import '../../domain/entities/planner_profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/planner_profile_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/planner_profile_remote_datasource.dart';

/// Implementation of [PlannerProfileRepository] using Firestore.
class PlannerProfileRepositoryImpl implements PlannerProfileRepository {
  PlannerProfileRepositoryImpl(this._remote, this._userRepository);

  final PlannerProfileRemoteDataSource _remote;
  final UserRepository _userRepository;

  @override
  Future<PlannerProfileEntity?> getPlannerProfile(String userId) async {
    final profile = await _remote.getPlannerProfile(userId);
    if (profile == null) return null;
    final user = await _userRepository.getUser(userId);
    return profile.copyWith(photoUrl: user?.photoUrl);
  }

  @override
  Future<List<PlannerProfileEntity>> getPlannerProfiles({
    int limit = 50,
    String? excludeUserId,
  }) async {
    var list = await _remote.getPlannerProfiles(
      limit: limit,
      excludeUserId: excludeUserId,
    );
    if (list.isEmpty) return list;
    final userIds = list.map((p) => p.userId).toSet().toList();
    final users = await _userRepository.getUsersByIds(userIds);
    list = list
        .map((p) => p.copyWith(photoUrl: users[p.userId]?.photoUrl))
        .toList();

    final viewerId = excludeUserId;
    if (viewerId == null || viewerId.isEmpty) return list;

    final filtered = <PlannerProfileEntity>[];
    for (final p in list) {
      final visibility = p.profileVisibility ?? ProfileVisibility.everyone;
      if (visibility == ProfileVisibility.onlyMe) continue;
      if (visibility == ProfileVisibility.connectionsOnly) {
        final worked = await _userRepository.hasWorkedWith(viewerId, p.userId);
        if (!worked) continue;
      }
      filtered.add(p);
    }
    return filtered;
  }

  @override
  Future<void> upsertPlannerProfile(PlannerProfileEntity profile) =>
      _remote.upsertPlannerProfile(profile);
}
