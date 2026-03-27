import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasources/user_remote_datasource.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/collaboration_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/user_repository.dart';

const int _maxNotifications = 50;

/// Implementation of [NotificationRepository] that aggregates from
/// bookings and collaborations with real-time streams.
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(
    this._bookingRepository,
    this._collaborationRepository,
    this._conversationRepository,
    this._eventRepository,
    this._userRepository,
    this._userRemoteDataSource,
  );

  final BookingRepository _bookingRepository;
  final CollaborationRepository _collaborationRepository;
  final ConversationRepository _conversationRepository;
  final EventRepository _eventRepository;
  final UserRepository _userRepository;
  final UserRemoteDataSource _userRemoteDataSource;

  @override
  Stream<List<NotificationEntity>> watchNotifications(
    String userId,
    UserRole role,
  ) {
    late StreamController<List<NotificationEntity>> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    List<BookingEntity> pendingBookings = [];
    List<BookingEntity> invitedBookings = [];
    List<BookingEntity> acceptedBookings = [];
    List<BookingEntity> declinedBookings = [];
    List<BookingEntity> invitationAcceptedBookings = [];
    List<BookingEntity> invitationDeclinedBookings = [];
    List<CollaborationEntity> collabsByTarget = [];
    List<CollaborationEntity> collabsByRequesterAccepted = [];
    List<CollaborationEntity> collabsByRequesterDeclined = [];
    List<Map<String, dynamic>> plannerNewEventDocs = [];
    List<ConversationEntity> unreadConversations = [];
    int emitSequence = 0;

    Future<void> rebuildAndEmit() async {
      final seq = ++emitSequence;
      final notifications = <NotificationEntity>[];

      if (role == UserRole.eventPlanner) {
        for (final b in pendingBookings) {
          final event = await _eventRepository.getEventById(b.eventId);
          final creative = await _userRepository.getUser(b.creativeId);
          final eventTitle = event?.title ?? 'Event';
          final creativeName = _displayName(creative, b.creativeId);
          final createdAt = b.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'booking-p-${b.id}',
            type: NotificationType.bookingNewApplication,
            title: 'New application for $eventTitle',
            subtitle: '$creativeName applied',
            createdAt: createdAt,
            route: '/event/${b.eventId}/applicants',
            eventId: b.eventId,
            bookingId: b.id,
            otherUserId: b.creativeId,
          ));
        }
        for (final c in collabsByRequesterAccepted) {
          final other = await _userRepository.getUser(c.targetUserId);
          final otherName = _displayName(other, c.targetUserId);
          final createdAt = c.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'collab-acc-${c.id}',
            type: NotificationType.collaborationAccepted,
            title: 'Proposal accepted',
            subtitle: '$otherName accepted your collaboration',
            createdAt: createdAt,
            route: '/collaboration/detail',
            routeExtra: {
              'collaboration': c,
              'otherPersonName': otherName,
              'otherPersonId': c.targetUserId,
              'otherPersonPhotoUrl': other?.photoUrl,
              'otherPersonRole': UserRole.creativeProfessional,
              'viewerIsCreative': false,
            },
            collaborationId: c.id,
            otherUserId: c.targetUserId,
          ));
        }
        for (final c in collabsByRequesterDeclined) {
          final other = await _userRepository.getUser(c.targetUserId);
          final otherName = _displayName(other, c.targetUserId);
          final createdAt = c.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'collab-dec-${c.id}',
            type: NotificationType.collaborationDeclined,
            title: 'Proposal declined',
            subtitle: '$otherName declined your collaboration',
            createdAt: createdAt,
            route: '/collaboration/detail',
            routeExtra: {
              'collaboration': c,
              'otherPersonName': otherName,
              'otherPersonId': c.targetUserId,
              'otherPersonPhotoUrl': other?.photoUrl,
              'otherPersonRole': UserRole.creativeProfessional,
              'viewerIsCreative': false,
            },
            collaborationId: c.id,
            otherUserId: c.targetUserId,
          ));
        }
        for (final b in invitationAcceptedBookings) {
          final event = await _eventRepository.getEventById(b.eventId);
          final creative = await _userRepository.getUser(b.creativeId);
          final eventTitle = event?.title ?? 'Event';
          final creativeName = _displayName(creative, b.creativeId);
          final createdAt = b.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'booking-ia-${b.id}',
            type: NotificationType.bookingInvitationAccepted,
            title: 'Invitation accepted',
            subtitle: '$creativeName accepted your invitation to $eventTitle',
            createdAt: createdAt,
            route: '/event/${b.eventId}/applicants',
            eventId: b.eventId,
            bookingId: b.id,
            otherUserId: b.creativeId,
          ));
        }
        for (final b in invitationDeclinedBookings) {
          final event = await _eventRepository.getEventById(b.eventId);
          final creative = await _userRepository.getUser(b.creativeId);
          final eventTitle = event?.title ?? 'Event';
          final creativeName = _displayName(creative, b.creativeId);
          final createdAt = b.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'booking-id-${b.id}',
            type: NotificationType.bookingInvitationDeclined,
            title: 'Invitation declined',
            subtitle: '$creativeName declined your invitation to $eventTitle',
            createdAt: createdAt,
            route: '/event/${b.eventId}/applicants',
            eventId: b.eventId,
            bookingId: b.id,
            otherUserId: b.creativeId,
          ));
        }
      } else {
        for (final b in invitedBookings) {
          final event = await _eventRepository.getEventById(b.eventId);
          final planner = await _userRepository.getUser(b.plannerId);
          final eventTitle = event?.title ?? 'Event';
          final plannerName = _displayName(planner, b.plannerId);
          final createdAt = b.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'booking-i-${b.id}',
            type: NotificationType.bookingInvited,
            title: 'Invitation to $eventTitle',
            subtitle: '$plannerName invited you',
            createdAt: createdAt,
            route: '/bookings',
            eventId: b.eventId,
            bookingId: b.id,
            otherUserId: b.plannerId,
          ));
        }
        for (final b in acceptedBookings) {
          final event = await _eventRepository.getEventById(b.eventId);
          final eventTitle = event?.title ?? 'Event';
          final createdAt = b.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'booking-a-${b.id}',
            type: NotificationType.bookingAccepted,
            title: 'Application accepted',
            subtitle: 'Your application for $eventTitle was accepted',
            createdAt: createdAt,
            route: '/event/${b.eventId}',
            eventId: b.eventId,
            bookingId: b.id,
          ));
        }
        for (final b in declinedBookings) {
          final event = await _eventRepository.getEventById(b.eventId);
          final eventTitle = event?.title ?? 'Event';
          final createdAt = b.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'booking-d-${b.id}',
            type: NotificationType.bookingDeclined,
            title: 'Application declined',
            subtitle: 'Your application for $eventTitle was declined',
            createdAt: createdAt,
            route: '/bookings',
            eventId: b.eventId,
            bookingId: b.id,
          ));
        }
        for (final c in collabsByTarget) {
          final other = await _userRepository.getUser(c.requesterId);
          final otherName = _displayName(other, c.requesterId);
          final createdAt = c.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'collab-p-${c.id}',
            type: NotificationType.collaborationNewProposal,
            title: 'New collaboration proposal',
            subtitle: '$otherName sent you a proposal',
            createdAt: createdAt,
            route: '/collaboration/detail',
            routeExtra: {
              'collaboration': c,
              'otherPersonName': otherName,
              'otherPersonId': c.requesterId,
              'otherPersonPhotoUrl': other?.photoUrl,
              'otherPersonRole': null,
              'viewerIsCreative': true,
            },
            collaborationId: c.id,
            otherUserId: c.requesterId,
          ));
        }
        for (final c in collabsByRequesterAccepted) {
          final other = await _userRepository.getUser(c.targetUserId);
          final otherName = _displayName(other, c.targetUserId);
          final createdAt = c.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'collab-acc-${c.id}',
            type: NotificationType.collaborationAccepted,
            title: 'Proposal accepted',
            subtitle: '$otherName accepted your collaboration',
            createdAt: createdAt,
            route: '/collaboration/detail',
            routeExtra: {
              'collaboration': c,
              'otherPersonName': otherName,
              'otherPersonId': c.targetUserId,
              'otherPersonPhotoUrl': other?.photoUrl,
              'otherPersonRole': UserRole.creativeProfessional,
              'viewerIsCreative': true,
            },
            collaborationId: c.id,
            otherUserId: c.targetUserId,
          ));
        }
        for (final c in collabsByRequesterDeclined) {
          final other = await _userRepository.getUser(c.targetUserId);
          final otherName = _displayName(other, c.targetUserId);
          final createdAt = c.createdAt ?? DateTime.now();
          notifications.add(NotificationEntity(
            id: 'collab-dec-${c.id}',
            type: NotificationType.collaborationDeclined,
            title: 'Proposal declined',
            subtitle: '$otherName declined your collaboration',
            createdAt: createdAt,
            route: '/collaboration/detail',
            routeExtra: {
              'collaboration': c,
              'otherPersonName': otherName,
              'otherPersonId': c.targetUserId,
              'otherPersonPhotoUrl': other?.photoUrl,
              'otherPersonRole': UserRole.creativeProfessional,
              'viewerIsCreative': true,
            },
            collaborationId: c.id,
            otherUserId: c.targetUserId,
          ));
        }
        for (final doc in plannerNewEventDocs) {
          final eventId = doc['eventId'] as String?;
          final plannerName = doc['plannerName'] as String? ?? 'A planner';
          final eventTitle = doc['eventTitle'] as String? ?? 'Event';
          final createdAtRaw = doc['createdAt'];
          DateTime createdAt;
          if (createdAtRaw is Timestamp) {
            createdAt = createdAtRaw.toDate();
          } else if (createdAtRaw is DateTime) {
            createdAt = createdAtRaw;
          } else {
            createdAt = DateTime.now();
          }
          if (eventId == null || eventId.isEmpty) continue;
          final docId = doc['id'] as String? ?? eventId;
          notifications.add(NotificationEntity(
            id: 'planner-new-event-$docId',
            type: NotificationType.plannerNewEvent,
            title: '$plannerName posted a new event',
            subtitle: eventTitle,
            createdAt: createdAt,
            route: '/event/$eventId',
            eventId: eventId,
            otherUserId: doc['plannerId'] as String?,
          ));
        }
      }

      for (final c in unreadConversations) {
        final otherName =
            c.otherUserDisplayName?.trim().isNotEmpty == true
                ? c.otherUserDisplayName!
                : 'Someone';
        final createdAt =
            c.lastMessageAt ?? c.createdAt ?? DateTime.now();
        notifications.add(NotificationEntity(
          id: 'chat-${c.id}',
          type: NotificationType.chatNewMessage,
          title: '$otherName sent a message',
          subtitle: c.lastMessageText,
          createdAt: createdAt,
          route: '/messages/chat/${c.id}',
          conversationId: c.id,
          otherUserId: c.otherUserId,
        ));
      }

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final limited = notifications.take(_maxNotifications).toList();

      if (seq == emitSequence && !controller.isClosed) {
        controller.add(limited);
      }
    }

    void onData(void Function() update) {
      update();
      rebuildAndEmit();
    }

    controller = StreamController<List<NotificationEntity>>.broadcast(
      onListen: () {
        if (role == UserRole.eventPlanner) {
          subscriptions.add(
            _bookingRepository
                .watchPendingBookingsByPlannerId(userId)
                .listen((list) => onData(() => pendingBookings = list)),
          );
          subscriptions.add(
            _collaborationRepository
                .watchCollaborationsByRequesterId(
                  userId,
                  status: CollaborationStatus.accepted,
                )
                .listen(
                  (list) => onData(() => collabsByRequesterAccepted = list),
                ),
          );
          subscriptions.add(
            _collaborationRepository
                .watchCollaborationsByRequesterId(
                  userId,
                  status: CollaborationStatus.declined,
                )
                .listen(
                  (list) => onData(() => collabsByRequesterDeclined = list),
                ),
          );
          subscriptions.add(
            _bookingRepository
                .watchAcceptedInvitationBookingsByPlannerId(userId)
                .listen(
                  (list) => onData(() => invitationAcceptedBookings = list),
                ),
          );
          subscriptions.add(
            _bookingRepository
                .watchDeclinedInvitationBookingsByPlannerId(userId)
                .listen(
                  (list) => onData(() => invitationDeclinedBookings = list),
                ),
          );
        } else {
          subscriptions.add(
            _bookingRepository
                .watchInvitedBookingsByCreativeId(userId)
                .listen((list) => onData(() => invitedBookings = list)),
          );
          subscriptions.add(
            _bookingRepository
                .watchAcceptedBookingsByCreativeId(userId)
                .listen((list) => onData(() => acceptedBookings = list)),
          );
          subscriptions.add(
            _bookingRepository
                .watchDeclinedBookingsByCreativeId(userId)
                .listen((list) => onData(() => declinedBookings = list)),
          );
          subscriptions.add(
            _collaborationRepository
                .watchCollaborationsByTargetUserId(
                  userId,
                  status: CollaborationStatus.pending,
                )
                .listen((list) => onData(() => collabsByTarget = list)),
          );
          subscriptions.add(
            _collaborationRepository
                .watchCollaborationsByRequesterId(
                  userId,
                  status: CollaborationStatus.accepted,
                )
                .listen(
                  (list) => onData(() => collabsByRequesterAccepted = list),
                ),
          );
          subscriptions.add(
            _collaborationRepository
                .watchCollaborationsByRequesterId(
                  userId,
                  status: CollaborationStatus.declined,
                )
                .listen(
                  (list) => onData(() => collabsByRequesterDeclined = list),
                ),
          );
          subscriptions.add(
            _userRemoteDataSource
                .watchPlannerNewEventNotifications(userId)
                .listen((list) => onData(() => plannerNewEventDocs = list)),
          );
        }
        subscriptions.add(
          _conversationRepository
              .watchConversations(userId)
              .listen((list) => onData(() => unreadConversations = list)),
        );
      },
      onCancel: () {
        for (final s in subscriptions) {
          s.cancel();
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    await _userRemoteDataSource.markNotificationAsRead(userId, notificationId);
  }

  @override
  Future<void> markAllAsRead(
    String userId,
    List<String> notificationIds,
  ) async {
    await _userRemoteDataSource.markAllNotificationsAsRead(
      userId,
      notificationIds,
    );
  }

  @override
  Stream<Set<String>> watchReadNotificationIds(String userId) {
    return _userRemoteDataSource.watchNotificationReadIds(userId);
  }

  String _displayName(UserEntity? user, String fallbackId) {
    if (user == null) return 'Someone';
    return user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : (user.username?.trim().isNotEmpty == true
            ? '@${user.username}'
            : user.email.split('@').firstOrNull ?? 'Someone');
  }
}
