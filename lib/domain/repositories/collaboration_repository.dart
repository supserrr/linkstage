import '../entities/collaboration_entity.dart';

/// Abstract contract for collaboration operations.
abstract class CollaborationRepository {
  /// Create a collaboration proposal.
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
  });

  /// Fetch collaborations where the given user is the target (incoming proposals).
  Future<List<CollaborationEntity>> getCollaborationsByTargetUserId(
    String targetUserId, {
    CollaborationStatus? status,
  });

  /// Fetch collaborations for a given event (where eventId matches).
  Future<List<CollaborationEntity>> getCollaborationsByEventId(
    String eventId, {
    CollaborationStatus? status,
  });

  /// Fetch collaborations where the given user is the requester (outgoing/sent proposals).
  Future<List<CollaborationEntity>> getCollaborationsByRequesterId(
    String requesterId, {
    CollaborationStatus? status,
  });

  /// Update collaboration status (accept/decline/complete).
  /// When status is completed, [confirmingIsPlanner] sets the appropriate timestamp.
  Future<void> updateStatus(
    String collaborationId,
    CollaborationStatus status, {
    bool? confirmingIsPlanner,
  });

  /// Creative confirms they completed the work (sets creativeConfirmedAt).
  Future<void> confirmCompletionByCreative(String collaborationId);

  /// Mark all accepted collaborations for an event as completed (cascade when event is completed).
  Future<void> completeAcceptedCollaborationsForEvent(String eventId);

  /// Check if requester already has an active (pending/accepted) proposal to target.
  Future<bool> hasExistingCollaboration(
    String requesterId,
    String targetUserId,
  );

  /// Check if there is any active collaboration between the two users (either direction).
  Future<bool> hasActiveCollaborationBetween(String userId1, String userId2);

  /// Stream of collaborations where the given user is the target (incoming proposals).
  Stream<List<CollaborationEntity>> watchCollaborationsByTargetUserId(
    String targetUserId, {
    CollaborationStatus? status,
  });

  /// Stream of collaborations where the given user is the requester (outgoing proposals).
  Stream<List<CollaborationEntity>> watchCollaborationsByRequesterId(
    String requesterId, {
    CollaborationStatus? status,
  });
}
