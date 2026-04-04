import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:linkstage/core/constants/app_icons.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart'
    show CollaborationEntity, CollaborationStatus;
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/followed_planners_repository.dart';
import 'package:linkstage/domain/repositories/notification_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/saved_creatives_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/creative_dashboard/creative_dashboard_cubit.dart';
import 'package:linkstage/presentation/bloc/creative_dashboard/creative_dashboard_state.dart';
import 'package:linkstage/presentation/bloc/planner_dashboard/planner_dashboard_cubit.dart';
import 'package:linkstage/presentation/bloc/planner_dashboard/planner_dashboard_state.dart';
import 'package:linkstage/presentation/bloc/unread_notifications/unread_notifications_cubit.dart';
import 'package:linkstage/presentation/bloc/unread_notifications/unread_notifications_state.dart';
import 'package:linkstage/presentation/widgets/organisms/creative_dashboard_content.dart';
import 'package:linkstage/presentation/widgets/organisms/planner_dashboard_content.dart';
import 'package:linkstage/presentation/widgets/molecules/connection_error_overlay.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockSavedCreativesRepository extends Mock
    implements SavedCreativesRepository {}

class MockFollowedPlannersRepository extends Mock
    implements FollowedPlannersRepository {}

class MockCreativeDashboardCubit extends MockCubit<CreativeDashboardState>
    implements CreativeDashboardCubit {}

class MockPlannerDashboardCubit extends MockCubit<PlannerDashboardState>
    implements PlannerDashboardCubit {}

class MockUnreadNotificationsCubit extends MockCubit<UnreadNotificationsState>
    implements UnreadNotificationsCubit {}

void main() {
  const plannerId = 'planner-w';
  const creativeId = 'creative-w';

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(UserRole.eventPlanner);
    registerFallbackValue(CollaborationStatus.pending);
    registerFallbackValue(const CreativeDashboardState());
    registerFallbackValue(const PlannerDashboardState());
    registerFallbackValue(const UnreadNotificationsState());
  });

  group('PlannerDashboardContent', () {
    late MockEventRepository eventRepo;
    late MockBookingRepository bookingRepo;
    late MockUserRepository userRepo;
    late MockNotificationRepository notifRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      eventRepo = MockEventRepository();
      bookingRepo = MockBookingRepository();
      userRepo = MockUserRepository();
      notifRepo = MockNotificationRepository();

      when(
        () => eventRepo.getEventsByPlannerId(plannerId),
      ).thenAnswer((_) => Stream.value(<EventEntity>[]));
      when(
        () => bookingRepo.watchPendingBookingsByPlannerId(plannerId),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => bookingRepo.watchAcceptedInvitationBookingsByPlannerId(plannerId),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => bookingRepo.watchDeclinedInvitationBookingsByPlannerId(plannerId),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () =>
            bookingRepo.watchAcceptedApplicationBookingsByPlannerId(plannerId),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => notifRepo.watchNotifications(plannerId, UserRole.eventPlanner),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => notifRepo.watchReadNotificationIds(plannerId),
      ).thenAnswer((_) => Stream.value(<String>{}));
    });

    testWidgets('shows greeting and Post a Gig after streams settle', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => UnreadNotificationsCubit(
                      notifRepo,
                      plannerId,
                      UserRole.eventPlanner,
                    ),
                  ),
                  BlocProvider(
                    create: (_) => PlannerDashboardCubit(
                      eventRepo,
                      bookingRepo,
                      userRepo,
                      prefs,
                      plannerId,
                    ),
                  ),
                ],
                child: const PlannerDashboardContent(displayName: 'Alex'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Hello, Alex'), findsOneWidget);
      expect(find.text('Post a Gig'), findsOneWidget);
    });

    testWidgets('shows skeleton while loading', (tester) async {
      final plannerCubit = MockPlannerDashboardCubit();
      const seeded = PlannerDashboardState(isLoading: true);
      when(() => plannerCubit.state).thenReturn(seeded);
      whenListen<PlannerDashboardState>(
        plannerCubit,
        const Stream<PlannerDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<PlannerDashboardCubit>.value(value: plannerCubit),
                BlocProvider<UnreadNotificationsCubit>.value(
                  value: unreadCubit,
                ),
              ],
              child: const PlannerDashboardContent(displayName: 'Alex'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PlannerDashboardSkeleton), findsOneWidget);
    });

    testWidgets('shows error overlay when error is set', (tester) async {
      final plannerCubit = MockPlannerDashboardCubit();
      const seeded = PlannerDashboardState(isLoading: false, error: 'net');
      when(() => plannerCubit.state).thenReturn(seeded);
      whenListen<PlannerDashboardState>(
        plannerCubit,
        const Stream<PlannerDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<PlannerDashboardCubit>.value(value: plannerCubit),
                BlocProvider<UnreadNotificationsCubit>.value(
                  value: unreadCubit,
                ),
              ],
              child: const PlannerDashboardContent(displayName: 'Alex'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ConnectionErrorOverlay), findsOneWidget);
    });

    testWidgets('Post a Gig navigates to create event route', (tester) async {
      final plannerCubit = MockPlannerDashboardCubit();
      const seeded = PlannerDashboardState(isLoading: false);
      when(() => plannerCubit.state).thenReturn(seeded);
      when(() => plannerCubit.refreshAfterAcknowledgements()).thenReturn(null);
      whenListen<PlannerDashboardState>(
        plannerCubit,
        const Stream<PlannerDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<PlannerDashboardCubit>.value(
                    value: plannerCubit,
                  ),
                  BlocProvider<UnreadNotificationsCubit>.value(
                    value: unreadCubit,
                  ),
                ],
                child: const PlannerDashboardContent(displayName: 'Alex'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.createEvent,
            builder: (_, _) => const Scaffold(body: Text('CreateEventStub')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Post a Gig'));
      await tester.pumpAndSettle();

      expect(find.text('CreateEventStub'), findsOneWidget);
    });

    testWidgets('notification bell navigates to notifications route', (
      tester,
    ) async {
      final plannerCubit = MockPlannerDashboardCubit();
      const seeded = PlannerDashboardState(isLoading: false);
      when(() => plannerCubit.state).thenReturn(seeded);
      when(() => plannerCubit.refreshAfterAcknowledgements()).thenReturn(null);
      whenListen<PlannerDashboardState>(
        plannerCubit,
        const Stream<PlannerDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<PlannerDashboardCubit>.value(
                    value: plannerCubit,
                  ),
                  BlocProvider<UnreadNotificationsCubit>.value(
                    value: unreadCubit,
                  ),
                ],
                child: const PlannerDashboardContent(displayName: 'Alex'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, _) => const Scaffold(body: Text('NotificationsStub')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final notifInk = find.ancestor(
        of: find.byIcon(AppIcons.notifications),
        matching: find.byType(InkWell),
      );
      await tester.tap(notifInk.first);
      await tester.pumpAndSettle();

      expect(find.text('NotificationsStub'), findsOneWidget);
    });

    testWidgets('Your active events View All navigates to bookings', (
      tester,
    ) async {
      final plannerCubit = MockPlannerDashboardCubit();
      const seeded = PlannerDashboardState(isLoading: false);
      when(() => plannerCubit.state).thenReturn(seeded);
      when(() => plannerCubit.refreshAfterAcknowledgements()).thenReturn(null);
      whenListen<PlannerDashboardState>(
        plannerCubit,
        const Stream<PlannerDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<PlannerDashboardCubit>.value(
                    value: plannerCubit,
                  ),
                  BlocProvider<UnreadNotificationsCubit>.value(
                    value: unreadCubit,
                  ),
                ],
                child: const PlannerDashboardContent(displayName: 'Alex'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.bookings,
            builder: (_, _) => const Scaffold(body: Text('BookingsStub')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(find.text('BookingsStub'), findsOneWidget);
    });

    testWidgets('tapping open event card navigates to event detail', (
      tester,
    ) async {
      final openEvent = EventEntity(
        id: 'ev-open',
        plannerId: plannerId,
        title: 'Gig',
        date: DateTime.now().add(const Duration(days: 4)),
        status: EventStatus.open,
      );
      final plannerCubit = MockPlannerDashboardCubit();
      final seeded = PlannerDashboardState(
        isLoading: false,
        events: [openEvent],
      );
      when(() => plannerCubit.state).thenReturn(seeded);
      when(() => plannerCubit.refreshAfterAcknowledgements()).thenReturn(null);
      whenListen<PlannerDashboardState>(
        plannerCubit,
        const Stream<PlannerDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<PlannerDashboardCubit>.value(
                    value: plannerCubit,
                  ),
                  BlocProvider<UnreadNotificationsCubit>.value(
                    value: unreadCubit,
                  ),
                ],
                child: const PlannerDashboardContent(displayName: 'Alex'),
              ),
            ),
          ),
          GoRoute(
            path: '/event/:id',
            builder: (_, state) => Scaffold(
              body: Text('EventDetail:${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.ensureVisible(find.text('Gig'));
      await tester.pump();
      await tester.tap(find.text('Gig'));
      await tester.pumpAndSettle();

      expect(find.text('EventDetail:ev-open'), findsOneWidget);
    });
  });

  group('CreativeDashboardContent', () {
    late MockProfileRepository profileRepo;
    late MockEventRepository eventRepo;
    late MockBookingRepository bookingRepo;
    late MockCollaborationRepository collabRepo;
    late MockSavedCreativesRepository savedCreativesRepo;
    late MockFollowedPlannersRepository followedRepo;
    late MockNotificationRepository notifRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      profileRepo = MockProfileRepository();
      eventRepo = MockEventRepository();
      bookingRepo = MockBookingRepository();
      collabRepo = MockCollaborationRepository();
      savedCreativesRepo = MockSavedCreativesRepository();
      followedRepo = MockFollowedPlannersRepository();
      notifRepo = MockNotificationRepository();

      when(() => profileRepo.getProfileByUserId(creativeId)).thenAnswer(
        (_) async => const ProfileEntity(id: 'p1', userId: creativeId),
      );
      when(
        () => eventRepo.fetchOpenEvents(limit: 20),
      ).thenAnswer((_) async => []);
      when(
        () => followedRepo.watchFollowedPlannerIds(creativeId),
      ).thenAnswer((_) => Stream.value(<String>{}));
      when(
        () => bookingRepo.getPendingBookingsByCreativeId(creativeId),
      ).thenAnswer((_) async => []);
      when(
        () => bookingRepo.getAcceptedBookingsByCreativeId(creativeId),
      ).thenAnswer((_) async => []);
      when(
        () => bookingRepo.getInvitedBookingsByCreativeId(creativeId),
      ).thenAnswer((_) async => []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          creativeId,
          status: CollaborationStatus.pending,
        ),
      ).thenAnswer((_) async => <CollaborationEntity>[]);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(creativeId),
      ).thenAnswer((_) async => []);
      when(
        () => savedCreativesRepo.watchSavedCreativeIds(creativeId),
      ).thenAnswer((_) => Stream.value(<String>{}));
      when(
        () => savedCreativesRepo.getSavedProfiles(creativeId),
      ).thenAnswer((_) async => <ProfileEntity>[]);
      when(
        () => profileRepo.getProfiles(
          limit: 20,
          excludeUserId: creativeId,
          onlyCreativeAccounts: true,
        ),
      ).thenAnswer((_) => Stream.value(<ProfileEntity>[]));
      when(
        () => bookingRepo.getPendingBookingsCountByEventIds([]),
      ).thenAnswer((_) async => <String, int>{});
      when(
        () => notifRepo.watchNotifications(
          creativeId,
          UserRole.creativeProfessional,
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => notifRepo.watchReadNotificationIds(creativeId),
      ).thenAnswer((_) => Stream.value(<String>{}));
    });

    testWidgets('shows Hello greeting after load', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => UnreadNotificationsCubit(
                      notifRepo,
                      creativeId,
                      UserRole.creativeProfessional,
                    ),
                  ),
                  BlocProvider(
                    create: (_) => CreativeDashboardCubit(
                      profileRepo,
                      eventRepo,
                      bookingRepo,
                      collabRepo,
                      savedCreativesRepo,
                      followedRepo,
                      prefs,
                      creativeId,
                    ),
                  ),
                ],
                child: const CreativeDashboardContent(displayName: 'Rita'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Hello, Rita'), findsOneWidget);
    });

    testWidgets('shows skeleton while loading', (tester) async {
      final creativeCubit = MockCreativeDashboardCubit();
      const seeded = CreativeDashboardState(isLoading: true);
      when(() => creativeCubit.state).thenReturn(seeded);
      whenListen<CreativeDashboardState>(
        creativeCubit,
        const Stream<CreativeDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<CreativeDashboardCubit>.value(
                  value: creativeCubit,
                ),
                BlocProvider<UnreadNotificationsCubit>.value(
                  value: unreadCubit,
                ),
              ],
              child: const CreativeDashboardContent(displayName: 'Rita'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CreativeDashboardSkeleton), findsOneWidget);
    });

    testWidgets('shows error UI and tapping Retry calls load', (tester) async {
      final creativeCubit = MockCreativeDashboardCubit();
      const seeded = CreativeDashboardState(isLoading: false, error: 'net');
      when(() => creativeCubit.state).thenReturn(seeded);
      whenListen<CreativeDashboardState>(
        creativeCubit,
        const Stream<CreativeDashboardState>.empty(),
        initialState: seeded,
      );
      when(() => creativeCubit.load()).thenAnswer((_) async {});

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<CreativeDashboardCubit>.value(
                  value: creativeCubit,
                ),
                BlocProvider<UnreadNotificationsCubit>.value(
                  value: unreadCubit,
                ),
              ],
              child: const CreativeDashboardContent(displayName: 'Rita'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ConnectionErrorOverlay), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => creativeCubit.load()).called(1);
    });

    testWidgets(
      'empty dashboard navigates via Find Gigs / Following / Explore',
      (tester) async {
        final creativeCubit = MockCreativeDashboardCubit();
        const seeded = CreativeDashboardState(
          isLoading: false,
          profile: ProfileEntity(
            id: 'p1',
            userId: creativeId,
            displayName: 'Rita',
          ),
          openEvents: [],
          savedEventIds: {},
          acceptedEventIds: {},
        );
        when(() => creativeCubit.state).thenReturn(seeded);
        whenListen<CreativeDashboardState>(
          creativeCubit,
          const Stream<CreativeDashboardState>.empty(),
          initialState: seeded,
        );

        final unreadCubit = MockUnreadNotificationsCubit();
        const unreadSeeded = UnreadNotificationsState(unreadCount: 2);
        when(() => unreadCubit.state).thenReturn(unreadSeeded);
        whenListen<UnreadNotificationsState>(
          unreadCubit,
          const Stream<UnreadNotificationsState>.empty(),
          initialState: unreadSeeded,
        );

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: MultiBlocProvider(
                  providers: [
                    BlocProvider<CreativeDashboardCubit>.value(
                      value: creativeCubit,
                    ),
                    BlocProvider<UnreadNotificationsCubit>.value(
                      value: unreadCubit,
                    ),
                  ],
                  child: const CreativeDashboardContent(displayName: 'Rita'),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.explore,
              builder: (context, state) =>
                  const Scaffold(body: Text('Explore')),
            ),
            GoRoute(
              path: AppRoutes.following,
              builder: (context, state) =>
                  const Scaffold(body: Text('Following')),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('No open events right now'), findsOneWidget);

        await tester.tap(find.text('Find Gigs'));
        await tester.pumpAndSettle();
        expect(find.text('Explore'), findsOneWidget);

        router.go('/');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Following'));
        await tester.pumpAndSettle();
        expect(find.text('Following'), findsOneWidget);

        router.go('/');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Explore'));
        await tester.pumpAndSettle();
        expect(find.text('Explore'), findsOneWidget);
      },
    );

    testWidgets('tapping notification icon navigates to Notifications', (
      tester,
    ) async {
      final creativeCubit = MockCreativeDashboardCubit();
      const seeded = CreativeDashboardState(
        isLoading: false,
        profile: ProfileEntity(
          id: 'p1',
          userId: creativeId,
          displayName: 'Rita',
        ),
      );
      when(() => creativeCubit.state).thenReturn(seeded);
      whenListen<CreativeDashboardState>(
        creativeCubit,
        const Stream<CreativeDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      const unreadSeeded = UnreadNotificationsState(unreadCount: 3);
      when(() => unreadCubit.state).thenReturn(unreadSeeded);
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: unreadSeeded,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<CreativeDashboardCubit>.value(
                    value: creativeCubit,
                  ),
                  BlocProvider<UnreadNotificationsCubit>.value(
                    value: unreadCubit,
                  ),
                ],
                child: const CreativeDashboardContent(displayName: 'Rita'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) =>
                const Scaffold(body: Text('Notifications')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final notifInk = find.ancestor(
        of: find.byIcon(AppIcons.notifications),
        matching: find.byType(InkWell),
      );
      await tester.tap(notifInk.first);
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('recent events save tap calls cubit.toggleSavedEvent', (
      tester,
    ) async {
      final creativeCubit = MockCreativeDashboardCubit();
      when(
        () => creativeCubit.toggleSavedEvent(any()),
      ).thenAnswer((_) async {});

      final event = EventEntity(id: 'e1', plannerId: plannerId, title: 'Gig 1');
      final seeded = CreativeDashboardState(
        isLoading: false,
        profile: const ProfileEntity(
          id: 'p1',
          userId: creativeId,
          displayName: 'Rita',
        ),
        openEvents: [event],
        pendingCountByEventId: const {'e1': 2},
        savedEventIds: const {},
      );
      when(() => creativeCubit.state).thenReturn(seeded);
      whenListen<CreativeDashboardState>(
        creativeCubit,
        const Stream<CreativeDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<CreativeDashboardCubit>.value(
                  value: creativeCubit,
                ),
                BlocProvider<UnreadNotificationsCubit>.value(
                  value: unreadCubit,
                ),
              ],
              child: const CreativeDashboardContent(displayName: 'Rita'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final saveIcon = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == AppIcons.savedOutline && w.size == 18,
      );
      final saveInk = find.ancestor(
        of: saveIcon,
        matching: find.byType(InkWell),
      );
      await tester.tap(saveInk.first);
      await tester.pump();

      verify(() => creativeCubit.toggleSavedEvent('e1')).called(1);
    });

    testWidgets('saved events tile unsave calls cubit.toggleSavedEvent', (
      tester,
    ) async {
      final creativeCubit = MockCreativeDashboardCubit();
      when(
        () => creativeCubit.toggleSavedEvent(any()),
      ).thenAnswer((_) async {});

      final savedEvent = EventEntity(
        id: 'e1',
        plannerId: plannerId,
        title: 'Gig 1',
      );
      final seeded = CreativeDashboardState(
        isLoading: false,
        profile: const ProfileEntity(
          id: 'p1',
          userId: creativeId,
          displayName: 'Rita',
        ),
        savedEventIds: const {'e1'},
        openEvents: [savedEvent],
      );
      when(() => creativeCubit.state).thenReturn(seeded);
      whenListen<CreativeDashboardState>(
        creativeCubit,
        const Stream<CreativeDashboardState>.empty(),
        initialState: seeded,
      );

      final unreadCubit = MockUnreadNotificationsCubit();
      when(
        () => unreadCubit.state,
      ).thenReturn(const UnreadNotificationsState());
      whenListen<UnreadNotificationsState>(
        unreadCubit,
        const Stream<UnreadNotificationsState>.empty(),
        initialState: const UnreadNotificationsState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<CreativeDashboardCubit>.value(
                  value: creativeCubit,
                ),
                BlocProvider<UnreadNotificationsCubit>.value(
                  value: unreadCubit,
                ),
              ],
              child: const CreativeDashboardContent(displayName: 'Rita'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Saved events'), findsOneWidget);

      final remove = find.byTooltip('Remove from saved');
      await tester.ensureVisible(remove);
      await tester.pump();
      await tester.tap(remove);
      await tester.pump();

      verify(() => creativeCubit.toggleSavedEvent('e1')).called(1);
    });
  });
}
