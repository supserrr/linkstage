import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entity_extensions.dart';
import '../../domain/entities/profile_entity.dart';
import '../models/profile_model.dart';

/// Remote data source for profiles in Firestore.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _profilesCollection = 'profiles';

  Stream<List<ProfileEntity>> getProfiles({
    ProfileCategory? category,
    String? location,
    int limit = 20,
    String? excludeUserId,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      _profilesCollection,
    );

    if (category != null) {
      query = query.where('category', isEqualTo: category.categoryKey);
    }
    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }
    query = query.limit(limit);

    return query.snapshots().map(
      (snapshot) {
        var list = snapshot.docs
            .map((d) => ProfileModel.fromFirestore(d).toEntity())
            .toList();
        if (excludeUserId != null) {
          list = list.where((p) => p.userId != excludeUserId).toList();
        }
        return list;
      },
    );
  }

  Future<ProfileEntity?> getProfile(String username) async {
    final doc = await _firestore
        .collection(_profilesCollection)
        .doc(_normalizeUsername(username))
        .get();
    if (doc.exists && doc.data() != null) {
      return ProfileModel.fromFirestore(doc).toEntity();
    }
    return null;
  }

  Future<ProfileEntity?> getProfileByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(_profilesCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return ProfileModel.fromFirestore(snapshot.docs.first).toEntity();
    }
    return null;
  }

  /// Batch fetch profiles by user IDs. Firestore whereIn limited to 30 per query.
  Future<List<ProfileEntity>> getProfilesByUserIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return [];
    final uniqueIds = userIds.toSet().where((id) => id.isNotEmpty).toList();
    if (uniqueIds.isEmpty) return [];
    const chunkSize = 30;
    final results = <ProfileEntity>[];
    for (var i = 0; i < uniqueIds.length; i += chunkSize) {
      final chunk = uniqueIds.skip(i).take(chunkSize).toList();
      final snapshot = await _firestore
          .collection(_profilesCollection)
          .where('userId', whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        results.add(ProfileModel.fromFirestore(doc).toEntity());
      }
    }
    return results;
  }

  static String _normalizeUsername(String s) => s.toLowerCase();

  Future<void> upsertProfile(ProfileEntity profile) async {
    final username = profile.id.isNotEmpty ? profile.id : profile.username ?? '';
    if (username.isEmpty) {
      throw ArgumentError('Profile must have username as id');
    }
    final docId = _normalizeUsername(username);
    final model = ProfileModel(
      id: docId,
      userId: profile.userId,
      username: username,
      bio: profile.bio,
      category: profile.category,
      priceRange: profile.priceRange,
      location: profile.location,
      portfolioUrls: profile.portfolioUrls,
      portfolioVideoUrls: profile.portfolioVideoUrls,
      availability: profile.availability,
      services: profile.services,
      languages: profile.languages,
      professions: profile.professions,
      rating: profile.rating,
      reviewCount: profile.reviewCount,
      displayName: profile.displayName,
      profileVisibility: profile.profileVisibility,
    );
    await _firestore
        .collection(_profilesCollection)
        .doc(docId)
        .set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateProfileRatingStats(
    String profileDocId,
    double rating,
    int reviewCount,
  ) async {
    final docId = _normalizeUsername(profileDocId);
    await _firestore.collection(_profilesCollection).doc(docId).update({
      'rating': rating,
      'reviewCount': reviewCount,
    });
  }

  Future<void> deleteProfile(String username) async {
    await _firestore
        .collection(_profilesCollection)
        .doc(_normalizeUsername(username))
        .delete();
  }

  Stream<ProfileEntity?> watchProfile(String username) {
    return _firestore
        .collection(_profilesCollection)
        .doc(_normalizeUsername(username))
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return ProfileModel.fromFirestore(doc).toEntity();
      }
      return null;
    });
  }
}
