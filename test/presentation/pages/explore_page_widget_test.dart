import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/l10n/app_localizations.dart';
import 'package:linkstage/presentation/pages/explore_page.dart';
import 'package:linkstage/presentation/widgets/molecules/connection_error_overlay.dart';
import 'package:linkstage/presentation/widgets/molecules/empty_state_dotted.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/presentation/bloc/profiles/profiles_bloc.dart';
import 'package:linkstage/presentation/bloc/profiles/profiles_state.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

class MockCreativeExploreCubit extends MockCubit<CreativeExploreUiState>
    implements CreativeExploreCubit {}

class MockProfilesBloc extends MockBloc<ProfilesEvent, ProfilesState>
    implements ProfilesBloc {}

class _FakeProfilesEvent extends Fake implements ProfilesEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeProfilesEvent());
  });

  late MockAuthRedirectNotifier auth;
  late MockAuthRepository authRepo;
  late MockProfileRepository profileRepo;
  late MockEventRepository eventRepo;
  late MockBookingRepository bookingRepo;
  late MockPlannerProfileRepository plannerProfileRepo;
  late MockCreativeExploreCubit creativeExploreCubit;
  late MockProfilesBloc profilesBloc;

  setUp(() async {
    auth = MockAuthRedirectNotifier();
    authRepo = MockAuthRepository();
    profileRepo = MockProfileRepository();
    eventRepo = MockEventRepository();
    bookingRepo = MockBookingRepository();
    plannerProfileRepo = MockPlannerProfileRepository();
    creativeExploreCubit = MockCreativeExploreCubit();
    profilesBloc = MockProfilesBloc();

    await sl.reset();

    when(() => authRepo.currentUser).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<UserEntity?>.empty());

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    when(
      () => profileRepo.getProfiles(
        category: any(named: 'category'),
        location: any(named: 'location'),
        excludeUserId: any(named: 'excludeUserId'),
        onlyCreativeAccounts: any(named: 'onlyCreativeAccounts'),
      ),
    ).thenAnswer((_) => Stream.value(const []));

    when(
      () => profileRepo.getProfileByUserId(any()),
    ).thenAnswer((_) async => null);

    when(
      () => eventRepo.fetchDiscoverableEvents(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const []);

    when(
      () => bookingRepo.getAcceptedBookingsByCreativeId(any()),
    ).thenAnswer((_) async => const []);

    when(
      () => plannerProfileRepo.getPlannerProfiles(
        limit: any(named: 'limit'),
        excludeUserId: any(named: 'excludeUserId'),
      ),
    ).thenAnswer((_) async => []);

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<PlannerProfileRepository>(plannerProfileRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('ExplorePage builds for creative user', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExplorePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ExplorePage), findsOneWidget);
    expect(find.text('Events'), findsWidgets);
  });

  testWidgets('ExplorePage builds for event planner unified tabs', (
    tester,
  ) async {
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExplorePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ExplorePage), findsOneWidget);
    expect(find.text('Creatives'), findsWidgets);
    expect(find.text('Event Planners'), findsWidgets);
  });

  testWidgets('ExplorePage shows event skeletons while loading', (
    tester,
  ) async {
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    whenListen<CreativeExploreUiState>(
      creativeExploreCubit,
      const Stream<CreativeExploreUiState>.empty(),
      initialState: const CreativeExploreUiState(eventsLoading: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExplorePage(creativeExploreCubit: creativeExploreCubit),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ExploreEventCardSkeleton), findsWidgets);
  });

  testWidgets('ExplorePage shows error overlay when event load fails', (
    tester,
  ) async {
    whenListen<CreativeExploreUiState>(
      creativeExploreCubit,
      const Stream<CreativeExploreUiState>.empty(),
      initialState: const CreativeExploreUiState(
        eventsLoading: false,
        eventsError: 'timeout',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExplorePage(creativeExploreCubit: creativeExploreCubit),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ConnectionErrorOverlay), findsWidgets);
  });

  testWidgets('ExplorePage shows empty state when no upcoming events', (
    tester,
  ) async {
    whenListen<CreativeExploreUiState>(
      creativeExploreCubit,
      const Stream<CreativeExploreUiState>.empty(),
      initialState: const CreativeExploreUiState(
        eventsLoading: false,
        events: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExplorePage(creativeExploreCubit: creativeExploreCubit),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(EmptyStateDotted), findsOneWidget);
    expect(find.text('No upcoming events'), findsOneWidget);
  });

  testWidgets('ExplorePage renders event list when populated', (tester) async {
    final event = EventEntity(
      id: 'ev-1',
      plannerId: 'pl-1',
      title: 'Gig',
      eventType: 'Wedding',
    );

    whenListen<CreativeExploreUiState>(
      creativeExploreCubit,
      const Stream<CreativeExploreUiState>.empty(),
      initialState: CreativeExploreUiState(
        eventsLoading: false,
        events: [event],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExplorePage(creativeExploreCubit: creativeExploreCubit),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Gig'), findsOneWidget);
  });

  testWidgets('Creatives tab shows VendorCard and tapping navigates', (
    tester,
  ) async {
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    // Force creatives tab.
    whenListen<CreativeExploreUiState>(
      creativeExploreCubit,
      const Stream<CreativeExploreUiState>.empty(),
      initialState: const CreativeExploreUiState(tab: ExploreTab.creatives),
    );

    final profiles = [
      const ProfileEntity(
        id: 'p1',
        userId: 'other-1',
        displayName: 'Other',
        location: 'Kigali',
        priceRange: '100000',
      ),
    ];
    when(() => profilesBloc.state).thenReturn(ProfilesState.loaded(profiles));
    whenListen<ProfilesState>(
      profilesBloc,
      const Stream<ProfilesState>.empty(),
      initialState: ProfilesState.loaded(profiles),
    );

    final router = GoRouter(
      initialLocation: '/explore',
      routes: [
        GoRoute(
          path: '/explore',
          builder: (context, state) => ExplorePage(
            creativeExploreCubit: creativeExploreCubit,
            profilesBloc: profilesBloc,
          ),
        ),
        GoRoute(
          path: '/view/creative/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Profile view')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Other'), findsOneWidget);

    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();

    expect(find.text('Profile view'), findsOneWidget);
  });

  testWidgets('Planner explore creatives shows skeletons while profiles load', (
    tester,
  ) async {
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );

    when(() => profilesBloc.state).thenReturn(const ProfilesState.loading());
    whenListen<ProfilesState>(
      profilesBloc,
      const Stream<ProfilesState>.empty(),
      initialState: const ProfilesState.loading(),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExplorePage(
          unifiedExploreCubit: UnifiedExploreCubit('planner-1'),
          profilesBloc: profilesBloc,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(VendorCardSkeleton), findsWidgets);
  });

  testWidgets(
    'Planner explore creatives shows "No matches" when search has no results',
    (tester) async {
      when(() => auth.user).thenReturn(
        const UserEntity(
          id: 'planner-1',
          email: 'p@test.com',
          role: UserRole.eventPlanner,
        ),
      );

      final seeded = ProfilesState.loaded(const [], searchQuery: 'zzz');
      when(() => profilesBloc.state).thenReturn(seeded);
      whenListen<ProfilesState>(
        profilesBloc,
        const Stream<ProfilesState>.empty(),
        initialState: seeded,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplorePage(
            unifiedExploreCubit: UnifiedExploreCubit('planner-1'),
            profilesBloc: profilesBloc,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('No matches for "zzz"'), findsOneWidget);
    },
  );

  testWidgets(
    'Planner explore search debounces and dispatches ProfilesSearchQueryChanged',
    (tester) async {
      when(() => auth.user).thenReturn(
        const UserEntity(
          id: 'planner-1',
          email: 'p@test.com',
          role: UserRole.eventPlanner,
        ),
      );

      final seeded = ProfilesState.loaded(const []);
      when(() => profilesBloc.state).thenReturn(seeded);
      whenListen<ProfilesState>(
        profilesBloc,
        const Stream<ProfilesState>.empty(),
        initialState: seeded,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplorePage(
            unifiedExploreCubit: UnifiedExploreCubit('planner-1'),
            profilesBloc: profilesBloc,
          ),
        ),
      );
      await tester.pump();

      // Search field is part of the unified explore (planner) view.
      await tester.enterText(find.byType(TextField).first, 'abc');

      await tester.pump(const Duration(milliseconds: 299));
      verifyNever(
        () => profilesBloc.add(any(that: isA<ProfilesSearchQueryChanged>())),
      );

      await tester.pump(const Duration(milliseconds: 5));
      verify(
        () => profilesBloc.add(
          any(
            that: isA<ProfilesSearchQueryChanged>().having(
              (e) => e.query,
              'query',
              'abc',
            ),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'Planner segmented control switches to Event Planners and triggers loadPlanners',
    (tester) async {
      when(() => auth.user).thenReturn(
        const UserEntity(
          id: 'planner-1',
          email: 'p@test.com',
          role: UserRole.eventPlanner,
        ),
      );

      final seeded = ProfilesState.loaded(const []);
      when(() => profilesBloc.state).thenReturn(seeded);
      whenListen<ProfilesState>(
        profilesBloc,
        const Stream<ProfilesState>.empty(),
        initialState: seeded,
      );

      when(
        () => plannerProfileRepo.getPlannerProfiles(
          limit: any(named: 'limit'),
          excludeUserId: any(named: 'excludeUserId'),
        ),
      ).thenAnswer((_) async => const []);

      final unified = UnifiedExploreCubit('planner-1');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplorePage(
            unifiedExploreCubit: unified,
            profilesBloc: profilesBloc,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Event Planners'));
      await tester.pump(const Duration(seconds: 1));

      verify(
        () => plannerProfileRepo.getPlannerProfiles(
          limit: 50,
          excludeUserId: 'planner-1',
        ),
      ).called(1);
    },
  );

  testWidgets('Events tab event card tap navigates to event detail', (
    tester,
  ) async {
    final event = EventEntity(
      id: 'ev-tap-nav',
      plannerId: 'pl-1',
      title: 'TapEvGig',
      eventType: 'Wedding',
    );

    whenListen<CreativeExploreUiState>(
      creativeExploreCubit,
      const Stream<CreativeExploreUiState>.empty(),
      initialState: CreativeExploreUiState(
        eventsLoading: false,
        events: [event],
      ),
    );

    final router = GoRouter(
      initialLocation: '/explore',
      routes: [
        GoRoute(
          path: '/explore',
          builder: (context, state) =>
              ExplorePage(creativeExploreCubit: creativeExploreCubit),
        ),
        GoRoute(
          path: '/event/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Detail:${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('TapEvGig'));
    await tester.pumpAndSettle();

    expect(find.text('Detail:ev-tap-nav'), findsOneWidget);
  });

  testWidgets('Creative explore taps Wedding event type filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExplorePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Wedding'));
    await tester.pump();
  });

  testWidgets('Planner unified explore opens filter sheet and applies', (
    tester,
  ) async {
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );

    final seeded = ProfilesState.loaded(const []);
    when(() => profilesBloc.state).thenReturn(seeded);
    whenListen<ProfilesState>(
      profilesBloc,
      const Stream<ProfilesState>.empty(),
      initialState: seeded,
    );

    when(
      () => plannerProfileRepo.getPlannerProfiles(
        limit: any(named: 'limit'),
        excludeUserId: any(named: 'excludeUserId'),
      ),
    ).thenAnswer((_) async => const []);

    final unified = UnifiedExploreCubit('planner-1');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExplorePage(
          unifiedExploreCubit: unified,
          profilesBloc: profilesBloc,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
  });
}
