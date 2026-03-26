import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/planner_dashboard/planner_dashboard_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  const plannerId = 'planner-1';

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('PlannerDashboardCubit', () {
    late MockEventRepository eventRepo;
    late MockBookingRepository bookingRepo;
    late MockUserRepository userRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      eventRepo = MockEventRepository();
      bookingRepo = MockBookingRepository();
      userRepo = MockUserRepository();

      when(
        () => eventRepo.getEventsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(<EventEntity>[]));
      when(
        () => bookingRepo.watchPendingBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => bookingRepo.watchAcceptedInvitationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => bookingRepo.watchDeclinedInvitationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => bookingRepo.watchAcceptedApplicationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value([]));
    });

    test('load re-subscribes without throwing', () async {
      final cubit = PlannerDashboardCubit(
        eventRepo,
        bookingRepo,
        userRepo,
        prefs,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cubit.load();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.close();
    });

    test(
      'ends with loaded state and empty aggregates when streams emit empty',
      () async {
        final cubit = PlannerDashboardCubit(
          eventRepo,
          bookingRepo,
          userRepo,
          prefs,
          plannerId,
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect(cubit.state.isLoading, false);
        expect(cubit.state.events, isEmpty);
        expect(cubit.state.applicantsCount, 0);
        expect(cubit.state.eventsCount, 0);
        expect(cubit.state.recentActivities, isEmpty);
        expect(cubit.state.error, isNull);
        await cubit.close();
      },
    );

    test('refreshAfterAcknowledgements does not throw after load', () async {
      final cubit = PlannerDashboardCubit(
        eventRepo,
        bookingRepo,
        userRepo,
        prefs,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      cubit.refreshAfterAcknowledgements();
      expect(cubit.state.isLoading, false);
      await cubit.close();
    });

    test('emits error when events stream fails', () async {
      final eventsController = StreamController<List<EventEntity>>();
      final errEventRepo = MockEventRepository();
      final okBookingRepo = MockBookingRepository();
      final okUserRepo = MockUserRepository();
      when(
        () => errEventRepo.getEventsByPlannerId(any()),
      ).thenAnswer((_) => eventsController.stream);
      when(
        () => okBookingRepo.watchPendingBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));
      when(
        () => okBookingRepo.watchAcceptedInvitationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));
      when(
        () => okBookingRepo.watchDeclinedInvitationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));
      when(
        () => okBookingRepo.watchAcceptedApplicationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));

      final cubit = PlannerDashboardCubit(
        errEventRepo,
        okBookingRepo,
        okUserRepo,
        prefs,
        plannerId,
      );
      eventsController.addError(Exception('e'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.isLoading, false);
      await cubit.close();
      await eventsController.close();
    });

    test('emits error when pending bookings stream fails', () async {
      final pendingController = StreamController<List<BookingEntity>>();
      final okEventRepo = MockEventRepository();
      final errBookingRepo = MockBookingRepository();
      final okUserRepo = MockUserRepository();
      when(
        () => okEventRepo.getEventsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(const <EventEntity>[]));
      when(
        () => errBookingRepo.watchPendingBookingsByPlannerId(any()),
      ).thenAnswer((_) => pendingController.stream);
      when(
        () => errBookingRepo.watchAcceptedInvitationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));
      when(
        () => errBookingRepo.watchDeclinedInvitationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));
      when(
        () => errBookingRepo.watchAcceptedApplicationBookingsByPlannerId(any()),
      ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));

      final cubit = PlannerDashboardCubit(
        okEventRepo,
        errBookingRepo,
        okUserRepo,
        prefs,
        plannerId,
      );
      pendingController.addError(Exception('b'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.error, isNotNull);
      await cubit.close();
      await pendingController.close();
    });

    test(
      'builds recent activity for pending application on upcoming event',
      () async {
        const eventId = 'evt-1';
        final future = DateTime.now().add(const Duration(days: 7));
        final upcoming = EventEntity(
          id: eventId,
          plannerId: plannerId,
          title: 'Gala',
          date: future,
          status: EventStatus.open,
        );
        final pending = BookingEntity(
          id: 'bk-1',
          eventId: eventId,
          creativeId: 'cr-1',
          plannerId: plannerId,
          createdAt: DateTime.now(),
        );

        final evRepo = MockEventRepository();
        final bkRepo = MockBookingRepository();
        final uRepo = MockUserRepository();
        when(
          () => evRepo.getEventsByPlannerId(any()),
        ).thenAnswer((_) => Stream.value([upcoming]));
        when(
          () => bkRepo.watchPendingBookingsByPlannerId(any()),
        ).thenAnswer((_) => Stream.value([pending]));
        when(
          () => bkRepo.watchAcceptedInvitationBookingsByPlannerId(any()),
        ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));
        when(
          () => bkRepo.watchDeclinedInvitationBookingsByPlannerId(any()),
        ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));
        when(
          () => bkRepo.watchAcceptedApplicationBookingsByPlannerId(any()),
        ).thenAnswer((_) => Stream.value(const <BookingEntity>[]));
        when(() => uRepo.getUsersByIds(any())).thenAnswer(
          (_) async => {
            'cr-1': const UserEntity(
              id: 'cr-1',
              email: 'c@test.com',
              displayName: 'Creative',
            ),
          },
        );

        final cubit = PlannerDashboardCubit(
          evRepo,
          bkRepo,
          uRepo,
          prefs,
          plannerId,
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect(cubit.state.recentActivities, isNotEmpty);
        expect(cubit.state.recentActivities.first.eventTitle, 'Gala');
        await cubit.close();
      },
    );
  });
}
