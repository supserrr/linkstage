import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/services/push_notification_service.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/bookings/bookings_cubit.dart';
import 'package:linkstage/presentation/bloc/bookings/bookings_state.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/presentation/pages/bookings_page.dart';
import 'package:linkstage/presentation/widgets/molecules/connection_error_overlay.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/router/app_router.dart';
import '../../fixtures/entity_fixtures.dart';
import 'package:mocktail/mocktail.dart';

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockBookingsCubit extends Mock implements BookingsCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const BookingsState());
    registerFallbackValue(BookingStatus.pending);
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  void registerPush() {
    final push = MockPushNotificationService();
    when(
      () => push.syncAcceptedEventId(
        creativeId: any(named: 'creativeId'),
        eventId: any(named: 'eventId'),
        add: any(named: 'add'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => push.notifyUser(
        targetUserId: any(named: 'targetUserId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});
    sl.registerSingleton<PushNotificationService>(push);
  }

  void registerBookingsSlForCreative() {
    final collabRepo = MockCollaborationRepository();
    final bookingRepo = MockBookingRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    when(
      () => collabRepo.getCollaborationsByTargetUserId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getInvitedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getPendingBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getAcceptedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getCompletedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);

    when(() => eventRepo.getEventById(any())).thenAnswer((_) async => null);
    when(() => userRepo.getUser(any())).thenAnswer((_) async => null);

    sl
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<AuthRedirectNotifier>(auth);
    registerPush();
  }

  void registerBookingsSlForPlanner() {
    final collabRepo = MockCollaborationRepository();
    final bookingRepo = MockBookingRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );

    when(
      () => collabRepo.getCollaborationsByTargetUserId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getInvitedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getPendingBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getAcceptedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getCompletedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);

    when(() => eventRepo.getEventById(any())).thenAnswer((_) async => null);
    when(() => userRepo.getUser(any())).thenAnswer((_) async => null);

    sl
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<AuthRedirectNotifier>(auth);
    registerPush();
  }

  testWidgets('shows Gigs tabs for creative user', (tester) async {
    registerBookingsSlForCreative();

    await tester.pumpWidget(const MaterialApp(home: BookingsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Gigs'), findsWidgets);
    expect(find.text('Collaborations'), findsOneWidget);
  });

  testWidgets('BookingsPage scaffold renders', (tester) async {
    registerBookingsSlForCreative();

    await tester.pumpWidget(const MaterialApp(home: BookingsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(BookingsPage), findsOneWidget);
  });

  testWidgets('planner sees browse empty state for gigs', (tester) async {
    registerBookingsSlForPlanner();

    await tester.pumpWidget(const MaterialApp(home: BookingsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Browse events'), findsOneWidget);
  });

  testWidgets(
    'injected cubit: gigs tab shows booking skeletons while loading',
    (tester) async {
      registerBookingsSlForCreative();
      final cubit = MockBookingsCubit();
      when(() => cubit.load()).thenAnswer((_) async {});
      whenListen<BookingsState>(
        cubit,
        const Stream<BookingsState>.empty(),
        initialState: const BookingsState(loading: true),
      );

      await tester.pumpWidget(
        MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BookingEventTileSkeleton), findsWidgets);
    },
  );

  testWidgets('injected cubit: gigs tab shows empty state when idle', (
    tester,
  ) async {
    registerBookingsSlForCreative();
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: const BookingsState(loading: false),
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('No gigs yet', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('injected cubit: gigs tab wraps body in error overlay', (
    tester,
  ) async {
    registerBookingsSlForCreative();
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: const BookingsState(loading: false, error: 'timeout'),
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(ConnectionErrorOverlay), findsWidgets);
  });

  testWidgets('injected cubit: shows Applications when pending bookings', (
    tester,
  ) async {
    registerBookingsSlForCreative();
    final booking = fakeBooking();
    final event = fakeEvent(id: booking.eventId);
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: BookingsState(
        loading: false,
        applications: [booking],
        events: {booking.eventId: event},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Applications'), findsOneWidget);
  });

  testWidgets('tapping Refresh calls cubit.load', (tester) async {
    registerBookingsSlForCreative();
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: const BookingsState(loading: false),
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();

    verify(() => cubit.load()).called(1);
  });

  testWidgets('Collaborations tab shows empty state when no proposals', (
    tester,
  ) async {
    registerBookingsSlForCreative();
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: const BookingsState(loading: false),
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Collaborations'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No collaboration proposals yet'), findsOneWidget);
  });

  testWidgets('Collaborations empty state Browse events navigates to Explore', (
    tester,
  ) async {
    registerBookingsSlForCreative();
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: const BookingsState(loading: false),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.bookings,
      routes: [
        GoRoute(
          path: AppRoutes.bookings,
          builder: (context, state) => BookingsPage(bookingsCubit: cubit),
        ),
        GoRoute(
          path: AppRoutes.explore,
          builder: (context, state) => const Scaffold(body: Text('Explore')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Collaborations'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Browse events'));
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsOneWidget);
  });

  testWidgets('Collaborations tab shows skeletons while loading', (
    tester,
  ) async {
    registerBookingsSlForCreative();
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: const BookingsState(loading: true),
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Collaborations'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CollaborationProposalTileSkeleton), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'Collaborations populated shows sections and View details navigates',
    (tester) async {
      registerBookingsSlForCreative();
      final cubit = MockBookingsCubit();
      when(() => cubit.load()).thenAnswer((_) async {});

      final active = fakeCollaboration(
        id: 'c1',
        requesterId: 'r1',
        targetUserId: 'creative-1',
        status: CollaborationStatus.pending,
      );
      final past = fakeCollaboration(
        id: 'c2',
        requesterId: 'r1',
        targetUserId: 'creative-1',
        status: CollaborationStatus.completed,
      );

      final seeded = BookingsState(
        loading: false,
        collaborations: [active, past],
        requesterNames: const {'r1': 'Requester'},
        requesterRoles: const {'r1': UserRole.eventPlanner},
      );
      when(() => cubit.state).thenReturn(seeded);
      whenListen<BookingsState>(
        cubit,
        const Stream<BookingsState>.empty(),
        initialState: seeded,
      );

      final router = GoRouter(
        initialLocation: AppRoutes.bookings,
        routes: [
          GoRoute(
            path: AppRoutes.bookings,
            builder: (context, state) => BookingsPage(bookingsCubit: cubit),
          ),
          GoRoute(
            path: AppRoutes.collaborationDetail,
            builder: (context, state) =>
                const Scaffold(body: Text('Collab detail')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Collaborations'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Requester'), findsWidgets);

      await tester.tap(find.widgetWithText(TextButton, 'View details').first);
      await tester.pumpAndSettle();

      expect(find.text('Collab detail'), findsOneWidget);
    },
  );

  testWidgets('planner empty state Browse events navigates to Explore', (
    tester,
  ) async {
    registerBookingsSlForPlanner();

    final router = GoRouter(
      initialLocation: AppRoutes.bookings,
      routes: [
        GoRoute(
          path: AppRoutes.bookings,
          builder: (context, state) => const BookingsPage(),
        ),
        GoRoute(
          path: AppRoutes.explore,
          builder: (context, state) =>
              const Scaffold(body: Text('ExploreStub')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Browse events'));
    await tester.pumpAndSettle();

    expect(find.text('ExploreStub'), findsOneWidget);
  });

  testWidgets('invited booking Accept updates status and reloads', (
    tester,
  ) async {
    final collabRepo = MockCollaborationRepository();
    final bookingRepo = MockBookingRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    when(
      () => collabRepo.getCollaborationsByTargetUserId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getInvitedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getPendingBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getAcceptedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getCompletedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.updateBookingStatus(any(), any()),
    ).thenAnswer((_) async {});

    when(() => eventRepo.getEventById(any())).thenAnswer((_) async => null);
    when(() => userRepo.getUser(any())).thenAnswer((_) async => null);

    sl
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<AuthRedirectNotifier>(auth);
    registerPush();

    final invited = fakeBooking(
      id: 'inv-book',
      eventId: 'ev-inv',
      creativeId: 'creative-1',
      plannerId: 'planner-1',
      status: BookingStatus.invited,
    );
    final event = fakeEvent(id: 'ev-inv', title: 'Invite Gig');
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    final seeded = BookingsState(
      loading: false,
      invited: [invited],
      events: {invited.eventId: event},
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Invitations'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verify(
      () => bookingRepo.updateBookingStatus('inv-book', BookingStatus.accepted),
    ).called(1);
    verify(() => cubit.load()).called(1);
  });

  testWidgets('invited booking Decline updates status and reloads', (
    tester,
  ) async {
    final collabRepo = MockCollaborationRepository();
    final bookingRepo = MockBookingRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    when(
      () => collabRepo.getCollaborationsByTargetUserId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getInvitedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getPendingBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getAcceptedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getCompletedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.updateBookingStatus(any(), any()),
    ).thenAnswer((_) async {});

    when(() => eventRepo.getEventById(any())).thenAnswer((_) async => null);
    when(() => userRepo.getUser(any())).thenAnswer((_) async => null);

    sl
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<AuthRedirectNotifier>(auth);
    registerPush();

    final invited = fakeBooking(
      id: 'inv-book-d',
      eventId: 'ev-inv-d',
      creativeId: 'creative-1',
      plannerId: 'planner-1',
      status: BookingStatus.invited,
    );
    final event = fakeEvent(id: 'ev-inv-d', title: 'Decline Gig');
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    final seeded = BookingsState(
      loading: false,
      invited: [invited],
      events: {invited.eventId: event},
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Invitations'), findsOneWidget);

    await tester.tap(find.text('Decline'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verify(
      () => bookingRepo.updateBookingStatus('inv-book-d', BookingStatus.declined),
    ).called(1);
    verify(() => cubit.load()).called(1);
  });

  testWidgets('accepted gig tap navigates to event detail', (tester) async {
    registerBookingsSlForCreative();

    final acc = fakeBooking(
      id: 'acc-book',
      eventId: 'ev-acc',
      creativeId: 'creative-1',
      status: BookingStatus.accepted,
    );
    final event = fakeEvent(id: 'ev-acc', title: 'AccGig');
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    final seeded = BookingsState(
      loading: false,
      accepted: [acc],
      events: {acc.eventId: event},
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: seeded,
    );

    final router = GoRouter(
      initialLocation: AppRoutes.bookings,
      routes: [
        GoRoute(
          path: AppRoutes.bookings,
          builder: (context, state) => BookingsPage(bookingsCubit: cubit),
        ),
        GoRoute(
          path: '/event/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Detail:${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('AccGig'));
    await tester.pumpAndSettle();

    expect(find.text('Detail:ev-acc'), findsOneWidget);
  });

  testWidgets('completed gig Confirm calls confirmCompletionByCreative', (
    tester,
  ) async {
    final collabRepo = MockCollaborationRepository();
    final bookingRepo = MockBookingRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    when(
      () => collabRepo.getCollaborationsByTargetUserId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getInvitedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getPendingBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getAcceptedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getCompletedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.confirmCompletionByCreative(any()),
    ).thenAnswer((_) async {});

    when(() => eventRepo.getEventById(any())).thenAnswer((_) async => null);
    when(() => userRepo.getUser(any())).thenAnswer((_) async => null);

    sl
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<AuthRedirectNotifier>(auth);
    registerPush();

    final completed = BookingEntity(
      id: 'cmp-book',
      eventId: 'ev-cmp',
      creativeId: 'creative-1',
      plannerId: 'planner-1',
      status: BookingStatus.completed,
      creativeConfirmedAt: null,
    );
    final ev = fakeEvent(id: 'ev-cmp', title: 'Past Gig');
    final cubit = MockBookingsCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.setConfirmingBookingId(any())).thenReturn(null);
    when(() => cubit.clearConfirmingBookingId()).thenReturn(null);
    final seeded = BookingsState(
      loading: false,
      completed: [completed],
      events: {completed.eventId: ev},
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<BookingsState>(
      cubit,
      const Stream<BookingsState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingsPage(bookingsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Past'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verify(() => bookingRepo.confirmCompletionByCreative('cmp-book')).called(1);
    verify(() => cubit.load()).called(1);
  });
}
