import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/review_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/event_applicants/event_applicants_cubit.dart';
import 'package:linkstage/presentation/bloc/event_applicants/event_applicants_state.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

void main() {
  const eventId = 'evt-1';
  final testEvent = EventEntity(
    id: eventId,
    plannerId: 'planner-1',
    title: 'Summer Fest',
  );
  final pendingBooking = BookingEntity(
    id: 'book-1',
    eventId: eventId,
    creativeId: 'creative-1',
    plannerId: 'planner-1',
    status: BookingStatus.pending,
  );
  final creativeUser = UserEntity(
    id: 'creative-1',
    email: 'c@test.com',
    displayName: 'Artist',
  );

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  void registerApplicantsSl({
    required EventEntity? event,
    List<BookingEntity> invited = const [],
    List<BookingEntity> pending = const [],
    List<BookingEntity> accepted = const [],
    List<BookingEntity> completed = const [],
    Map<String, UserEntity> usersByCreativeId = const {},
  }) {
    final eventRepo = MockEventRepository();
    final bookingRepo = MockBookingRepository();
    final userRepo = MockUserRepository();
    final reviewRepo = MockReviewRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => eventRepo.getEventById(any())).thenAnswer((_) async => event);
    when(
      () => bookingRepo.getInvitedBookingsByEventId(any()),
    ).thenAnswer((_) async => invited);
    when(
      () => bookingRepo.getPendingBookingsByEventId(any()),
    ).thenAnswer((_) async => pending);
    when(
      () => bookingRepo.getAcceptedBookingsByEventId(any()),
    ).thenAnswer((_) async => accepted);
    when(
      () => bookingRepo.getCompletedBookingsByEventId(any()),
    ).thenAnswer((_) async => completed);

    when(() => userRepo.getUser(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments[0] as String;
      return usersByCreativeId[id];
    });

    when(
      () => reviewRepo.getReviewByBookingAndReviewer(any(), any()),
    ).thenAnswer((_) async => null);

    when(
      () => auth.user,
    ).thenReturn(const UserEntity(id: 'planner-1', email: 'p@test.com'));

    sl.registerSingleton<EventRepository>(eventRepo);
    sl.registerSingleton<BookingRepository>(bookingRepo);
    sl.registerSingleton<UserRepository>(userRepo);
    sl.registerSingleton<ReviewRepository>(reviewRepo);
    sl.registerSingleton<AuthRedirectNotifier>(auth);
  }

  group('EventApplicantsCubit', () {
    blocTest<EventApplicantsCubit, EventApplicantsState>(
      'load finishes with event and merged applicants',
      build: () {
        registerApplicantsSl(
          event: testEvent,
          pending: [pendingBooking],
          usersByCreativeId: {'creative-1': creativeUser},
        );
        return EventApplicantsCubit(eventId);
      },
      wait: const Duration(milliseconds: 50),
      verify: (c) {
        expect(c.state.loading, isFalse);
        expect(c.state.error, isNull);
        expect(c.state.event?.title, 'Summer Fest');
        expect(c.state.applicants, hasLength(1));
        expect(c.state.applicants.single.id, 'book-1');
        expect(c.state.creativeUsers['creative-1']?.displayName, 'Artist');
      },
    );

    blocTest<EventApplicantsCubit, EventApplicantsState>(
      'load sets error when event missing',
      build: () {
        registerApplicantsSl(event: null);
        return EventApplicantsCubit(eventId);
      },
      wait: const Duration(milliseconds: 50),
      verify: (c) {
        expect(c.state.loading, isFalse);
        expect(c.state.error, 'Event not found');
        expect(c.state.applicants, isEmpty);
      },
    );

    blocTest<EventApplicantsCubit, EventApplicantsState>(
      'setAcceptingBookingId and clearAcceptingBookingId',
      build: () {
        registerApplicantsSl(event: null);
        return EventApplicantsCubit(eventId);
      },
      wait: const Duration(milliseconds: 50),
      act: (c) => c
        ..setAcceptingBookingId('book-1')
        ..clearAcceptingBookingId(),
      verify: (c) {
        expect(c.state.acceptingBookingId, isNull);
      },
    );

    blocTest<EventApplicantsCubit, EventApplicantsState>(
      'markReviewedForBooking sets flag',
      build: () {
        registerApplicantsSl(event: null);
        return EventApplicantsCubit(eventId);
      },
      wait: const Duration(milliseconds: 50),
      act: (c) => c.markReviewedForBooking('book-99'),
      verify: (c) {
        expect(c.state.hasReviewedByBookingId['book-99'], isTrue);
      },
    );
  });
}
