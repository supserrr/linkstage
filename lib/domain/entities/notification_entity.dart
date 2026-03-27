import 'package:equatable/equatable.dart';

/// Type of notification derived from booking or collaboration activity.
enum NotificationType {
  bookingNewApplication,
  bookingInvited,
  bookingAccepted,
  bookingDeclined,
  bookingInvitationAccepted,
  bookingInvitationDeclined,
  collaborationNewProposal,
  collaborationAccepted,
  collaborationDeclined,
  plannerNewEvent,
  chatNewMessage,
}

/// Domain entity for an in-app notification.
class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.createdAt,
    required this.route,
    this.routeExtra,
    this.eventId,
    this.bookingId,
    this.collaborationId,
    this.conversationId,
    this.otherUserId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String? subtitle;
  final DateTime createdAt;
  /// Route to navigate to when tapped (e.g. AppRoutes.eventApplicants(eventId)).
  final String route;
  /// Extra data for routes that need it (e.g. collaboration detail).
  final Object? routeExtra;
  final String? eventId;
  final String? bookingId;
  final String? collaborationId;
  final String? conversationId;
  final String? otherUserId;

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        subtitle,
        createdAt,
        route,
        routeExtra,
        eventId,
        bookingId,
        collaborationId,
        conversationId,
        otherUserId,
      ];
}
