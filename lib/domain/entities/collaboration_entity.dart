import 'package:equatable/equatable.dart';

/// Collaboration proposal status.
enum CollaborationStatus { pending, accepted, declined, completed }

/// Domain entity for a collaboration proposal.
class CollaborationEntity extends Equatable {
  const CollaborationEntity({
    required this.id,
    required this.requesterId,
    required this.targetUserId,
    required this.description,
    this.status = CollaborationStatus.pending,
    this.title,
    this.eventId,
    this.createdAt,
    this.budget,
    this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.eventType,
    this.plannerConfirmedAt,
    this.creativeConfirmedAt,
  });

  final String id;
  final String requesterId;
  final String targetUserId;
  final String description;
  final CollaborationStatus status;

  /// Display name for collaborations not tied to an event.
  final String? title;
  final String? eventId;
  final DateTime? createdAt;
  final double? budget;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? eventType;
  final DateTime? plannerConfirmedAt;
  final DateTime? creativeConfirmedAt;

  /// Display name for UI: title ?? eventType ?? truncated description ?? 'Collaboration'.
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!;
    if (eventType != null && eventType!.trim().isNotEmpty) return eventType!;
    if (description.isNotEmpty) {
      final truncated = description.length > 50
          ? '${description.substring(0, 50)}...'
          : description;
      return truncated;
    }
    return 'Collaboration';
  }

  static CollaborationStatus? statusFromKey(String? key) {
    switch (key) {
      case 'pending':
        return CollaborationStatus.pending;
      case 'accepted':
        return CollaborationStatus.accepted;
      case 'declined':
        return CollaborationStatus.declined;
      case 'completed':
        return CollaborationStatus.completed;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
    id,
    requesterId,
    targetUserId,
    description,
    status,
    title,
    eventId,
    createdAt,
    budget,
    date,
    startTime,
    endTime,
    location,
    eventType,
    plannerConfirmedAt,
    creativeConfirmedAt,
  ];
}
