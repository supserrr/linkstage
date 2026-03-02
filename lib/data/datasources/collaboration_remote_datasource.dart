import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/collaboration_entity.dart';
import '../models/collaboration_model.dart';

/// Remote data source for collaborations in Firestore.
class CollaborationRemoteDataSource {
  CollaborationRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'collaborations';

  Future<CollaborationEntity> createCollaboration({
    required String requesterId,
    required String targetUserId,
    required String description,
    String? title,
    String? eventId,
    double? budget,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    String? eventType,
  }) async {
    final exists = await _hasActiveBetween(requesterId, targetUserId);
    if (exists) {
      throw Exception(
        'An ongoing collaboration already exists between you and this creative',
      );
    }
    final ref = _firestore.collection(_collection).doc();
    final model = CollaborationModel(
      id: ref.id,
      requesterId: requesterId,
      targetUserId: targetUserId,
      description: description,
      status: CollaborationStatus.pending,
      title: title,
      eventId: eventId,
      createdAt: DateTime.now(),
      budget: budget,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location,
      eventType: eventType,
    );
    await ref.set(model.toFirestore());
    return model.toEntity();
  }

  Future<List<CollaborationEntity>> getCollaborationsByTargetUserId(
    String targetUserId, {
    CollaborationStatus? status,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('targetUserId', isEqualTo: targetUserId);

    if (status != null) {
      final key = _statusToKey(status);
      query = query.where('status', isEqualTo: key);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((d) => CollaborationModel.fromFirestore(d).toEntity())
        .toList();
  }

  Future<List<CollaborationEntity>> getCollaborationsByEventId(
    String eventId, {
    CollaborationStatus? status,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId);

    if (status != null) {
      final key = _statusToKey(status);
      query = query.where('status', isEqualTo: key);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((d) => CollaborationModel.fromFirestore(d).toEntity())
        .toList();
  }

  Future<List<CollaborationEntity>> getCollaborationsByRequesterId(
    String requesterId, {
    CollaborationStatus? status,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('requesterId', isEqualTo: requesterId);

    if (status != null) {
      final key = _statusToKey(status);
      query = query.where('status', isEqualTo: key);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((d) => CollaborationModel.fromFirestore(d).toEntity())
        .toList();
  }

  Stream<List<CollaborationEntity>> watchCollaborationsByTargetUserId(
    String targetUserId, {
    CollaborationStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('targetUserId', isEqualTo: targetUserId);

    if (status != null) {
      final key = _statusToKey(status);
      query = query.where('status', isEqualTo: key);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => CollaborationModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  Stream<List<CollaborationEntity>> watchCollaborationsByRequesterId(
    String requesterId, {
    CollaborationStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('requesterId', isEqualTo: requesterId);

    if (status != null) {
      final key = _statusToKey(status);
      query = query.where('status', isEqualTo: key);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => CollaborationModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  static String _statusToKey(CollaborationStatus status) {
    switch (status) {
      case CollaborationStatus.pending:
        return 'pending';
      case CollaborationStatus.accepted:
        return 'accepted';
      case CollaborationStatus.declined:
        return 'declined';
      case CollaborationStatus.completed:
        return 'completed';
    }
  }

  /// Update collaboration status. When status is completed, [confirmingIsPlanner]
  /// determines which confirmation timestamp to set.
  Future<void> updateStatus(
    String collaborationId,
    CollaborationStatus status, {
    bool? confirmingIsPlanner,
  }) async {
    final updates = <String, dynamic>{'status': _statusToKey(status)};
    if (status == CollaborationStatus.completed && confirmingIsPlanner != null) {
      if (confirmingIsPlanner) {
        updates['plannerConfirmedAt'] = FieldValue.serverTimestamp();
      } else {
        updates['creativeConfirmedAt'] = FieldValue.serverTimestamp();
      }
    }
    await _firestore.collection(_collection).doc(collaborationId).update(updates);
  }

  /// Creative confirms they completed the work (sets creativeConfirmedAt).
  Future<void> confirmCompletionByCreative(String collaborationId) async {
    await _firestore.collection(_collection).doc(collaborationId).update({
      'creativeConfirmedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns true if there is an active collaboration (pending or accepted).
  /// When declined or completed, a new proposal can be sent.
  Future<bool> hasExistingCollaboration(String requesterId, String targetUserId) async {
    return _hasActiveBetween(requesterId, targetUserId);
  }

  /// Returns true if there is any active collaboration between the two users (either direction).
  Future<bool> hasActiveCollaborationBetween(String userId1, String userId2) async {
    return _hasActiveBetween(userId1, userId2);
  }

  Future<bool> _hasActiveBetween(String userId1, String userId2) async {
    final snapshot1 = await _firestore
        .collection(_collection)
        .where('requesterId', isEqualTo: userId1)
        .where('targetUserId', isEqualTo: userId2)
        .get();
    final snapshot2 = await _firestore
        .collection(_collection)
        .where('requesterId', isEqualTo: userId2)
        .where('targetUserId', isEqualTo: userId1)
        .get();
    return snapshot1.docs.any(_isActiveStatus) || snapshot2.docs.any(_isActiveStatus);
  }

  bool _isActiveStatus(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final status = doc.data()['status'] as String?;
    return status == 'pending' || status == 'accepted';
  }
}
