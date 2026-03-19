import 'dart:async';

import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Implementation of [ProfileRepository] using Firestore.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._userRepository);

  final ProfileRemoteDataSource _remote;
  final UserRepository _userRepository;

  @override
  Stream<List<ProfileEntity>> getProfiles({
    ProfileCategory? category,
    String? location,
    int limit = 20,
    String? excludeUserId,
    bool onlyCreativeAccounts = false,
  }) {
    final stream = _remote.getProfiles(
      category: category,
      location: location,
      limit: limit,
      excludeUserId: excludeUserId,
    );
    return stream.asyncMap((list) async {
      if (list.isEmpty) return list;

      // Always merge photoUrl from user documents.
      final userIds = list.map((p) => p.userId).toSet().toList();
      final users = await _userRepository.getUsersByIds(userIds);
      list = list
          .map((p) => p.copyWith(photoUrl: users[p.userId]?.photoUrl))
          .toList();

      if (onlyCreativeAccounts) {
        list = list
            .where(
              (p) => users[p.userId]?.role == UserRole.creativeProfessional,
            )
            .toList();
      }

      final viewerId = excludeUserId;
      if (viewerId == null || viewerId.isEmpty) return list;

      final filtered = <ProfileEntity>[];
      for (final p in list) {
        final visibility = p.profileVisibility ?? ProfileVisibility.everyone;
        if (visibility == ProfileVisibility.onlyMe) continue;
        if (visibility == ProfileVisibility.connectionsOnly) {
          final worked = await _userRepository.hasWorkedWith(
            viewerId,
            p.userId,
          );
          if (!worked) continue;
        }
        filtered.add(p);
      }
      return filtered;
    });
  }

  @override
  Future<ProfileEntity?> getProfile(String username) async {
    final profile = await _remote.getProfile(username);
    if (profile == null) return null;
    final user = await _userRepository.getUser(profile.userId);
    return profile.copyWith(photoUrl: user?.photoUrl);
  }

  @override
  Future<ProfileEntity?> getProfileByUserId(String userId) async {
    final profile = await _remote.getProfileByUserId(userId);
    if (profile == null) return null;
    final user = await _userRepository.getUser(userId);
    return profile.copyWith(photoUrl: user?.photoUrl);
  }

  @override
  Future<List<ProfileEntity>> getProfilesByUserIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final profiles = await _remote.getProfilesByUserIds(userIds);
    if (profiles.isEmpty) return [];
    final users = await _userRepository.getUsersByIds(userIds);
    return profiles
        .map((p) => p.copyWith(photoUrl: users[p.userId]?.photoUrl))
        .toList();
  }

  @override
  Stream<ProfileEntity?> watchProfile(String username) {
    return _remote.watchProfile(username).asyncMap((profile) async {
      if (profile == null) return null;
      final user = await _userRepository.getUser(profile.userId);
      return profile.copyWith(photoUrl: user?.photoUrl);
    });
  }

  @override
  Future<void> upsertProfile(ProfileEntity profile) =>
      _remote.upsertProfile(profile);

  @override
  Future<void> updateProfileRatingStats(
    String profileDocId,
    double rating,
    int reviewCount,
  ) => _remote.updateProfileRatingStats(profileDocId, rating, reviewCount);

  @override
  Future<void> deleteProfile(String username) =>
      _remote.deleteProfile(username);
}
