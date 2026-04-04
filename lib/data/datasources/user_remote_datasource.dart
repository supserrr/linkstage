import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entity_extensions.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';

/// Remote data source for user documents in Firestore.
class UserRemoteDataSource {
  UserRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';
  static const String _profilesCollection = 'profiles';

  Future<UserEntity?> getUser(String userId) async {
    final doc = await _firestore.collection(_usersCollection).doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(doc).toEntity();
    }
    return null;
  }

  /// Batch get users by IDs (e.g. to filter profiles by role).
  /// Uses parallel get() per chunk (Flutter SDK has no getAll); chunkSize 30 for consistency.
  Future<Map<String, UserEntity>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final uniqueIds = ids.toSet().toList();
    final result = <String, UserEntity>{};
    const chunkSize = 30;
    for (var i = 0; i < uniqueIds.length; i += chunkSize) {
      final chunkIds = uniqueIds.skip(i).take(chunkSize).toList();
      final refs = chunkIds.map(
        (id) => _firestore.collection(_usersCollection).doc(id),
      );
      final docs = await Future.wait(refs.map((ref) => ref.get()));
      for (var j = 0; j < docs.length; j++) {
        final doc = docs[j];
        if (doc.exists && doc.data() != null) {
          final user = UserModel.fromFirestore(doc).toEntity();
          result[chunkIds[j]] = user;
        }
      }
    }
    return result;
  }

  Future<void> upsertUser(UserEntity user) async {
    final model = UserModel(
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      role: user.role,
      lastUsernameChangeAt: user.lastUsernameChangeAt != null
          ? Timestamp.fromDate(user.lastUsernameChangeAt!)
          : null,
    );
    await _firestore
        .collection(_usersCollection)
        .doc(user.id)
        .set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<bool> checkUsernameAvailable(
    String username, {
    String? excludeUserId,
  }) async {
    final doc = await _firestore
        .collection(_profilesCollection)
        .doc(username.toLowerCase())
        .get();
    if (!doc.exists) return true;
    if (excludeUserId != null) {
      final data = doc.data();
      final docUserId = data?['userId'] as String?;
      return docUserId == excludeUserId;
    }
    return false;
  }

  Future<void> updateUsername(
    String userId,
    String newUsername,
    DateTime lastUsernameChangeAt,
  ) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'username': newUsername.toLowerCase(),
      'lastUsernameChangeAt': Timestamp.fromDate(lastUsernameChangeAt),
    });
  }

  /// Atomically change username: check availability, create new profile,
  /// delete old profile, update users. Prevents TOCTOU race.
  Future<void> changeUsernameAtomic(
    String userId,
    String newUsername,
    String? oldUsername,
    ProfileEntity newProfileData,
    DateTime lastUsernameChangeAt,
  ) async {
    final normalized = newUsername.toLowerCase();
    final oldNormalized = oldUsername?.toLowerCase();
    final model = ProfileModel(
      id: normalized,
      userId: newProfileData.userId,
      username: normalized,
      bio: newProfileData.bio,
      category: newProfileData.category,
      priceRange: newProfileData.priceRange,
      location: newProfileData.location,
      portfolioUrls: newProfileData.portfolioUrls,
      portfolioVideoUrls: newProfileData.portfolioVideoUrls,
      availability: newProfileData.availability,
      services: newProfileData.services,
      languages: newProfileData.languages,
      professions: newProfileData.professions,
      rating: newProfileData.rating,
      reviewCount: newProfileData.reviewCount,
      displayName: newProfileData.displayName,
      profileVisibility: newProfileData.profileVisibility,
    );
    await _firestore.runTransaction((transaction) async {
      final newProfileRef = _firestore
          .collection(_profilesCollection)
          .doc(normalized);
      final newDoc = await transaction.get(newProfileRef);
      if (newDoc.exists) {
        final data = newDoc.data();
        final docUserId = data?['userId'] as String?;
        if (docUserId != userId) {
          throw StateError('Username $normalized is already taken');
        }
      }
      transaction.set(
        newProfileRef,
        model.toFirestore(),
        SetOptions(merge: true),
      );
      if (oldNormalized != null && oldNormalized.isNotEmpty) {
        final oldProfileRef = _firestore
            .collection(_profilesCollection)
            .doc(oldNormalized);
        transaction.delete(oldProfileRef);
      }
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      transaction.update(userRef, {
        'username': normalized,
        'lastUsernameChangeAt': Timestamp.fromDate(lastUsernameChangeAt),
      });
    });
  }

  Future<void> updateRole(String userId, UserRole role) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'role': role.roleKey,
    });
  }

  Future<void> updatePrivacySettings(
    String userId, {
    ProfileVisibility? profileVisibility,
    WhoCanMessage? whoCanMessage,
    bool? showOnlineStatus,
  }) async {
    final updates = <String, dynamic>{};
    if (profileVisibility != null) {
      updates['profileVisibility'] = UserEntity.profileVisibilityToKey(
        profileVisibility,
      );
    }
    if (whoCanMessage != null) {
      updates['whoCanMessage'] = UserEntity.whoCanMessageToKey(whoCanMessage);
    }
    if (showOnlineStatus != null) {
      updates['showOnlineStatus'] = showOnlineStatus;
    }
    if (updates.isEmpty) return;
    await _firestore.collection(_usersCollection).doc(userId).update(updates);
  }

  Future<void> updateLastSeen(String userId) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserEntity?> watchUser(String userId) {
    return _firestore.collection(_usersCollection).doc(userId).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc).toEntity();
      }
      return null;
    });
  }

  static const String _notificationReadsSubcollection = 'notification_reads';

  /// Mark a single notification as read.
  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationReadsSubcollection)
        .doc(notificationId)
        .set({'readAt': FieldValue.serverTimestamp()});
  }

  /// Mark all given notifications as read.
  Future<void> markAllNotificationsAsRead(
    String userId,
    List<String> notificationIds,
  ) async {
    if (notificationIds.isEmpty) return;
    final batch = _firestore.batch();
    final col = _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationReadsSubcollection);
    for (final id in notificationIds) {
      batch.set(col.doc(id), {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  /// Stream of read notification IDs for the user.
  Stream<Set<String>> watchNotificationReadIds(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationReadsSubcollection)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  static const String _plannerNewEventNotificationsSub =
      'planner_new_event_notifications';

  /// Stream of planner-new-event notification docs for creatives who follow planners.
  Stream<List<Map<String, dynamic>>> watchPlannerNewEventNotifications(
    String userId,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_plannerNewEventNotificationsSub)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  static const String _deviceTokensSubcollection = 'device_tokens';

  /// Store FCM token for the user. Uses hash of token as doc ID for multiple devices.
  Future<void> setFcmToken(String userId, String token) async {
    final docId = token.hashCode.toUnsigned(64).toRadixString(36);
    await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_deviceTokensSubcollection)
        .doc(docId)
        .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Remove FCM token for the user.
  Future<void> removeFcmToken(String userId, String token) async {
    final docId = token.hashCode.toUnsigned(64).toRadixString(36);
    await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_deviceTokensSubcollection)
        .doc(docId)
        .delete();
  }
}
