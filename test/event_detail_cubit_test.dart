import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/event_detail/event_detail_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

void main() {
  const eventId = 'evt-detail-1';
  final testEvent = EventEntity(
    id: eventId,
    plannerId: 'planner-1',
    title: 'Summer Gala',
    description: 'Evening event',
    status: EventStatus.open,
    date: DateTime.now().add(const Duration(days: 7)),
  );

  late MockEventRepository eventRepo;
  late MockBookingRepository bookingRepo;
  late MockUserRepository userRepo;
  late MockPlannerProfileRepository plannerProfileRepo;

  setUp(() {
    eventRepo = MockEventRepository();
    bookingRepo = MockBookingRepository();
    userRepo = MockUserRepository();
    plannerProfileRepo = MockPlannerProfileRepository();

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
        displayName: 'Planner Pat',
      ),
    );
    when(
      () => plannerProfileRepo.getPlannerProfile(testEvent.plannerId),
    ).thenAnswer(
      (_) async => const PlannerProfileEntity(userId: 'planner-1', bio: ''),
    );
  });

  test('load emits event and planner data for planner viewer', () async {
    final cubit = EventDetailCubit(
      eventRepo,
      bookingRepo,
      userRepo,
      plannerProfileRepo,
      eventId,
      'planner-1',
      false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.isLoading, false);
    expect(cubit.state.error, isNull);
    expect(cubit.state.event?.title, 'Summer Gala');
    expect(cubit.state.planner?.displayName, 'Planner Pat');
    await cubit.close();
  });

  test(
    'load sets hasApplied for creative when pending booking exists',
    () async {
      when(
        () => bookingRepo.hasPendingBookingForEvent(eventId, 'creative-1'),
      ).thenAnswer((_) async => true);
      when(
        () => bookingRepo.getAcceptedBookingsByEventId(eventId),
      ).thenAnswer((_) async => []);

      final cubit = EventDetailCubit(
        eventRepo,
        bookingRepo,
        userRepo,
        plannerProfileRepo,
        eventId,
        'creative-1',
        true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.hasApplied, true);
      await cubit.close();
    },
  );

  test('load sets error when event missing', () async {
    when(() => eventRepo.getEventById(eventId)).thenAnswer((_) async => null);
    final cubit = EventDetailCubit(
      eventRepo,
      bookingRepo,
      userRepo,
      plannerProfileRepo,
      eventId,
      'planner-1',
      false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.isLoading, false);
    expect(cubit.state.error, 'Event not found');
    await cubit.close();
  });

  test('load tolerates applicant photo user fetch failure', () async {
    when(
      () => bookingRepo.getPendingBookingsByEventId(eventId),
    ).thenAnswer(
      (_) async => [
        BookingEntity(
          id: 'bk-p',
          eventId: eventId,
          creativeId: 'cr-99',
          plannerId: testEvent.plannerId,
        ),
      ],
    );
    when(() => userRepo.getUser('cr-99')).thenThrow(Exception('no user'));

    final cubit = EventDetailCubit(
      eventRepo,
      bookingRepo,
      userRepo,
      plannerProfileRepo,
      eventId,
      'planner-1',
      false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.error, isNull);
    expect(cubit.state.applicantPhotoUrls.length, 1);
    expect(cubit.state.applicantPhotoUrls.first, isNull);
    await cubit.close();
  });

  test('load sets error when getEventById throws', () async {
    when(() => eventRepo.getEventById(eventId)).thenThrow(Exception('network'));
    final cubit = EventDetailCubit(
      eventRepo,
      bookingRepo,
      userRepo,
      plannerProfileRepo,
      eventId,
      'planner-1',
      false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.isLoading, false);
    expect(cubit.state.error, isNotNull);
    await cubit.close();
  });
}
