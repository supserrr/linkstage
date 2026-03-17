import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

/// Firestore paths (same as existing rules).
class _Paths {
  static const String chatUsers = 'chat_users';
  static const String userChats = 'user_chats';
  static const String chatsSub = 'chats';
  static const String chats = 'chats';
  static const String users = 'users';
  static const String messages = 'messages';
}

/// Remote data source for conversations and messages.
class ConversationRemoteDataSource {
  ConversationRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _random = Random();

  /// Stream of conversations for [userId] from user_chats + chat_users for names/photos.
  Stream<List<ConversationEntity>> watchConversations(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    final ref = _firestore
        .collection(_Paths.userChats)
        .doc(userId)
        .collection(_Paths.chatsSub);
    return ref.snapshots().asyncMap((snapshot) async {
      final list = <ConversationEntity>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final chatId = doc.id;
        final otherUserId = (data['user_id'] ?? '').toString();
        final lastMessageText = data['last_message_text'] as String?;
        final lastMessageAt = (data['last_message_at'] as Timestamp?)?.toDate();
        final lastMessageSenderId = (data['last_message_sender_id'] ?? '').toString();
        final lastReadAt = (data['last_read_at'] as Timestamp?)?.toDate();
        final createdAt = (data['created_at'] as Timestamp?)?.toDate();
        // When sender is known: unread if last message is from the other user and not yet read.
        // When sender is unknown (legacy): treat as unread if never read, to show indicators.
        final hasUnread = lastMessageAt != null &&
            (lastReadAt == null || lastMessageAt.isAfter(lastReadAt)) &&
            (lastMessageSenderId.isEmpty
                ? true
                : lastMessageSenderId != userId);
        // Compute actual unread count from messages (source of truth).
        final unreadCount = hasUnread
            ? await _countUnreadMessages(chatId, userId, otherUserId, lastReadAt)
            : 0;
        String? displayName;
        String? photoUrl;
        if (otherUserId.isNotEmpty) {
          final chatUserDoc = await _firestore
              .collection(_Paths.chatUsers)
              .doc(otherUserId)
              .get();
          final chatUserData = chatUserDoc.data();
          final chatUserName = chatUserData?['displayName'] as String?;
          final chatUserPhoto = chatUserData?['photoUrl'] as String?;
          final usersDoc = await _firestore
              .collection(_Paths.users)
              .doc(otherUserId)
              .get();
          final usersData = usersDoc.data();
          if (usersData != null) {
            final dn = usersData['displayName'] as String?;
            final un = usersData['username'] as String?;
            final em = usersData['email'] as String?;
            displayName = (dn?.isNotEmpty == true)
                ? dn
                : (un?.isNotEmpty == true ? un : (em ?? chatUserName));
            photoUrl = (usersData['photoUrl'] as String?) ?? chatUserPhoto;
          } else {
            displayName = chatUserName;
            photoUrl = chatUserPhoto;
          }
        }
        list.add(ConversationEntity(
          id: chatId,
          otherUserId: otherUserId,
          otherUserDisplayName: displayName,
          otherUserPhotoUrl: photoUrl,
          lastMessageText: lastMessageText,
          lastMessageAt: lastMessageAt,
          createdAt: createdAt,
          hasUnread: hasUnread,
          unreadCount: unreadCount,
        ));
      }
      list.sort((a, b) {
        final aAt = a.lastMessageAt ?? a.createdAt ?? DateTime(0);
        final bAt = b.lastMessageAt ?? b.createdAt ?? DateTime(0);
        return bAt.compareTo(aAt);
      });
      return list;
    });
  }

  /// Gets existing 1:1 chat id or creates one; returns chatId.
  Future<String> getOrCreateOneToOneChat(
      String currentUserId, String otherUserId) async {
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      throw ArgumentError('Both user ids required');
    }
    final ref = _firestore
        .collection(_Paths.userChats)
        .doc(currentUserId)
        .collection(_Paths.chatsSub);
    final existing = await ref
        .where('user_id', isEqualTo: otherUserId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }
    final chatId = _generateChatId();
    final chatRef = _firestore.collection(_Paths.chats).doc(chatId);
    await chatRef.set(
      <String, dynamic>{'chat_room_type': 'oneToOne'},
      SetOptions(merge: true),
    );
    final participantsRef = chatRef.collection(_Paths.users);
    final now = FieldValue.serverTimestamp();
    final base = <String, dynamic>{
      'role': 'admin',
      'typing_status': 'typed',
      'user_active_status': 'offline',
      'membership_status': 'member',
      'membership_status_timestamp': now,
      'pin_status': 'unpinned',
      'pin_status_timestamp': now,
      'mute_status': 'unmuted',
    };
    await participantsRef.doc(currentUserId).set(
      <String, dynamic>{...base, 'user_id': currentUserId},
      SetOptions(merge: true),
    );
    await participantsRef.doc(otherUserId).set(
      <String, dynamic>{...base, 'user_id': otherUserId},
      SetOptions(merge: true),
    );
    await ref.doc(chatId).set(<String, dynamic>{
      'user_id': otherUserId,
      'created_at': now,
    }, SetOptions(merge: true));
    await _firestore
        .collection(_Paths.userChats)
        .doc(otherUserId)
        .collection(_Paths.chatsSub)
        .doc(chatId)
        .set(<String, dynamic>{
      'user_id': currentUserId,
      'created_at': now,
    }, SetOptions(merge: true));
    return chatId;
  }

  String _generateChatId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now();
    final prefix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}-';
    final suffix = List.generate(8, (_) => chars[_random.nextInt(chars.length)]).join();
    return '$prefix$suffix-${List.generate(4, (_) => chars[_random.nextInt(chars.length)]).join()}-${List.generate(12, (_) => chars[_random.nextInt(chars.length)]).join()}';
  }

  /// Stream of messages for [chatId], ordered by createdAt asc.
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    if (chatId.isEmpty) return Stream.value([]);
    return _firestore
        .collection(_Paths.chats)
        .doc(chatId)
        .collection(_Paths.messages)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => MessageModel.fromFirestore(d, chatId).toEntity())
            .toList());
  }

  /// Max length for chat message text (enforced in UI and Firestore rules).
  static const int maxMessageLength = 2000;

  /// Sends a text message and updates last message on both user_chats entries.
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    if (chatId.isEmpty || senderId.isEmpty) return;
    final trimmed = text.length > maxMessageLength
        ? text.substring(0, maxMessageLength)
        : text;
    final messagesRef = _firestore
        .collection(_Paths.chats)
        .doc(chatId)
        .collection(_Paths.messages);
    await messagesRef.add(MessageModel.toFirestore(senderId, trimmed));
    final now = FieldValue.serverTimestamp();
    final participants = await _firestore
        .collection(_Paths.chats)
        .doc(chatId)
        .collection(_Paths.users)
        .get();
    for (final doc in participants.docs) {
      final uid = doc.id;
      final isRecipient = uid != senderId;
      final update = <String, dynamic>{
        'last_message_text': trimmed,
        'last_message_at': now,
        'last_message_sender_id': senderId,
        if (isRecipient) 'unread_count': FieldValue.increment(1),
        if (!isRecipient) 'unread_count': 0,
      };
      await _firestore
          .collection(_Paths.userChats)
          .doc(uid)
          .collection(_Paths.chatsSub)
          .doc(chatId)
          .set(update, SetOptions(merge: true));
    }
  }

  /// Gets other participant id and display name for [chatId] from current user's perspective.
  Future<({String otherUserId, String displayName})?> getOtherParticipant(
    String chatId,
    String currentUserId,
  ) async {
    if (chatId.isEmpty || currentUserId.isEmpty) return null;
    final doc = await _firestore
        .collection(_Paths.userChats)
        .doc(currentUserId)
        .collection(_Paths.chatsSub)
        .doc(chatId)
        .get();
    final data = doc.data();
    final otherUserId = (data?['user_id'] ?? '').toString();
    if (otherUserId.isEmpty) return null;
    final userDoc = await _firestore
        .collection(_Paths.chatUsers)
        .doc(otherUserId)
        .get();
    final userData = userDoc.data();
    final displayName = (userData?['displayName'] ?? userData?['id'] ?? otherUserId).toString();
    return (otherUserId: otherUserId, displayName: displayName);
  }

  /// Counts messages from [otherUserId] that are unread by [userId] (created after [lastReadAt]).
  Future<int> _countUnreadMessages(
    String chatId,
    String userId,
    String otherUserId,
    DateTime? lastReadAt,
  ) async {
    if (chatId.isEmpty || otherUserId.isEmpty) return 0;
    try {
      Query<Map<String, dynamic>> q = _firestore
          .collection(_Paths.chats)
          .doc(chatId)
          .collection(_Paths.messages);
      if (lastReadAt != null) {
        q = q.where('createdAt', isGreaterThan: Timestamp.fromDate(lastReadAt));
      }
      final snap = await q.limit(500).get();
      return snap.docs.where((d) {
        final sentBy = (d.data()['sentBy'] ?? d.data()['senderId'] ?? '').toString();
        return sentBy == otherUserId;
      }).length;
    } catch (_) {
      return 0;
    }
  }

  /// Marks the chat as read for [userId]; updates last_read_at and resets unread_count.
  Future<void> markChatAsRead(String chatId, String userId) async {
    if (chatId.isEmpty || userId.isEmpty) return;
    await _firestore
        .collection(_Paths.userChats)
        .doc(userId)
        .collection(_Paths.chatsSub)
        .doc(chatId)
        .set({
          'last_read_at': FieldValue.serverTimestamp(),
          'unread_count': 0,
        }, SetOptions(merge: true));
  }
}
