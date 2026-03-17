import '../entities/profile_entity.dart';

/// Abstract contract for profile operations.
abstract class ProfileRepository {
  /// Stream of profiles (for discovery).
  /// [excludeUserId] if set, excludes that user's profile from results (e.g. current user).
  /// [onlyCreativeAccounts] if true, only includes profiles whose user role is creative (excludes event planners).
  Stream<List<ProfileEntity>> getProfiles({
    ProfileCategory? category,
    String? location,
    int limit = 20,
    String? excludeUserId,
    bool onlyCreativeAccounts = false,
  });

  /// Get profile by username (doc ID).
  Future<ProfileEntity?> getProfile(String username);

  /// Get profile by user ID.
  Future<ProfileEntity?> getProfileByUserId(String userId);

  /// Batch fetch profiles by user IDs. Returns profiles with photoUrl merged from users.
  Future<List<ProfileEntity>> getProfilesByUserIds(List<String> userIds);

  /// Stream of single profile for real-time updates.
  Stream<ProfileEntity?> watchProfile(String username);

  /// Create or update profile.
  Future<void> upsertProfile(ProfileEntity profile);

  /// Update only [rating] and [reviewCount] on the profile document [profileDocId].
  Future<void> updateProfileRatingStats(
    String profileDocId,
    double rating,
    int reviewCount,
  );

  /// Delete profile by username (used when migrating during username change).
  Future<void> deleteProfile(String username);
}
