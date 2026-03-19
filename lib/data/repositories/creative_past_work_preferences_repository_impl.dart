import '../../domain/repositories/creative_past_work_preferences_repository.dart';
import '../datasources/creative_past_work_preferences_remote_datasource.dart';

class CreativePastWorkPreferencesRepositoryImpl
    implements CreativePastWorkPreferencesRepository {
  CreativePastWorkPreferencesRepositoryImpl(this._remote);

  final CreativePastWorkPreferencesRemoteDataSource _remote;

  @override
  Future<List<String>> getHiddenIds(String creativeUserId) =>
      _remote.getHiddenIds(creativeUserId);

  @override
  Future<void> setHiddenIds(String creativeUserId, List<String> hiddenIds) =>
      _remote.setHiddenIds(creativeUserId, hiddenIds);

  @override
  Future<void> setItemVisibility(
    String creativeUserId,
    String itemId,
    bool show,
  ) async {
    if (show) {
      await _remote.removeHiddenId(creativeUserId, itemId);
    } else {
      await _remote.addHiddenId(creativeUserId, itemId);
    }
  }
}
