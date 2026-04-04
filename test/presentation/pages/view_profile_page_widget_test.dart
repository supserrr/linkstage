import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/review_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/followed_planners_repository.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/review_repository.dart';
import 'package:linkstage/domain/repositories/saved_creatives_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/creative_profile/creative_profile_cubit.dart';
import 'package:linkstage/presentation/bloc/creative_profile/creative_profile_state.dart';
import 'package:linkstage/presentation/bloc/planner_profile/planner_profile_cubit.dart';
import 'package:linkstage/presentation/bloc/planner_profile/planner_profile_state.dart';
import 'package:linkstage/presentation/pages/profile/view_profile_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

class MockFollowedPlannersRepository extends Mock
    implements FollowedPlannersRepository {}

class MockSavedCreativesRepository extends Mock
    implements SavedCreativesRepository {}

class MockCreativeProfileCubit extends MockCubit<CreativeProfileState>
    implements CreativeProfileCubit {}

class MockPlannerProfileCubit extends MockCubit<PlannerProfileState>
    implements PlannerProfileCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const CreativeProfileState());
    registerFallbackValue(const PlannerProfileState());
    registerFallbackValue(<String>[]);
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('ViewProfilePage builds viewing another creative profile', (
    tester,
  ) async {
    final profileRepo = MockProfileRepository();
    final reviewRepo = MockReviewRepository();
    final bookingRepo = MockBookingRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    when(() => profileRepo.getProfileByUserId('other-1')).thenAnswer(
      (_) async => const ProfileEntity(
        id: 'other-1',
        userId: 'other-1',
        displayName: 'Other',
      ),
    );
    when(() => userRepo.getUser('other-1')).thenAnswer(
      (_) async => const UserEntity(id: 'other-1', email: 'o@test.com'),
    );
    when(
      () => reviewRepo.getReviewsByRevieweeId('other-1'),
    ).thenAnswer((_) async => const []);
    when(
      () => bookingRepo.getCompletedBookingsByCreativeId('other-1'),
    ).thenAnswer((_) async => const []);

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<UserRepository>(userRepo);

    await tester.pumpWidget(
      const MaterialApp(home: ViewProfilePage(profileUserId: 'other-1')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ViewProfilePage), findsOneWidget);
  });

  testWidgets('builds planner profile when profileRole is event planner', (
    tester,
  ) async {
    final profileRepo = MockProfileRepository();
    final reviewRepo = MockReviewRepository();
    final bookingRepo = MockBookingRepository();
    final userRepo = MockUserRepository();
    final eventRepo = MockEventRepository();
    final collabRepo = MockCollaborationRepository();
    final plannerProfileRepo = MockPlannerProfileRepository();
    final followedRepo = MockFollowedPlannersRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    when(() => userRepo.getUser('planner-1')).thenAnswer(
      (_) async => const UserEntity(id: 'planner-1', email: 'p@test.com'),
    );
    when(() => plannerProfileRepo.getPlannerProfile('planner-1')).thenAnswer(
      (_) async =>
          const PlannerProfileEntity(userId: 'planner-1', displayName: 'Pat'),
    );
    when(
      () => eventRepo.fetchEventsByPlannerId('planner-1'),
    ).thenAnswer((_) async => const []);
    when(
      () => bookingRepo.getCompletedBookingsByPlannerId('planner-1'),
    ).thenAnswer((_) async => const []);
    when(
      () => bookingRepo.getAcceptedBookingsByCreativeId('viewer-1'),
    ).thenAnswer((_) async => const []);
    when(
      () => followedRepo.watchFollowedPlannerIds('viewer-1'),
    ).thenAnswer((_) => Stream.value(<String>{}));
    when(
      () => followedRepo.toggleFollow(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => collabRepo.getCollaborationsByTargetUserId(
        'planner-1',
        status: CollaborationStatus.completed,
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => collabRepo.getCollaborationsByRequesterId(
        'planner-1',
        status: CollaborationStatus.completed,
      ),
    ).thenAnswer((_) async => const []);

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<PlannerProfileRepository>(plannerProfileRepo)
      ..registerSingleton<FollowedPlannersRepository>(followedRepo);

    await tester.pumpWidget(
      const MaterialApp(
        home: ViewProfilePage(
          profileUserId: 'planner-1',
          profileRole: UserRole.eventPlanner,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(ViewProfilePage), findsOneWidget);
  });

  testWidgets('creative profile loading shows loader', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockCreativeProfileCubit();
    const seeded = CreativeProfileState(isLoading: true, profile: null);
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativeProfileState>(
      cubit,
      const Stream<CreativeProfileState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ViewProfilePage(
          profileUserId: 'other-1',
          creativeProfileCubit: cubit,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Loader branch: should not show "Profile not found" yet.
    expect(find.text('Profile not found'), findsNothing);
  });

  testWidgets('planner profile error shows Retry and calls refresh', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockPlannerProfileCubit();
    const seeded = PlannerProfileState(
      error: 'net',
      user: null,
      plannerProfile: null,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<PlannerProfileState>(
      cubit,
      const Stream<PlannerProfileState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.refresh()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: ViewProfilePage(
          profileUserId: 'planner-1',
          profileRole: UserRole.eventPlanner,
          plannerProfileCubit: cubit,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => cubit.refresh()).called(1);
  });

  testWidgets(
    'creative view profile shows favorite and tapping calls toggleSaved',
    (tester) async {
      final auth = MockAuthRedirectNotifier();
      when(() => auth.user).thenReturn(
        const UserEntity(
          id: 'viewer-1',
          email: 'v@test.com',
          role: UserRole.eventPlanner,
        ),
      );

      final authRepo = MockAuthRepository();
      when(() => authRepo.currentUser).thenReturn(null);

      final saved = MockSavedCreativesRepository();
      when(
        () => saved.watchSavedCreativeIds('viewer-1'),
      ).thenAnswer((_) => Stream.value(<String>{'other-1'}));
      when(
        () => saved.toggleSaved('viewer-1', 'other-1'),
      ).thenAnswer((_) async {});

      sl
        ..registerSingleton<AuthRedirectNotifier>(auth)
        ..registerSingleton<AuthRepository>(authRepo)
        ..registerSingleton<SavedCreativesRepository>(saved);

      final cubit = MockCreativeProfileCubit();
      const seeded = CreativeProfileState(
        isLoading: false,
        profile: ProfileEntity(
          id: 'other-1',
          userId: 'other-1',
          displayName: 'Other',
        ),
      );
      when(() => cubit.state).thenReturn(seeded);
      whenListen<CreativeProfileState>(
        cubit,
        const Stream<CreativeProfileState>.empty(),
        initialState: seeded,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ViewProfilePage(
            profileUserId: 'other-1',
            creativeProfileCubit: cubit,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => saved.toggleSaved('viewer-1', 'other-1')).called(1);
    },
  );

  testWidgets('planner view profile follow button calls toggleFollow', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    final followed = MockFollowedPlannersRepository();
    when(
      () => followed.watchFollowedPlannerIds('viewer-1'),
    ).thenAnswer((_) => Stream.value(<String>{}));
    when(
      () => followed.toggleFollow('viewer-1', 'planner-1'),
    ).thenAnswer((_) async {});

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<FollowedPlannersRepository>(followed);

    final cubit = MockPlannerProfileCubit();
    const seeded = PlannerProfileState(
      user: UserEntity(id: 'planner-1', email: 'p@test.com'),
      plannerProfile: PlannerProfileEntity(
        userId: 'planner-1',
        displayName: 'Pat',
      ),
      isLoading: false,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<PlannerProfileState>(
      cubit,
      const Stream<PlannerProfileState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ViewProfilePage(
          profileUserId: 'planner-1',
          profileRole: UserRole.eventPlanner,
          plannerProfileCubit: cubit,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final follow = find.widgetWithText(FilledButton, 'Follow');
    expect(follow, findsOneWidget);

    await tester.tap(follow);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => followed.toggleFollow('viewer-1', 'planner-1')).called(1);
  });

  testWidgets('creative view profile share button is tappable', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.eventPlanner,
      ),
    );

    final authRepo = MockAuthRepository();
    when(() => authRepo.currentUser).thenReturn(null);

    final saved = MockSavedCreativesRepository();
    when(
      () => saved.watchSavedCreativeIds('viewer-1'),
    ).thenAnswer((_) => Stream.value(<String>{}));

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<SavedCreativesRepository>(saved);

    final cubit = MockCreativeProfileCubit();
    const seeded = CreativeProfileState(
      isLoading: false,
      profile: ProfileEntity(
        id: 'other-1',
        userId: 'other-1',
        displayName: 'Other',
      ),
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativeProfileState>(
      cubit,
      const Stream<CreativeProfileState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ViewProfilePage(
          profileUserId: 'other-1',
          creativeProfileCubit: cubit,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
  });

  testWidgets('planner view profile Contact planner navigates to chat route', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    final followed = MockFollowedPlannersRepository();
    when(
      () => followed.watchFollowedPlannerIds('viewer-1'),
    ).thenAnswer((_) => Stream.value(<String>{}));

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<FollowedPlannersRepository>(followed);

    final cubit = MockPlannerProfileCubit();
    const seeded = PlannerProfileState(
      user: UserEntity(id: 'planner-1', email: 'p@test.com'),
      plannerProfile: PlannerProfileEntity(
        userId: 'planner-1',
        displayName: 'Pat',
      ),
      isLoading: false,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<PlannerProfileState>(
      cubit,
      const Stream<PlannerProfileState>.empty(),
      initialState: seeded,
    );

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => ViewProfilePage(
            profileUserId: 'planner-1',
            profileRole: UserRole.eventPlanner,
            plannerProfileCubit: cubit,
          ),
        ),
        GoRoute(
          path: '/messages/with/:id',
          builder: (context, state) => const Scaffold(body: Text('Chat')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.widgetWithText(FilledButton, 'Contact planner'));
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsOneWidget);
  });

  testWidgets('See more reviews navigates to profile reviews route', (
    tester,
  ) async {
    final profileRepo = MockProfileRepository();
    final reviewRepo = MockReviewRepository();
    final bookingRepo = MockBookingRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();
    final authRepo = MockAuthRepository();
    final saved = MockSavedCreativesRepository();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    when(() => authRepo.currentUser).thenReturn(null);
    when(
      () => saved.watchSavedCreativeIds('viewer-1'),
    ).thenAnswer((_) => Stream.value(<String>{}));

    when(() => profileRepo.getProfileByUserId('other-1')).thenAnswer(
      (_) async => const ProfileEntity(
        id: 'other-1',
        userId: 'other-1',
        displayName: 'Other',
      ),
    );
    when(() => userRepo.getUser('other-1')).thenAnswer(
      (_) async => const UserEntity(id: 'other-1', email: 'o@test.com'),
    );
    final reviews = [
      ReviewEntity(
        id: 'r1',
        reviewerId: 'rv1',
        revieweeId: 'other-1',
        rating: 5,
        comment: 'A',
      ),
      ReviewEntity(
        id: 'r2',
        reviewerId: 'rv2',
        revieweeId: 'other-1',
        rating: 5,
        comment: 'B',
      ),
      ReviewEntity(
        id: 'r3',
        reviewerId: 'rv3',
        revieweeId: 'other-1',
        rating: 5,
        comment: 'C',
      ),
    ];
    when(
      () => reviewRepo.getReviewsByRevieweeId('other-1'),
    ).thenAnswer((_) async => reviews);
    when(() => userRepo.getUsersByIds(any())).thenAnswer(
      (_) async => {
        'rv1': const UserEntity(id: 'rv1', email: 'a@test.com'),
        'rv2': const UserEntity(id: 'rv2', email: 'b@test.com'),
        'rv3': const UserEntity(id: 'rv3', email: 'c@test.com'),
      },
    );
    when(
      () => bookingRepo.getCompletedBookingsByCreativeId('other-1'),
    ).thenAnswer((_) async => const []);

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<SavedCreativesRepository>(saved)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<UserRepository>(userRepo);

    final router = GoRouter(
      initialLocation: '/vp',
      routes: [
        GoRoute(
          path: '/vp',
          builder: (context, state) =>
              const ViewProfilePage(profileUserId: 'other-1'),
        ),
        GoRoute(
          path: AppRoutes.profileReviews,
          builder: (context, state) => Scaffold(
            body: Text('Reviews:${state.uri.queryParameters['userId'] ?? ''}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Profile not found'), findsNothing);
    expect(find.text('Other'), findsOneWidget);
    verify(() => reviewRepo.getReviewsByRevieweeId('other-1')).called(1);
    expect(find.text('3 reviews'), findsOneWidget);

    final listFinder = find.ancestor(
      of: find.text('Other'),
      matching: find.byType(ListView),
    );
    await tester.drag(listFinder, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('See more reviews'), findsOneWidget);

    await tester.tap(find.text('See more reviews'));
    await tester.pumpAndSettle();

    expect(find.text('Reviews:other-1'), findsOneWidget);
  });

  testWidgets('Portfolio See All navigates to portfolio route', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.eventPlanner,
      ),
    );

    final authRepo = MockAuthRepository();
    when(() => authRepo.currentUser).thenReturn(null);

    final saved = MockSavedCreativesRepository();
    when(
      () => saved.watchSavedCreativeIds('viewer-1'),
    ).thenAnswer((_) => Stream.value(<String>{}));

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<SavedCreativesRepository>(saved);

    final cubit = MockCreativeProfileCubit();
    const profile = ProfileEntity(
      id: 'other-1',
      userId: 'other-1',
      displayName: 'Other',
      portfolioVideoUrls: ['vid'],
    );
    const seeded = CreativeProfileState(isLoading: false, profile: profile);
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativeProfileState>(
      cubit,
      const Stream<CreativeProfileState>.empty(),
      initialState: seeded,
    );

    final router = GoRouter(
      initialLocation: '/vp',
      routes: [
        GoRoute(
          path: '/vp',
          builder: (context, state) => ViewProfilePage(
            profileUserId: 'other-1',
            creativeProfileCubit: cubit,
          ),
        ),
        GoRoute(
          path: AppRoutes.profilePortfolio,
          builder: (context, state) => Scaffold(
            body: Text(
              'Portfolio:${state.uri.queryParameters['userId'] ?? ''}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('See All'), findsOneWidget);

    await tester.tap(find.text('See All'));
    await tester.pumpAndSettle();

    expect(find.text('Portfolio:other-1'), findsOneWidget);
  });

  testWidgets('Past work row navigates to creative past work route', (
    tester,
  ) async {
    final profileRepo = MockProfileRepository();
    final reviewRepo = MockReviewRepository();
    final bookingRepo = MockBookingRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();
    final authRepo = MockAuthRepository();
    final saved = MockSavedCreativesRepository();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'v@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    when(() => authRepo.currentUser).thenReturn(null);
    when(
      () => saved.watchSavedCreativeIds('viewer-1'),
    ).thenAnswer((_) => Stream.value(<String>{}));

    when(() => profileRepo.getProfileByUserId('other-1')).thenAnswer(
      (_) async => const ProfileEntity(
        id: 'other-1',
        userId: 'other-1',
        displayName: 'Other',
      ),
    );
    when(() => userRepo.getUser('other-1')).thenAnswer(
      (_) async => const UserEntity(id: 'other-1', email: 'o@test.com'),
    );
    when(
      () => reviewRepo.getReviewsByRevieweeId('other-1'),
    ).thenAnswer((_) async => const []);
    when(
      () => bookingRepo.getCompletedBookingsByCreativeId('other-1'),
    ).thenAnswer((_) async => const []);

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<SavedCreativesRepository>(saved)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<UserRepository>(userRepo);

    final router = GoRouter(
      initialLocation: '/vp',
      routes: [
        GoRoute(
          path: '/vp',
          builder: (context, state) =>
              const ViewProfilePage(profileUserId: 'other-1'),
        ),
        GoRoute(
          path: '/view/creative/:id/past-work',
          builder: (context, state) =>
              Scaffold(body: Text('PastWork:${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Profile not found'), findsNothing);
    expect(find.text('Other'), findsOneWidget);

    final listFinder = find.ancestor(
      of: find.text('Other'),
      matching: find.byType(ListView),
    );
    await tester.drag(listFinder, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('View past events and collaborations'), findsOneWidget);

    await tester.tap(find.text('View past events and collaborations'));
    await tester.pumpAndSettle();

    expect(find.text('PastWork:other-1'), findsOneWidget);
  });

  testWidgets('own profile shows loading when auth user is null', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(null);

    sl.registerSingleton<AuthRedirectNotifier>(auth);

    await tester.pumpWidget(
      const MaterialApp(home: ViewProfilePage()),
    );
    await tester.pump();

    expect(find.text('Profile'), findsNothing);
    expect(find.byType(Center), findsWidgets);
  });

  testWidgets(
    'own creative profile uses injected cubit and shows Profile app bar',
    (tester) async {
      final auth = MockAuthRedirectNotifier();
      when(() => auth.user).thenReturn(
        const UserEntity(
          id: 'me-1',
          email: 'me@test.com',
          role: UserRole.creativeProfessional,
        ),
      );

      final authRepo = MockAuthRepository();
      when(() => authRepo.currentUser).thenReturn(null);

      final saved = MockSavedCreativesRepository();
      when(
        () => saved.watchSavedCreativeIds('me-1'),
      ).thenAnswer((_) => Stream.value(<String>{}));

      sl
        ..registerSingleton<AuthRedirectNotifier>(auth)
        ..registerSingleton<AuthRepository>(authRepo)
        ..registerSingleton<SavedCreativesRepository>(saved);

      final cubit = MockCreativeProfileCubit();
      const seeded = CreativeProfileState(
        isLoading: false,
        profile: ProfileEntity(
          id: 'me-1',
          userId: 'me-1',
          displayName: 'Me',
        ),
      );
      when(() => cubit.state).thenReturn(seeded);
      whenListen<CreativeProfileState>(
        cubit,
        const Stream<CreativeProfileState>.empty(),
        initialState: seeded,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ViewProfilePage(creativeProfileCubit: cubit),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Me'), findsOneWidget);
    },
  );

  testWidgets(
    'own planner profile uses injected cubit and shows Profile app bar',
    (tester) async {
      final auth = MockAuthRedirectNotifier();
      when(() => auth.user).thenReturn(
        const UserEntity(
          id: 'me-pl',
          email: 'pl@test.com',
          role: UserRole.eventPlanner,
        ),
      );

      final eventRepo = MockEventRepository();
      final collabRepo = MockCollaborationRepository();
      final followed = MockFollowedPlannersRepository();

      when(
        () => eventRepo.fetchEventsByPlannerId('me-pl'),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          'me-pl',
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          'me-pl',
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => followed.watchFollowedPlannerIds('me-pl'),
      ).thenAnswer((_) => Stream.value(<String>{}));

      sl
        ..registerSingleton<AuthRedirectNotifier>(auth)
        ..registerSingleton<EventRepository>(eventRepo)
        ..registerSingleton<CollaborationRepository>(collabRepo)
        ..registerSingleton<FollowedPlannersRepository>(followed);

      final cubit = MockPlannerProfileCubit();
      const seeded = PlannerProfileState(
        isLoading: false,
        user: UserEntity(
          id: 'me-pl',
          email: 'pl@test.com',
          displayName: 'Planner Me',
        ),
        plannerProfile: PlannerProfileEntity(
          userId: 'me-pl',
          displayName: 'Planner Me',
        ),
      );
      when(() => cubit.state).thenReturn(seeded);
      whenListen<PlannerProfileState>(
        cubit,
        const Stream<PlannerProfileState>.empty(),
        initialState: seeded,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ViewProfilePage(plannerProfileCubit: cubit),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Planner Me'), findsOneWidget);
    },
  );
}
