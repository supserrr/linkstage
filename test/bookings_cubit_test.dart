import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/bookings/bookings_cubit.dart';
import 'package:linkstage/presentation/bloc/bookings/bookings_state.dart';
import 'package:mocktail/mocktail.dart';

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  void registerBookingsSl({required UserEntity? currentUser}) {
    final collabRepo = MockCollaborationRepository();
    final bookingRepo = MockBookingRepository();
    final eventRepo = MockEventRepository();
    final userRepo = MockUserRepository();
    final auth = MockAuthRedirectNotifier();

    when(() => auth.user).thenReturn(currentUser);

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

    sl.registerSingleton<CollaborationRepository>(collabRepo);
    sl.registerSingleton<BookingRepository>(bookingRepo);
    sl.registerSingleton<EventRepository>(eventRepo);
    sl.registerSingleton<UserRepository>(userRepo);
    sl.registerSingleton<AuthRedirectNotifier>(auth);
  }

  group('BookingsCubit', () {
    blocTest<BookingsCubit, BookingsState>(
      'load sets loading false when user is not a creative',
      build: () {
        registerBookingsSl(
          currentUser: const UserEntity(
            id: 'u1',
            email: 'planner@test.com',
            role: UserRole.eventPlanner,
          ),
        );
        return BookingsCubit()..load();
      },
      wait: const Duration(milliseconds: 20),
      verify: (c) {
        expect(c.state.loading, isFalse);
        expect(c.state.error, isNull);
        expect(c.state.invited, isEmpty);
      },
    );

    blocTest<BookingsCubit, BookingsState>(
      'load sets loading false when user is null',
      build: () {
        registerBookingsSl(currentUser: null);
        return BookingsCubit()..load();
      },
      wait: const Duration(milliseconds: 20),
      verify: (c) {
        expect(c.state.loading, isFalse);
      },
    );

    blocTest<BookingsCubit, BookingsState>(
      'load completes for creative with empty lists',
      build: () {
        registerBookingsSl(
          currentUser: const UserEntity(
            id: 'creative-1',
            email: 'c@test.com',
            role: UserRole.creativeProfessional,
          ),
        );
        return BookingsCubit()..load();
      },
      wait: const Duration(milliseconds: 50),
      verify: (c) {
        expect(c.state.loading, isFalse);
        expect(c.state.error, isNull);
        expect(c.state.invited, isEmpty);
        expect(c.state.collaborations, isEmpty);
      },
    );

    blocTest<BookingsCubit, BookingsState>(
      'setConfirmingBookingId and clearConfirmingBookingId',
      build: () {
        registerBookingsSl(
          currentUser: const UserEntity(
            id: 'creative-1',
            email: 'c@test.com',
            role: UserRole.creativeProfessional,
          ),
        );
        return BookingsCubit()..load();
      },
      wait: const Duration(milliseconds: 50),
      act: (c) => c
        ..setConfirmingBookingId('b-done')
        ..clearConfirmingBookingId(),
      verify: (c) {
        expect(c.state.confirmingBookingId, isNull);
      },
    );
  });
}
