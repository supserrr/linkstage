/// Repository for creative's past work visibility preferences.
/// IDs in [hiddenIds] are booking IDs or collaboration IDs to hide from public view.
abstract class CreativePastWorkPreferencesRepository {
  /// Get IDs the creative has chosen to hide from their public past work.
  Future<List<String>> getHiddenIds(String creativeUserId);

  /// Set the list of IDs to hide. Replaces existing.
  Future<void> setHiddenIds(String creativeUserId, List<String> hiddenIds);

  /// Toggle visibility: add to hidden if [show] is false, remove if true.
  Future<void> setItemVisibility(
    String creativeUserId,
    String itemId,
    bool show,
  );
}
