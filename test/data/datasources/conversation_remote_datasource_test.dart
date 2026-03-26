import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/conversation_remote_datasource.dart';

void main() {
  group('ConversationRemoteDataSource', () {
    test('getOrCreateOneToOneChat creates chat + user_chats entries', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ConversationRemoteDataSource(firestore: fake);

      final chatId = await ds.getOrCreateOneToOneChat('u1', 'u2');

      final u1Chat = await fake
          .collection('user_chats')
          .doc('u1')
          .collection('chats')
          .doc(chatId)
          .get();
      final u2Chat = await fake
          .collection('user_chats')
          .doc('u2')
          .collection('chats')
          .doc(chatId)
          .get();

      expect(u1Chat.exists, isTrue);
      expect(u2Chat.exists, isTrue);
      expect(u1Chat.data()?['user_id'], 'u2');
      expect(u2Chat.data()?['user_id'], 'u1');
    });

    test('sendMessage trims text and updates unread_count', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ConversationRemoteDataSource(firestore: fake);

      const chatId = 'chat-1';

      await fake.collection('chats').doc(chatId).set({
        'chat_room_type': 'oneToOne',
      });
      await fake
          .collection('chats')
          .doc(chatId)
          .collection('users')
          .doc('u1')
          .set({'user_id': 'u1'});
      await fake
          .collection('chats')
          .doc(chatId)
          .collection('users')
          .doc('u2')
          .set({'user_id': 'u2'});

      final longText = List.filled(
        ConversationRemoteDataSource.maxMessageLength + 10,
        'a',
      ).join();
      await ds.sendMessage(chatId, 'u1', longText);

      final u1Row = await fake
          .collection('user_chats')
          .doc('u1')
          .collection('chats')
          .doc(chatId)
          .get();
      final u2Row = await fake
          .collection('user_chats')
          .doc('u2')
          .collection('chats')
          .doc(chatId)
          .get();

      expect(
        u1Row.data()?['last_message_text'],
        hasLength(ConversationRemoteDataSource.maxMessageLength),
      );
      expect(
        u2Row.data()?['last_message_text'],
        hasLength(ConversationRemoteDataSource.maxMessageLength),
      );
      expect(u1Row.data()?['unread_count'], 0);
      expect(u2Row.data()?['unread_count'], 1);
    });

    test(
      'watchConversations computes hasUnread and unreadCount from messages',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = ConversationRemoteDataSource(firestore: fake);

        const userId = 'u1';
        const otherUserId = 'u2';
        const chatId = 'chat-2';

        await fake
            .collection('user_chats')
            .doc(userId)
            .collection('chats')
            .doc(chatId)
            .set({
              'user_id': otherUserId,
              'last_message_text': 'hi',
              'last_message_sender_id': otherUserId,
              'last_message_at': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
              'created_at': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
            });

        await fake.collection('chat_users').doc(otherUserId).set({
          'displayName': 'Other',
          'photoUrl': 'x',
        });
        await fake.collection('users').doc(otherUserId).set({
          'email': 'other@test.com',
          'displayName': 'Other User',
          'photoUrl': 'y',
        });

        final messagesRef = fake
            .collection('chats')
            .doc(chatId)
            .collection('messages');
        await messagesRef.add({
          'sentBy': otherUserId,
          'text': 'm1',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 10)),
        });
        await messagesRef.add({
          'sentBy': otherUserId,
          'text': 'm2',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 11)),
        });
        await messagesRef.add({
          'sentBy': userId,
          'text': 'mine',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 12)),
        });

        final list = await ds.watchConversations(userId).first;

        expect(list, hasLength(1));
        expect(list.single.id, chatId);
        expect(list.single.otherUserId, otherUserId);
        expect(list.single.hasUnread, isTrue);
        expect(list.single.unreadCount, 2);
        expect(list.single.otherUserDisplayName, isNotEmpty);
      },
    );

    test('watchConversations empty userId yields empty stream', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ConversationRemoteDataSource(firestore: fake);
      final list = await ds.watchConversations('').first;
      expect(list, isEmpty);
    });

    test('getOrCreateOneToOneChat returns existing chat id', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ConversationRemoteDataSource(firestore: fake);

      await fake
          .collection('user_chats')
          .doc('u1')
          .collection('chats')
          .doc('existing-id')
          .set({'user_id': 'u2'});

      final id = await ds.getOrCreateOneToOneChat('u1', 'u2');
      expect(id, 'existing-id');
    });

    test('getOrCreateOneToOneChat throws when id empty', () async {
      final ds = ConversationRemoteDataSource(
        firestore: FakeFirebaseFirestore(),
      );
      expect(() => ds.getOrCreateOneToOneChat('', 'u2'), throwsArgumentError);
    });

    test('watchMessages maps documents', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ConversationRemoteDataSource(firestore: fake);

      const chatId = 'c-msg';
      await fake.collection('chats').doc(chatId).set({
        'chat_room_type': 'oneToOne',
      });
      await fake.collection('chats').doc(chatId).collection('messages').add({
        'sentBy': 'u1',
        'text': 'hello',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      final msgs = await ds.watchMessages(chatId).first;
      expect(msgs, hasLength(1));
      expect(msgs.single.text, 'hello');
    });

    test('watchMessages empty chatId yields empty', () async {
      final ds = ConversationRemoteDataSource(
        firestore: FakeFirebaseFirestore(),
      );
      final msgs = await ds.watchMessages('').first;
      expect(msgs, isEmpty);
    });

    test('getOtherParticipant returns names', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ConversationRemoteDataSource(firestore: fake);

      await fake
          .collection('user_chats')
          .doc('me')
          .collection('chats')
          .doc('ch1')
          .set({'user_id': 'other'});
      await fake.collection('chat_users').doc('other').set({
        'displayName': 'Other Person',
      });

      final r = await ds.getOtherParticipant('ch1', 'me');
      expect(r?.otherUserId, 'other');
      expect(r?.displayName, 'Other Person');
    });

    test('getOtherParticipant null when missing row', () async {
      final ds = ConversationRemoteDataSource(
        firestore: FakeFirebaseFirestore(),
      );
      expect(await ds.getOtherParticipant('', 'u'), isNull);
    });

    test('markChatAsRead writes', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ConversationRemoteDataSource(firestore: fake);

      await fake
          .collection('user_chats')
          .doc('u1')
          .collection('chats')
          .doc('cid')
          .set({'user_id': 'u2'});

      await ds.markChatAsRead('cid', 'u1');
      final doc = await fake
          .collection('user_chats')
          .doc('u1')
          .collection('chats')
          .doc('cid')
          .get();
      expect(doc.data()?.containsKey('last_read_at'), isTrue);
      expect(doc.data()?['unread_count'], 0);
    });
  });
}
