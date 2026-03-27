import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/planner_profile_entity.dart';
import '../../domain/repositories/followed_planners_repository.dart';
import '../../domain/repositories/planner_profile_repository.dart';

/// Firestore implementation using users/{userId}/followed_planners subcollection.
class FollowedPlannersRepositoryImpl implements FollowedPlannersRepository {
  FollowedPlannersRepositoryImpl(
    this._plannerProfileRepository, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final PlannerProfileRepository _plannerProfileRepository;

  static const String _usersCollection = 'users';
  static const String _followedPlannersSub = 'followed_planners';

  @override
  Future<void> toggleFollow(String creativeUserId, String plannerId) async {
    if (creativeUserId.isEmpty || plannerId.isEmpty) return;
    final ref = _firestore
        .collection(_usersCollection)
        .doc(creativeUserId)
        .collection(_followedPlannersSub)
        .doc(plannerId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'plannerId': plannerId,
        'followedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> addFollow(String creativeUserId, String plannerId) async {
    if (creativeUserId.isEmpty || plannerId.isEmpty) return;
    final ref = _firestore
        .collection(_usersCollection)
        .doc(creativeUserId)
        .collection(_followedPlannersSub)
        .doc(plannerId);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'plannerId': plannerId,
        'followedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Stream<Set<String>> watchFollowedPlannerIds(String creativeUserId) {
    if (creativeUserId.isEmpty) return Stream.value({});
    return _firestore
        .collection(_usersCollection)
        .doc(creativeUserId)
        .collection(_followedPlannersSub)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.id).toSet());
  }

  @override
  Future<List<PlannerProfileEntity>> getFollowedPlannerProfiles(
    String creativeUserId,
  ) async {
    if (creativeUserId.isEmpty) return [];
    final snapshot = await _firestore
        .collection(_usersCollection)
        .doc(creativeUserId)
        .collection(_followedPlannersSub)
        .get();
    if (snapshot.docs.isEmpty) return [];
    final ids = snapshot.docs.map((d) => d.id).toList();
    final profiles = <PlannerProfileEntity>[];
    for (final id in ids) {
      final profile = await _plannerProfileRepository.getPlannerProfile(id);
      if (profile != null) {
        profiles.add(profile);
      }
    }
    return profiles;
  }
}
