import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/followed_planners_repository.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/pages/event_detail_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

class MockFollowedPlannersRepository extends Mock
    implements FollowedPlannersRepository {}

void main() {
  const eventId = 'evt-widget-1';

  final testEvent = EventEntity(
    id: eventId,
    plannerId: 'planner-1',
    title: 'Widget Gala',
    description: 'Details here',
    status: EventStatus.open,
    date: DateTime.now().add(const Duration(days: 14)),
  );

  late MockAuthRedirectNotifier authRedirect;
  late MockEventRepository eventRepo;
  late MockBookingRepository bookingRepo;
  late MockUserRepository userRepo;
  late MockPlannerProfileRepository plannerProfileRepo;
  late MockFollowedPlannersRepository followedRepo;

  setUp(() async {
    authRedirect = MockAuthRedirectNotifier();
    eventRepo = MockEventRepository();
    bookingRepo = MockBookingRepository();
    userRepo = MockUserRepository();
    plannerProfileRepo = MockPlannerProfileRepository();
    followedRepo = MockFollowedPlannersRepository();

    await sl.reset();
    sl
      ..registerLazySingleton<AuthRedirectNotifier>(() => authRedirect)
      ..registerLazySingleton<EventRepository>(() => eventRepo)
      ..registerLazySingleton<BookingRepository>(() => bookingRepo)
      ..registerLazySingleton<UserRepository>(() => userRepo)
      ..registerLazySingleton<PlannerProfileRepository>(
        () => plannerProfileRepo,
      )
      ..registerLazySingleton<FollowedPlannersRepository>(() => followedRepo);

    when(
      () => followedRepo.watchFollowedPlannerIds('planner-1'),
    ).thenAnswer((_) => Stream.value(<String>{}));
    when(
      () => followedRepo.toggleFollow(any(), any()),
    ).thenAnswer((_) async {});

    when(() => authRedirect.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    when(
      () => eventRepo.getEventById(eventId),
    ).thenAnswer((_) async => testEvent);
    when(
      () => bookingRepo.getPendingBookingsCountByEventId(eventId),
    ).thenAnswer((_) async => 0);
    when(
      () => bookingRepo.getPendingBookingsByEventId(eventId),
    ).thenAnswer((_) async => []);
    when(() => userRepo.getUser(testEvent.plannerId)).thenAnswer(
      (_) async => const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        displayName: 'Pat',
      ),
    );
    when(
      () => plannerProfileRepo.getPlannerProfile(testEvent.plannerId),
    ).thenAnswer(
      (_) async => const PlannerProfileEntity(userId: 'planner-1', bio: ''),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows event title after load', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EventDetailPage(eventId: eventId)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Widget Gala'), findsOneWidget);
  });
}
