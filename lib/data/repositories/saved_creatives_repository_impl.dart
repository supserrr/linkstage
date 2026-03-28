import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/saved_creatives_repository.dart';

/// Firestore implementation using users/{userId}/saved_creatives subcollection.
class SavedCreativesRepositoryImpl implements SavedCreativesRepository {
  SavedCreativesRepositoryImpl(
    this._profileRepository, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final ProfileRepository _profileRepository;

  static const String _usersCollection = 'users';
  static const String _savedCreativesSub = 'saved_creatives';

  @override
  Future<void> toggleSaved(String ownerUserId, String creativeUserId) async {
    if (ownerUserId.isEmpty || creativeUserId.isEmpty) return;
    final ref = _firestore
        .collection(_usersCollection)
        .doc(ownerUserId)
        .collection(_savedCreativesSub)
        .doc(creativeUserId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'creativeUserId': creativeUserId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Stream<Set<String>> watchSavedCreativeIds(String ownerUserId) {
    if (ownerUserId.isEmpty) return Stream.value({});
    return _firestore
        .collection(_usersCollection)
        .doc(ownerUserId)
        .collection(_savedCreativesSub)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.id).toSet());
  }

  @override
  Future<List<ProfileEntity>> getSavedProfiles(String ownerUserId) async {
    if (ownerUserId.isEmpty) return [];
    final snapshot = await _firestore
        .collection(_usersCollection)
        .doc(ownerUserId)
        .collection(_savedCreativesSub)
        .get();
    if (snapshot.docs.isEmpty) return [];
    final ids = snapshot.docs.map((d) => d.id).toList();
    return _profileRepository.getProfilesByUserIds(ids);
  }
}
