import '../../domain/entities/collaboration_entity.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../datasources/collaboration_remote_datasource.dart';

/// Implementation of [CollaborationRepository] using Firestore.
class CollaborationRepositoryImpl implements CollaborationRepository {
  CollaborationRepositoryImpl(this._remote);

  final CollaborationRemoteDataSource _remote;

  @override
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
  }) => _remote.createCollaboration(
    requesterId: requesterId,
    targetUserId: targetUserId,
    description: description,
    title: title,
    eventId: eventId,
    budget: budget,
    date: date,
    startTime: startTime,
    endTime: endTime,
    location: location,
    eventType: eventType,
  );

  @override
  Future<List<CollaborationEntity>> getCollaborationsByTargetUserId(
    String targetUserId, {
    CollaborationStatus? status,
  }) => _remote.getCollaborationsByTargetUserId(targetUserId, status: status);

  @override
  Future<List<CollaborationEntity>> getCollaborationsByEventId(
    String eventId, {
    CollaborationStatus? status,
  }) => _remote.getCollaborationsByEventId(eventId, status: status);

  @override
  Future<List<CollaborationEntity>> getCollaborationsByRequesterId(
    String requesterId, {
    CollaborationStatus? status,
  }) => _remote.getCollaborationsByRequesterId(requesterId, status: status);

  @override
  Future<void> updateStatus(
    String collaborationId,
    CollaborationStatus status, {
    bool? confirmingIsPlanner,
  }) => _remote.updateStatus(
    collaborationId,
    status,
    confirmingIsPlanner: confirmingIsPlanner,
  );

  @override
  Future<void> confirmCompletionByCreative(String collaborationId) =>
      _remote.confirmCompletionByCreative(collaborationId);

  @override
  Future<void> completeAcceptedCollaborationsForEvent(String eventId) async {
    final accepted = await _remote.getCollaborationsByEventId(
      eventId,
      status: CollaborationStatus.accepted,
    );
    for (final c in accepted) {
      await _remote.updateStatus(
        c.id,
        CollaborationStatus.completed,
        confirmingIsPlanner: true,
      );
    }
  }

  @override
  Future<bool> hasExistingCollaboration(
    String requesterId,
    String targetUserId,
  ) => _remote.hasExistingCollaboration(requesterId, targetUserId);

  @override
  Future<bool> hasActiveCollaborationBetween(String userId1, String userId2) =>
      _remote.hasActiveCollaborationBetween(userId1, userId2);

  @override
  Stream<List<CollaborationEntity>> watchCollaborationsByTargetUserId(
    String targetUserId, {
    CollaborationStatus? status,
  }) => _remote.watchCollaborationsByTargetUserId(targetUserId, status: status);

  @override
  Stream<List<CollaborationEntity>> watchCollaborationsByRequesterId(
    String requesterId, {
    CollaborationStatus? status,
  }) => _remote.watchCollaborationsByRequesterId(requesterId, status: status);
}
