import '../entities/planner_profile_entity.dart';

/// Repository for creatives following event planners.
/// Follow state persists until the creative explicitly unfollows.
abstract class FollowedPlannersRepository {
  /// Toggle follow state. If following, unfollows; if not, follows.
  Future<void> toggleFollow(String creativeUserId, String plannerId);

  /// Add follow (used for migration from SharedPreferences). No-op if already following.
  Future<void> addFollow(String creativeUserId, String plannerId);

  /// Stream of followed planner user IDs for the given creative.
  Stream<Set<String>> watchFollowedPlannerIds(String creativeUserId);

  /// Fetch planner profiles for all followed planners.
  Future<List<PlannerProfileEntity>> getFollowedPlannerProfiles(
    String creativeUserId,
  );
}
