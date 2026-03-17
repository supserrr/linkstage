import '../entities/planner_profile_entity.dart';

/// Abstract contract for planner profile operations.
abstract class PlannerProfileRepository {
  /// Get planner profile by user ID.
  Future<PlannerProfileEntity?> getPlannerProfile(String userId);

  /// Fetch planner profiles for discovery (e.g. search/explore).
  /// [excludeUserId] if set, excludes that user's profile from results (e.g. current user).
  Future<List<PlannerProfileEntity>> getPlannerProfiles({
    int limit = 50,
    String? excludeUserId,
  });

  /// Create or update planner profile.
  Future<void> upsertPlannerProfile(PlannerProfileEntity profile);
}
