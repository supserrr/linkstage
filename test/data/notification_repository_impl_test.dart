import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/user_remote_datasource.dart';
import 'package:linkstage/data/repositories/notification_repository_impl.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/conversation_entity.dart';
import 'package:linkstage/domain/entities/notification_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/conversation_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import '../fixtures/entity_fixtures.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserRole.eventPlanner);
    registerFallbackValue(CollaborationStatus.pending);
  });

  test('planner role emits bookingNewApplication', () async {
    final bookingRepo = MockBookingRepository();
    final collabRepo = MockCollaborationRepository();
    final convoRepo = MockConversationRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final userRemote = MockUserRemoteDataSource();

    final booking = fakeBooking(
      id: 'b1',
      eventId: 'e1',
      creativeId: 'c1',
      plannerId: 'planner-1',
    );

    when(
      () => bookingRepo.watchPendingBookingsByPlannerId('planner-1'),
    ).thenAnswer((_) => Stream.value([booking]));
    when(
      () => collabRepo.watchCollaborationsByRequesterId(
        'planner-1',
        status: CollaborationStatus.accepted,
      ),
    ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());
    when(
      () => collabRepo.watchCollaborationsByRequesterId(
        'planner-1',
        status: CollaborationStatus.declined,
      ),
    ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());
    when(
      () => bookingRepo.watchAcceptedInvitationBookingsByPlannerId('planner-1'),
    ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
    when(
      () => bookingRepo.watchDeclinedInvitationBookingsByPlannerId('planner-1'),
    ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());

    when(
      () => eventRepo.getEventById('e1'),
    ).thenAnswer((_) async => fakeEvent(id: 'e1', plannerId: 'planner-1'));
    when(
      () => userRepo.getUser('c1'),
    ).thenAnswer((_) async => fakeUser(id: 'c1', email: 'c1@test.com'));

    when(
      () => convoRepo.watchConversations('planner-1'),
    ).thenAnswer((_) => const Stream<List<ConversationEntity>>.empty());

    when(
      () => userRemote.watchPlannerNewEventNotifications(any()),
    ).thenAnswer((_) => const Stream<List<Map<String, dynamic>>>.empty());

    final repo = NotificationRepositoryImpl(
      bookingRepo,
      collabRepo,
      convoRepo,
      eventRepo,
      userRepo,
      userRemote,
    );

    final list = await repo
        .watchNotifications('planner-1', UserRole.eventPlanner)
        .firstWhere(
          (l) => l.any((n) => n.type == NotificationType.bookingNewApplication),
        )
        .timeout(const Duration(seconds: 2));

    expect(list.any((n) => n.route == '/event/e1/applicants'), isTrue);
    expect(list.any((n) => n.otherUserId == 'c1'), isTrue);
  });

  test('limits notifications to maxNotifications (50)', () async {
    final bookingRepo = MockBookingRepository();
    final collabRepo = MockCollaborationRepository();
    final convoRepo = MockConversationRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final userRemote = MockUserRemoteDataSource();

    when(
      () => bookingRepo.watchPendingBookingsByPlannerId('planner-1'),
    ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
    when(
      () => collabRepo.watchCollaborationsByRequesterId(
        'planner-1',
        status: CollaborationStatus.accepted,
      ),
    ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());
    when(
      () => collabRepo.watchCollaborationsByRequesterId(
        'planner-1',
        status: CollaborationStatus.declined,
      ),
    ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());
    when(
      () => bookingRepo.watchAcceptedInvitationBookingsByPlannerId('planner-1'),
    ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
    when(
      () => bookingRepo.watchDeclinedInvitationBookingsByPlannerId('planner-1'),
    ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
    when(
      () => userRemote.watchPlannerNewEventNotifications(any()),
    ).thenAnswer((_) => const Stream<List<Map<String, dynamic>>>.empty());

    final convos = List.generate(
      60,
      (i) => ConversationEntity(
        id: 'chat-$i',
        otherUserId: 'u$i',
        otherUserDisplayName: 'U$i',
        lastMessageText: 'm$i',
        lastMessageAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        hasUnread: true,
        unreadCount: 1,
      ),
    );
    when(
      () => convoRepo.watchConversations('planner-1'),
    ).thenAnswer((_) => Stream.value(convos));

    final repo = NotificationRepositoryImpl(
      bookingRepo,
      collabRepo,
      convoRepo,
      eventRepo,
      userRepo,
      userRemote,
    );

    final list = await repo
        .watchNotifications('planner-1', UserRole.eventPlanner)
        .firstWhere((l) => l.length == 50)
        .timeout(const Duration(seconds: 2));

    expect(list, hasLength(50));
    expect(list.first.createdAt.isAfter(list.last.createdAt), isTrue);
  });

  test(
    'creative role emits bookingInvited + collaborationNewProposal + chatNewMessage',
    () async {
      final bookingRepo = MockBookingRepository();
      final collabRepo = MockCollaborationRepository();
      final convoRepo = MockConversationRepository();
      final eventRepo = MockEventRepository();
      final userRepo = MockUserRepository();
      final userRemote = MockUserRemoteDataSource();

      final invited = fakeBooking(
        id: 'bi-1',
        eventId: 'e1',
        creativeId: 'creative-1',
        plannerId: 'planner-1',
        status: BookingStatus.invited,
      );
      when(
        () => bookingRepo.watchInvitedBookingsByCreativeId('creative-1'),
      ).thenAnswer((_) => Stream.value([invited]));
      when(
        () => bookingRepo.watchAcceptedBookingsByCreativeId('creative-1'),
      ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
      when(
        () => bookingRepo.watchDeclinedBookingsByCreativeId('creative-1'),
      ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());

      final proposal = fakeCollaboration(
        id: 'c1',
        requesterId: 'planner-1',
        targetUserId: 'creative-1',
        status: CollaborationStatus.pending,
      );
      when(
        () => collabRepo.watchCollaborationsByTargetUserId(
          'creative-1',
          status: CollaborationStatus.pending,
        ),
      ).thenAnswer((_) => Stream.value([proposal]));
      when(
        () => collabRepo.watchCollaborationsByRequesterId(
          'creative-1',
          status: CollaborationStatus.accepted,
        ),
      ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());
      when(
        () => collabRepo.watchCollaborationsByRequesterId(
          'creative-1',
          status: CollaborationStatus.declined,
        ),
      ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());

      when(
        () => eventRepo.getEventById('e1'),
      ).thenAnswer((_) async => fakeEvent(id: 'e1', plannerId: 'planner-1'));
      when(() => userRepo.getUser('planner-1')).thenAnswer(
        (_) async => fakeUser(
          id: 'planner-1',
          email: 'p@test.com',
          role: UserRole.eventPlanner,
        ),
      );

      when(() => convoRepo.watchConversations('creative-1')).thenAnswer(
        (_) => Stream.value([
          ConversationEntity(
            id: 'chat-1',
            otherUserId: 'planner-1',
            otherUserDisplayName: 'Planner',
            lastMessageText: 'Hello',
            lastMessageAt: DateTime.utc(2026, 2, 1),
            hasUnread: true,
            unreadCount: 1,
          ),
        ]),
      );

      when(
        () => userRemote.watchPlannerNewEventNotifications(any()),
      ).thenAnswer((_) => const Stream<List<Map<String, dynamic>>>.empty());

      final repo = NotificationRepositoryImpl(
        bookingRepo,
        collabRepo,
        convoRepo,
        eventRepo,
        userRepo,
        userRemote,
      );

      final list = await repo
          .watchNotifications('creative-1', UserRole.creativeProfessional)
          .firstWhere(
            (l) =>
                l.any((n) => n.type == NotificationType.bookingInvited) &&
                l.any(
                  (n) => n.type == NotificationType.collaborationNewProposal,
                ) &&
                l.any((n) => n.type == NotificationType.chatNewMessage),
          )
          .timeout(const Duration(seconds: 2));

      expect(
        list.any(
          (n) =>
              n.type == NotificationType.bookingInvited &&
              n.route == '/bookings',
        ),
        isTrue,
      );
      expect(
        list.any(
          (n) =>
              n.type == NotificationType.collaborationNewProposal &&
              n.collaborationId == 'c1',
        ),
        isTrue,
      );
      expect(
        list.any(
          (n) =>
              n.type == NotificationType.chatNewMessage &&
              n.route == '/messages/chat/chat-1',
        ),
        isTrue,
      );
    },
  );

  test(
    'planner role emits collaborationAccepted and collaborationDeclined',
    () async {
      final bookingRepo = MockBookingRepository();
      final collabRepo = MockCollaborationRepository();
      final convoRepo = MockConversationRepository();
      final eventRepo = MockEventRepository();
      final userRepo = MockUserRepository();
      final userRemote = MockUserRemoteDataSource();

      when(
        () => bookingRepo.watchPendingBookingsByPlannerId('planner-1'),
      ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
      when(
        () => collabRepo.watchCollaborationsByRequesterId(
          'planner-1',
          status: CollaborationStatus.accepted,
        ),
      ).thenAnswer(
        (_) => Stream.value([
          fakeCollaboration(
            id: 'ca',
            requesterId: 'planner-1',
            targetUserId: 't1',
            status: CollaborationStatus.accepted,
          ),
        ]),
      );
      when(
        () => collabRepo.watchCollaborationsByRequesterId(
          'planner-1',
          status: CollaborationStatus.declined,
        ),
      ).thenAnswer(
        (_) => Stream.value([
          fakeCollaboration(
            id: 'cd',
            requesterId: 'planner-1',
            targetUserId: 't2',
            status: CollaborationStatus.declined,
          ),
        ]),
      );
      when(
        () =>
            bookingRepo.watchAcceptedInvitationBookingsByPlannerId('planner-1'),
      ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
      when(
        () =>
            bookingRepo.watchDeclinedInvitationBookingsByPlannerId('planner-1'),
      ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
      when(
        () => convoRepo.watchConversations('planner-1'),
      ).thenAnswer((_) => const Stream<List<ConversationEntity>>.empty());
      when(
        () => userRemote.watchPlannerNewEventNotifications(any()),
      ).thenAnswer((_) => const Stream<List<Map<String, dynamic>>>.empty());

      when(
        () => userRepo.getUser('t1'),
      ).thenAnswer((_) async => fakeUser(id: 't1', email: 't1@test.com'));
      when(
        () => userRepo.getUser('t2'),
      ).thenAnswer((_) async => fakeUser(id: 't2', email: 't2@test.com'));

      final repo = NotificationRepositoryImpl(
        bookingRepo,
        collabRepo,
        convoRepo,
        eventRepo,
        userRepo,
        userRemote,
      );

      final list = await repo
          .watchNotifications('planner-1', UserRole.eventPlanner)
          .firstWhere(
            (l) =>
                l.any(
                  (n) => n.type == NotificationType.collaborationAccepted,
                ) &&
                l.any((n) => n.type == NotificationType.collaborationDeclined),
          )
          .timeout(const Duration(seconds: 2));

      expect(list.any((n) => n.collaborationId == 'ca'), isTrue);
      expect(list.any((n) => n.collaborationId == 'cd'), isTrue);
    },
  );

  test(
    'planner role emits bookingInvitationAccepted and bookingInvitationDeclined',
    () async {
      final bookingRepo = MockBookingRepository();
      final collabRepo = MockCollaborationRepository();
      final convoRepo = MockConversationRepository();
      final eventRepo = MockEventRepository();
      final userRepo = MockUserRepository();
      final userRemote = MockUserRemoteDataSource();

      when(
        () => bookingRepo.watchPendingBookingsByPlannerId('planner-1'),
      ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
      when(
        () => collabRepo.watchCollaborationsByRequesterId(
          'planner-1',
          status: CollaborationStatus.accepted,
        ),
      ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());
      when(
        () => collabRepo.watchCollaborationsByRequesterId(
          'planner-1',
          status: CollaborationStatus.declined,
        ),
      ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());

      final ia = fakeBooking(
        id: 'ia-1',
        eventId: 'ev-ia',
        creativeId: 'cr-ia',
        plannerId: 'planner-1',
        status: BookingStatus.accepted,
      );
      final id = fakeBooking(
        id: 'id-1',
        eventId: 'ev-id',
        creativeId: 'cr-id',
        plannerId: 'planner-1',
        status: BookingStatus.declined,
      );
      when(
        () =>
            bookingRepo.watchAcceptedInvitationBookingsByPlannerId('planner-1'),
      ).thenAnswer((_) => Stream.value([ia]));
      when(
        () =>
            bookingRepo.watchDeclinedInvitationBookingsByPlannerId('planner-1'),
      ).thenAnswer((_) => Stream.value([id]));

      when(
        () => eventRepo.getEventById('ev-ia'),
      ).thenAnswer((_) async => fakeEvent(id: 'ev-ia'));
      when(
        () => eventRepo.getEventById('ev-id'),
      ).thenAnswer((_) async => fakeEvent(id: 'ev-id'));
      when(
        () => userRepo.getUser('cr-ia'),
      ).thenAnswer((_) async => fakeUser(id: 'cr-ia'));
      when(
        () => userRepo.getUser('cr-id'),
      ).thenAnswer((_) async => fakeUser(id: 'cr-id'));

      when(
        () => convoRepo.watchConversations('planner-1'),
      ).thenAnswer((_) => const Stream<List<ConversationEntity>>.empty());
      when(
        () => userRemote.watchPlannerNewEventNotifications(any()),
      ).thenAnswer((_) => const Stream<List<Map<String, dynamic>>>.empty());

      final repo = NotificationRepositoryImpl(
        bookingRepo,
        collabRepo,
        convoRepo,
        eventRepo,
        userRepo,
        userRemote,
      );

      final list = await repo
          .watchNotifications('planner-1', UserRole.eventPlanner)
          .firstWhere(
            (l) =>
                l.any(
                  (n) => n.type == NotificationType.bookingInvitationAccepted,
                ) &&
                l.any(
                  (n) => n.type == NotificationType.bookingInvitationDeclined,
                ),
          )
          .timeout(const Duration(seconds: 2));

      expect(list.any((n) => n.bookingId == 'ia-1'), isTrue);
      expect(list.any((n) => n.bookingId == 'id-1'), isTrue);
    },
  );

  test(
    'creative role emits bookingAccepted, bookingDeclined, plannerNewEvent',
    () async {
      final bookingRepo = MockBookingRepository();
      final collabRepo = MockCollaborationRepository();
      final convoRepo = MockConversationRepository();
      final eventRepo = MockEventRepository();
      final userRepo = MockUserRepository();
      final userRemote = MockUserRemoteDataSource();

      final accepted = fakeBooking(
        id: 'ba',
        eventId: 'e-acc',
        creativeId: 'creative-1',
        plannerId: 'pl-1',
        status: BookingStatus.accepted,
      );
      final declined = fakeBooking(
        id: 'bd',
        eventId: 'e-dec',
        creativeId: 'creative-1',
        plannerId: 'pl-2',
        status: BookingStatus.declined,
      );

      when(
        () => bookingRepo.watchInvitedBookingsByCreativeId('creative-1'),
      ).thenAnswer((_) => const Stream<List<BookingEntity>>.empty());
      when(
        () => bookingRepo.watchAcceptedBookingsByCreativeId('creative-1'),
      ).thenAnswer((_) => Stream.value([accepted]));
      when(
        () => bookingRepo.watchDeclinedBookingsByCreativeId('creative-1'),
      ).thenAnswer((_) => Stream.value([declined]));
      when(
        () => collabRepo.watchCollaborationsByTargetUserId(
          'creative-1',
          status: CollaborationStatus.pending,
        ),
      ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());
      when(
        () => collabRepo.watchCollaborationsByRequesterId(
          'creative-1',
          status: CollaborationStatus.accepted,
        ),
      ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());
      when(
        () => collabRepo.watchCollaborationsByRequesterId(
          'creative-1',
          status: CollaborationStatus.declined,
        ),
      ).thenAnswer((_) => const Stream<List<CollaborationEntity>>.empty());

      when(
        () => eventRepo.getEventById('e-acc'),
      ).thenAnswer((_) async => fakeEvent(id: 'e-acc', title: 'Acc'));
      when(
        () => eventRepo.getEventById('e-dec'),
      ).thenAnswer((_) async => fakeEvent(id: 'e-dec', title: 'Dec'));

      when(
        () => userRemote.watchPlannerNewEventNotifications('creative-1'),
      ).thenAnswer(
        (_) => Stream.value([
          {
            'id': 'pn1',
            'eventId': 'e-new',
            'plannerName': 'Planner X',
            'eventTitle': 'New gig',
            'createdAt': DateTime.utc(2026, 3, 1),
          },
        ]),
      );

      when(
        () => convoRepo.watchConversations('creative-1'),
      ).thenAnswer((_) => const Stream<List<ConversationEntity>>.empty());

      final repo = NotificationRepositoryImpl(
        bookingRepo,
        collabRepo,
        convoRepo,
        eventRepo,
        userRepo,
        userRemote,
      );

      final list = await repo
          .watchNotifications('creative-1', UserRole.creativeProfessional)
          .firstWhere(
            (l) =>
                l.any((n) => n.type == NotificationType.bookingAccepted) &&
                l.any((n) => n.type == NotificationType.bookingDeclined) &&
                l.any((n) => n.type == NotificationType.plannerNewEvent),
          )
          .timeout(const Duration(seconds: 2));

      expect(
        list.any((n) => n.type == NotificationType.plannerNewEvent),
        isTrue,
      );
    },
  );

  test('markAsRead and markAllAsRead delegate to user remote', () async {
    final bookingRepo = MockBookingRepository();
    final collabRepo = MockCollaborationRepository();
    final convoRepo = MockConversationRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final userRemote = MockUserRemoteDataSource();

    when(
      () => userRemote.markNotificationAsRead('u1', 'n1'),
    ).thenAnswer((_) async {});
    when(
      () => userRemote.markAllNotificationsAsRead('u1', ['a', 'b']),
    ).thenAnswer((_) async {});

    final repo = NotificationRepositoryImpl(
      bookingRepo,
      collabRepo,
      convoRepo,
      eventRepo,
      userRepo,
      userRemote,
    );

    await repo.markAsRead('u1', 'n1');
    await repo.markAllAsRead('u1', ['a', 'b']);

    verify(() => userRemote.markNotificationAsRead('u1', 'n1')).called(1);
    verify(
      () => userRemote.markAllNotificationsAsRead('u1', ['a', 'b']),
    ).called(1);
  });

  test('watchReadNotificationIds forwards stream', () async {
    final bookingRepo = MockBookingRepository();
    final collabRepo = MockCollaborationRepository();
    final convoRepo = MockConversationRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final userRemote = MockUserRemoteDataSource();

    when(
      () => userRemote.watchNotificationReadIds('u1'),
    ).thenAnswer((_) => Stream.value({'a', 'b'}));

    final repo = NotificationRepositoryImpl(
      bookingRepo,
      collabRepo,
      convoRepo,
      eventRepo,
      userRepo,
      userRemote,
    );

    final s = await repo.watchReadNotificationIds('u1').first;
    expect(s, {'a', 'b'});
  });
}
