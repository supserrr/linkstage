import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/planner_profile_entity.dart';
import '../models/planner_profile_model.dart';

/// Remote data source for planner profiles in Firestore.
class PlannerProfileRemoteDataSource {
  PlannerProfileRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'planner_profiles';

  Future<PlannerProfileEntity?> getPlannerProfile(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return PlannerProfileModel.fromFirestore(doc).toEntity();
    }
    return null;
  }

  /// Fetch planner profiles for discovery (e.g. search/explore).
  /// [excludeUserId] if set, excludes that user's profile from results.
  Future<List<PlannerProfileEntity>> getPlannerProfiles({
    int limit = 50,
    String? excludeUserId,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .limit(limit)
        .get();
    var list = snapshot.docs
        .map((d) => PlannerProfileModel.fromFirestore(d).toEntity())
        .toList();
    if (excludeUserId != null) {
      list = list.where((e) => e.userId != excludeUserId).toList();
    }
    return list;
  }

  Future<void> upsertPlannerProfile(PlannerProfileEntity profile) async {
    final model = PlannerProfileModel(
      userId: profile.userId,
      bio: profile.bio,
      location: profile.location,
      eventTypes: profile.eventTypes,
      languages: profile.languages,
      portfolioUrls: profile.portfolioUrls,
      displayName: profile.displayName,
      role: profile.role,
      profileVisibility: profile.profileVisibility,
    );
    await _firestore
        .collection(_collection)
        .doc(profile.userId)
        .set(model.toFirestore(), SetOptions(merge: true));
  }
}
