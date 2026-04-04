import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
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
import 'package:linkstage/presentation/pages/home_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

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

void main() {
  const plannerId = 'home-planner';
  const creativeId = 'home-creative';

  late MockAuthRedirectNotifier auth;
  late MockEventRepository eventRepo;
  late MockBookingRepository bookingRepo;
  late MockUserRepository userRepo;
  late MockNotificationRepository notifRepo;
  late MockProfileRepository profileRepo;
  late MockCollaborationRepository collabRepo;
  late MockSavedCreativesRepository savedCreativesRepo;
  late MockFollowedPlannersRepository followedRepo;
  late SharedPreferences prefs;

  setUp(() async {
    auth = MockAuthRedirectNotifier();
    eventRepo = MockEventRepository();
    bookingRepo = MockBookingRepository();
    userRepo = MockUserRepository();
    notifRepo = MockNotificationRepository();
    profileRepo = MockProfileRepository();
    collabRepo = MockCollaborationRepository();
    savedCreativesRepo = MockSavedCreativesRepository();
    followedRepo = MockFollowedPlannersRepository();

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

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

    await sl.reset();
    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<NotificationRepository>(notifRepo)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<SavedCreativesRepository>(savedCreativesRepo)
      ..registerSingleton<FollowedPlannersRepository>(followedRepo)
      ..registerSingleton<SharedPreferences>(prefs);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('HomePage shows planner dashboard when user is planner', (
    tester,
  ) async {
    when(() => auth.isAuthenticated).thenReturn(true);
    when(() => auth.isReady).thenReturn(true);
    when(() => auth.needsRoleSelection).thenReturn(false);
    when(() => auth.needsProfileSetup).thenReturn(false);
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: plannerId,
        email: 'p@test.com',
        role: UserRole.eventPlanner,
        displayName: 'Pat',
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Hello, Pat'), findsOneWidget);
    expect(find.text('Post a Gig'), findsOneWidget);
  });

  testWidgets('HomePage shows creative dashboard when user is creative', (
    tester,
  ) async {
    when(() => auth.isAuthenticated).thenReturn(true);
    when(() => auth.isReady).thenReturn(true);
    when(() => auth.needsRoleSelection).thenReturn(false);
    when(() => auth.needsProfileSetup).thenReturn(false);
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: creativeId,
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
        displayName: 'Chris',
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Hello, Chris'), findsOneWidget);
  });

  testWidgets('HomePage shows loading when authenticated but auth not ready', (
    tester,
  ) async {
    when(() => auth.isAuthenticated).thenReturn(true);
    when(() => auth.isReady).thenReturn(false);
    when(() => auth.user).thenReturn(null);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();

    expect(find.byType(SafeArea), findsNothing);
    expect(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Center),
      ),
      findsWidgets,
    );
  });

  testWidgets('HomePage navigates to role selection when needsRoleSelection', (
    tester,
  ) async {
    when(() => auth.isAuthenticated).thenReturn(true);
    when(() => auth.isReady).thenReturn(true);
    when(() => auth.needsRoleSelection).thenReturn(true);
    when(() => auth.needsProfileSetup).thenReturn(false);
    when(() => auth.user).thenReturn(
      const UserEntity(id: 'u1', email: 'u@test.com', role: null),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.roleSelection,
          builder: (_, state) => const Scaffold(body: Text('RoleSelection')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RoleSelection'), findsOneWidget);
  });
}
