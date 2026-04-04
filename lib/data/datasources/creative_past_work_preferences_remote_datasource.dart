import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data source for creative past work visibility preferences.
class CreativePastWorkPreferencesRemoteDataSource {
  CreativePastWorkPreferencesRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'creative_past_work_preferences';

  Future<List<String>> getHiddenIds(String creativeUserId) async {
    final doc = await _firestore
        .collection(_collection)
        .doc(creativeUserId)
        .get();
    final data = doc.data();
    if (data == null) return [];
    final list = data['hiddenIds'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => e.toString()).toList();
  }

  Future<void> setHiddenIds(
    String creativeUserId,
    List<String> hiddenIds,
  ) async {
    await _firestore.collection(_collection).doc(creativeUserId).set({
      'userId': creativeUserId,
      'hiddenIds': hiddenIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addHiddenId(String creativeUserId, String itemId) async {
    final current = await getHiddenIds(creativeUserId);
    if (current.contains(itemId)) return;
    await setHiddenIds(creativeUserId, [...current, itemId]);
  }

  Future<void> removeHiddenId(String creativeUserId, String itemId) async {
    final current = await getHiddenIds(creativeUserId);
    final updated = current.where((id) => id != itemId).toList();
    await setHiddenIds(creativeUserId, updated);
  }
}
