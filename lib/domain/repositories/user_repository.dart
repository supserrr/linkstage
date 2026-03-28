import '../entities/profile_entity.dart';
import '../entities/user_entity.dart';

/// Abstract contract for user document operations.
abstract class UserRepository {
  /// Check if two users have worked together (completed booking or collaboration).
  Future<bool> hasWorkedWith(String userId1, String userId2);

  /// Check if [senderId] can send a message to [recipientId] based on recipient's whoCanMessage.
  /// Returns false if recipient has disabled messages or restricted to worked-with only.
  Future<bool> canSendMessageTo(String senderId, String recipientId);

  /// Update privacy settings for a user.
  Future<void> updatePrivacySettings(
    String userId, {
    ProfileVisibility? profileVisibility,
    WhoCanMessage? whoCanMessage,
    bool? showOnlineStatus,
  });

  /// Update last seen timestamp.
  Future<void> updateLastSeen(String userId);
  /// Get user by ID.
  Future<UserEntity?> getUser(String userId);

  /// Batch get users by IDs (e.g. to filter profiles by role).
  Future<Map<String, UserEntity>> getUsersByIds(List<String> ids);

  /// Create or update user document.
  Future<void> upsertUser(UserEntity user);

  /// Update user role.
  Future<void> updateRole(String userId, UserRole role);

  /// Check if username is available.
  /// [excludeUserId] when changing username: exclude own profile from uniqueness check.
  Future<bool> checkUsernameAvailable(String username, {String? excludeUserId});

  /// Update username and lastUsernameChangeAt (for username change flow).
  Future<void> updateUsername(
    String userId,
    String newUsername,
    DateTime lastUsernameChangeAt,
  );

  /// Atomically change username: check availability, create new profile,
  /// delete old profile, update users. Prevents TOCTOU race.
  Future<void> changeUsernameAtomic(
    String userId,
    String newUsername,
    String? oldUsername,
    ProfileEntity newProfileData,
    DateTime lastUsernameChangeAt,
  );

  /// Stream of user document for real-time updates.
  Stream<UserEntity?> watchUser(String userId);
}
