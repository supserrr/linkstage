import '../entities/user_entity.dart';

/// Repository for syncing app users into the chat_users Firestore collection
/// so the conversation list can resolve other user display name and photo.
abstract class ChatUserRepository {
  /// Ensures the user exists in chat_users with id, displayName, photoUrl.
  Future<void> ensureChatUser(UserEntity user);

  /// Ensures a user exists in chat_users by id only (e.g. when profile not in Firestore yet).
  Future<void> ensureChatUserById(String userId);
}
