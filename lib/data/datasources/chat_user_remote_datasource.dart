import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstraction for writing chat user docs. Allows tests to mock without
/// touching Firestore sealed types (Query, CollectionReference).
abstract class ChatUserFirestoreWriter {
  Future<void> setChatUser(String id, Map<String, dynamic> data);
}

/// Remote data source for chat user documents in Firestore.
/// Used so the conversation list can resolve other user display name and photo.
class ChatUserRemoteDataSource {
  ChatUserRemoteDataSource({
    ChatUserFirestoreWriter? writer,
    FirebaseFirestore? firestore,
  }) : _writer =
           writer ??
           FirestoreChatUserFirestoreWriter(
             firestore ?? FirebaseFirestore.instance,
           );

  final ChatUserFirestoreWriter _writer;

  /// Ensures a user document exists in [chat_users] with merge.
  Future<void> ensureChatUser({
    required String id,
    String? displayName,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{
      'id': id,
      ...?(displayName != null ? {'displayName': displayName} : null),
      ...?(photoUrl != null ? {'photoUrl': photoUrl} : null),
    };
    await _writer.setChatUser(id, data);
  }

  /// Ensures a user exists in chat_users by id only (e.g. when profile not in Firestore yet).
  Future<void> ensureChatUserById(String userId) async {
    if (userId.isEmpty) return;
    await _writer.setChatUser(userId, {'id': userId});
  }
}

/// Firestore implementation of [ChatUserFirestoreWriter].
class FirestoreChatUserFirestoreWriter implements ChatUserFirestoreWriter {
  FirestoreChatUserFirestoreWriter(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _chatUsersCollection = 'chat_users';

  @override
  Future<void> setChatUser(String id, Map<String, dynamic> data) async {
    await _firestore
        .collection(_chatUsersCollection)
        .doc(id)
        .set(data, SetOptions(merge: true));
  }
}
