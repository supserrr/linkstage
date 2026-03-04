import '../entities/profile_entity.dart';

/// Repository for saved/favorited creatives (planner saves creatives to find later).
abstract class SavedCreativesRepository {
  /// Toggle save state for a creative. If saved, removes; if not, adds.
  Future<void> toggleSaved(String ownerUserId, String creativeUserId);

  /// Stream of saved creative user IDs for the given owner.
  Stream<Set<String>> watchSavedCreativeIds(String ownerUserId);

  /// Fetch profile entities for all saved creatives.
  Future<List<ProfileEntity>> getSavedProfiles(String ownerUserId);
}
