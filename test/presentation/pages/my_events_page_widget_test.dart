import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/my_events/my_events_cubit.dart';
import 'package:linkstage/presentation/bloc/my_events/my_events_state.dart';
import 'package:linkstage/presentation/pages/my_events_page.dart';
import 'package:linkstage/presentation/widgets/molecules/empty_state_illustrated.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockMyEventsCubit extends MockCubit<MyEventsState>
    implements MyEventsCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MyEventsState());
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('MyEventsPage builds for planner with events tab', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    final eventRepo = MockEventRepository();
    final bookingRepo = MockBookingRepository();
    final collabRepo = MockCollaborationRepository();
    final userRepo = MockUserRepository();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );

    when(
      () => eventRepo.getEventsByPlannerId(any()),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => bookingRepo.watchPendingBookingsByPlannerId(any()),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => collabRepo.getCollaborationsByRequesterId(any()),
    ).thenAnswer((_) async => const []);
    when(() => userRepo.getUsersByIds(any())).thenAnswer((_) async => {});

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<UserRepository>(userRepo);

    await tester.pumpWidget(const MaterialApp(home: MyEventsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MyEventsPage), findsOneWidget);
    expect(find.text('Events'), findsWidgets);
  });

  testWidgets('MyEventsPage shows skeletons while loading', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockMyEventsCubit();
    when(() => cubit.state).thenReturn(const MyEventsState(isLoading: true));
    whenListen<MyEventsState>(
      cubit,
      const Stream<MyEventsState>.empty(),
      initialState: const MyEventsState(isLoading: true),
    );

    await tester.pumpWidget(
      MaterialApp(home: MyEventsPage(myEventsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(EventCardSkeleton), findsWidgets);
  });

  testWidgets('MyEventsPage shows empty state when no events', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockMyEventsCubit();
    when(
      () => cubit.state,
    ).thenReturn(const MyEventsState(events: [], isLoading: false));
    whenListen<MyEventsState>(
      cubit,
      const Stream<MyEventsState>.empty(),
      initialState: const MyEventsState(events: [], isLoading: false),
    );

    await tester.pumpWidget(
      MaterialApp(home: MyEventsPage(myEventsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(EmptyStateIllustrated), findsOneWidget);
    expect(
      find.textContaining('No events yet', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('MyEventsPage shows upcoming and past sections when populated', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final now = DateTime.now();
    final upcoming = EventEntity(
      id: 'ev-up',
      plannerId: 'planner-1',
      title: 'Upcoming',
      date: now.add(const Duration(days: 2)),
    );
    final past = EventEntity(
      id: 'ev-past',
      plannerId: 'planner-1',
      title: 'Past',
      date: now.subtract(const Duration(days: 2)),
    );

    final cubit = MockMyEventsCubit();
    final seeded = MyEventsState(events: [upcoming, past]);
    when(() => cubit.state).thenReturn(seeded);
    whenListen<MyEventsState>(
      cubit,
      const Stream<MyEventsState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(home: MyEventsPage(myEventsCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Upcoming'), findsWidgets);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -1000),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Past'), findsWidgets);
  });

  testWidgets('AppBar create event navigates to create route', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockMyEventsCubit();
    when(
      () => cubit.state,
    ).thenReturn(const MyEventsState(events: [], isLoading: false));
    whenListen<MyEventsState>(
      cubit,
      const Stream<MyEventsState>.empty(),
      initialState: const MyEventsState(events: [], isLoading: false),
    );

    final router = GoRouter(
      initialLocation: '/my-events',
      routes: [
        GoRoute(
          path: '/my-events',
          builder: (_, _) => MyEventsPage(myEventsCubit: cubit),
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

    await tester.tap(find.byTooltip('Create event'));
    await tester.pumpAndSettle();

    expect(find.text('CreateEventStub'), findsOneWidget);
  });

  testWidgets('empty state Create event navigates to create route', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockMyEventsCubit();
    when(
      () => cubit.state,
    ).thenReturn(const MyEventsState(events: [], isLoading: false));
    whenListen<MyEventsState>(
      cubit,
      const Stream<MyEventsState>.empty(),
      initialState: const MyEventsState(events: [], isLoading: false),
    );

    final router = GoRouter(
      initialLocation: '/my-events',
      routes: [
        GoRoute(
          path: '/my-events',
          builder: (_, _) => MyEventsPage(myEventsCubit: cubit),
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

    await tester.tap(find.text('Create event'));
    await tester.pumpAndSettle();

    expect(find.text('CreateEventStub'), findsOneWidget);
  });

  testWidgets('tapping event card navigates to event detail', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final now = DateTime.now();
    final upcoming = EventEntity(
      id: 'ev-nav',
      plannerId: 'planner-1',
      title: 'NavTarget',
      date: now.add(const Duration(days: 2)),
      status: EventStatus.open,
    );

    final cubit = MockMyEventsCubit();
    final seeded = MyEventsState(events: [upcoming]);
    when(() => cubit.state).thenReturn(seeded);
    whenListen<MyEventsState>(
      cubit,
      const Stream<MyEventsState>.empty(),
      initialState: seeded,
    );

    final router = GoRouter(
      initialLocation: '/my-events',
      routes: [
        GoRoute(
          path: '/my-events',
          builder: (_, _) => MyEventsPage(myEventsCubit: cubit),
        ),
        GoRoute(
          path: '/event/:id',
          builder: (_, state) =>
              Scaffold(body: Text('EventDetail:${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('NavTarget'));
    await tester.pumpAndSettle();

    expect(find.text('EventDetail:ev-nav'), findsOneWidget);
  });

  testWidgets('Collaborations tab Browse creatives navigates to explore', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    final collabRepo = MockCollaborationRepository();
    final userRepo = MockUserRepository();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    when(
      () => collabRepo.getCollaborationsByRequesterId(any()),
    ).thenAnswer((_) async => const []);
    when(() => userRepo.getUsersByIds(any())).thenAnswer((_) async => {});

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<UserRepository>(userRepo);

    final cubit = MockMyEventsCubit();
    when(
      () => cubit.state,
    ).thenReturn(const MyEventsState(events: [], isLoading: false));
    whenListen<MyEventsState>(
      cubit,
      const Stream<MyEventsState>.empty(),
      initialState: const MyEventsState(events: [], isLoading: false),
    );

    final router = GoRouter(
      initialLocation: '/my-events',
      routes: [
        GoRoute(
          path: '/my-events',
          builder: (_, _) => MyEventsPage(myEventsCubit: cubit),
        ),
        GoRoute(
          path: AppRoutes.explore,
          builder: (_, _) => const Scaffold(body: Text('ExploreStub')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Collaborations'));
    await tester.pumpAndSettle();

    expect(find.text('Browse creatives'), findsOneWidget);
    await tester.tap(find.text('Browse creatives'));
    await tester.pumpAndSettle();

    expect(find.text('ExploreStub'), findsOneWidget);
  });
}
