import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/services/push_notification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/review_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/review_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/event_applicants/event_applicants_cubit.dart';
import 'package:linkstage/presentation/bloc/event_applicants/event_applicants_state.dart';
import 'package:linkstage/presentation/pages/event_applicants_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/entity_fixtures.dart';
import 'package:linkstage/core/router/auth_redirect.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockEventApplicantsCubit extends MockCubit<EventApplicantsState>
    implements EventApplicantsCubit {}

void main() {
  const eventId = 'evt-widget-1';

  setUpAll(() {
    registerFallbackValue(const EventApplicantsState(eventId: eventId));
    registerFallbackValue(BookingStatus.pending);
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows Applications title when event loads', (tester) async {
    final eventRepo = MockEventRepository();
    final bookingRepo = MockBookingRepository();
    final userRepo = MockUserRepository();
    final reviewRepo = MockReviewRepository();
    final push = MockPushNotificationService();

    when(() => eventRepo.getEventById(eventId)).thenAnswer(
      (_) async =>
          EventEntity(id: eventId, plannerId: 'planner-1', title: 'Gala'),
    );
    when(
      () => bookingRepo.getInvitedBookingsByEventId(eventId),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getPendingBookingsByEventId(eventId),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getAcceptedBookingsByEventId(eventId),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getCompletedBookingsByEventId(eventId),
    ).thenAnswer((_) async => []);
    when(
      () => reviewRepo.getReviewByBookingAndReviewer(any(), any()),
    ).thenAnswer((_) async => null);
    when(
      () => push.syncAcceptedEventId(
        creativeId: any(named: 'creativeId'),
        eventId: any(named: 'eventId'),
        add: any(named: 'add'),
      ),
    ).thenAnswer((_) async {});

    sl
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<PushNotificationService>(push);

    await tester.pumpWidget(
      const MaterialApp(home: EventApplicantsPage(eventId: eventId)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Applications'), findsOneWidget);
  });

  testWidgets('shows error and Retry when load fails', (tester) async {
    final eventRepo = MockEventRepository();
    final bookingRepo = MockBookingRepository();
    final userRepo = MockUserRepository();
    final reviewRepo = MockReviewRepository();
    final push = MockPushNotificationService();

    when(() => eventRepo.getEventById(eventId)).thenThrow(Exception('net'));
    when(
      () => bookingRepo.getInvitedBookingsByEventId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getPendingBookingsByEventId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getAcceptedBookingsByEventId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => bookingRepo.getCompletedBookingsByEventId(any()),
    ).thenAnswer((_) async => []);
    when(() => userRepo.getUser(any())).thenAnswer((_) async => null);
    when(
      () => reviewRepo.getReviewByBookingAndReviewer(any(), any()),
    ).thenAnswer((_) async => null);
    sl
      ..registerSingleton<EventRepository>(eventRepo)
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<PushNotificationService>(push);

    await tester.pumpWidget(
      const MaterialApp(home: EventApplicantsPage(eventId: eventId)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows empty state when no applications', (tester) async {
    final cubit = MockEventApplicantsCubit();
    final seeded = EventApplicantsState(
      eventId: eventId,
      event: fakeEvent(id: eventId, title: 'Gala'),
      applicants: const [],
      creativeUsers: const {},
      loading: false,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<EventApplicantsState>(
      cubit,
      const Stream<EventApplicantsState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.load()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: EventApplicantsPage(
          eventId: eventId,
          eventApplicantsCubit: cubit,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('No applications yet', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('tapping Accept updates booking status', (tester) async {
    final bookingRepo = MockBookingRepository();
    final push = MockPushNotificationService();

    when(
      () => bookingRepo.updateBookingStatus(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => push.syncAcceptedEventId(
        creativeId: any(named: 'creativeId'),
        eventId: any(named: 'eventId'),
        add: any(named: 'add'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => push.notifyUser(
        targetUserId: any(named: 'targetUserId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    sl
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<PushNotificationService>(push);

    final cubit = MockEventApplicantsCubit();
    final booking = fakeBooking(
      id: 'b-1',
      eventId: eventId,
      creativeId: 'creative-1',
      plannerId: 'planner-1',
    );
    final seeded = EventApplicantsState(
      eventId: eventId,
      event: fakeEvent(id: eventId, title: 'Gala'),
      applicants: [booking],
      creativeUsers: {
        'creative-1': const UserEntity(id: 'creative-1', email: 'c1@test.com'),
      },
      loading: false,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<EventApplicantsState>(
      cubit,
      const Stream<EventApplicantsState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.setAcceptingBookingId(any())).thenReturn(null);
    when(() => cubit.clearAcceptingBookingId()).thenReturn(null);
    when(() => cubit.load()).thenAnswer((_) async {});

    final router = GoRouter(
      initialLocation: '/applicants',
      routes: [
        GoRoute(
          path: '/applicants',
          builder: (context, state) => EventApplicantsPage(
            eventId: eventId,
            eventApplicantsCubit: cubit,
          ),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const Scaffold(body: Text('Messages')),
        ),
        GoRoute(
          path: '/messages/with/:id',
          builder: (context, state) => const Scaffold(body: Text('Chat')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verify(
      () => bookingRepo.updateBookingStatus('b-1', BookingStatus.accepted),
    ).called(1);
  });

  testWidgets('tapping Reject declines booking and notifies creative', (
    tester,
  ) async {
    final bookingRepo = MockBookingRepository();
    final push = MockPushNotificationService();

    when(
      () => bookingRepo.updateBookingStatus(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => push.syncAcceptedEventId(
        creativeId: any(named: 'creativeId'),
        eventId: any(named: 'eventId'),
        add: any(named: 'add'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => push.notifyUser(
        targetUserId: any(named: 'targetUserId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    sl
      ..registerSingleton<BookingRepository>(bookingRepo)
      ..registerSingleton<PushNotificationService>(push);

    final cubit = MockEventApplicantsCubit();
    final booking = fakeBooking(
      id: 'b-2',
      eventId: eventId,
      creativeId: 'creative-2',
      plannerId: 'planner-1',
      status: BookingStatus.pending,
    );
    final seeded = EventApplicantsState(
      eventId: eventId,
      event: fakeEvent(id: eventId, title: 'Gala'),
      applicants: [booking],
      creativeUsers: {
        'creative-2': const UserEntity(id: 'creative-2', email: 'c2@test.com'),
      },
      loading: false,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<EventApplicantsState>(
      cubit,
      const Stream<EventApplicantsState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.setRejectingBookingId(any())).thenReturn(null);
    when(() => cubit.clearRejectingBookingId()).thenReturn(null);
    when(() => cubit.load()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: EventApplicantsPage(
          eventId: eventId,
          eventApplicantsCubit: cubit,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Reject'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(
      () => bookingRepo.updateBookingStatus('b-2', BookingStatus.declined),
    ).called(1);
    verify(
      () => push.notifyUser(
        targetUserId: 'creative-2',
        title: 'Application declined',
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).called(1);
  });

  testWidgets('tapping Complete confirms and marks booking completed', (
    tester,
  ) async {
    final bookingRepo = MockBookingRepository();
    when(
      () => bookingRepo.updateBookingStatus(any(), any()),
    ).thenAnswer((_) async {});
    sl.registerSingleton<BookingRepository>(bookingRepo);

    final cubit = MockEventApplicantsCubit();
    final booking = fakeBooking(
      id: 'b-3',
      eventId: eventId,
      creativeId: 'creative-3',
      plannerId: 'planner-1',
      status: BookingStatus.accepted,
    );
    final seeded = EventApplicantsState(
      eventId: eventId,
      event: fakeEvent(id: eventId, title: 'Gala'),
      applicants: [booking],
      creativeUsers: {
        'creative-3': const UserEntity(id: 'creative-3', email: 'c3@test.com'),
      },
      loading: false,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<EventApplicantsState>(
      cubit,
      const Stream<EventApplicantsState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.setCompletingBookingId(any())).thenReturn(null);
    when(() => cubit.clearCompletingBookingId()).thenReturn(null);
    when(() => cubit.load()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: EventApplicantsPage(
          eventId: eventId,
          eventApplicantsCubit: cubit,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();

    expect(find.text('Mark as complete'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Complete'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(
      () => bookingRepo.updateBookingStatus('b-3', BookingStatus.completed),
    ).called(1);
  });

  testWidgets(
    'completed booking: leaving a review calls ReviewRepository.createReview',
    (tester) async {
      final reviewRepo = MockReviewRepository();
      when(
        () => reviewRepo.createReview(
          bookingId: any(named: 'bookingId'),
          reviewerId: any(named: 'reviewerId'),
          revieweeId: any(named: 'revieweeId'),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer(
        (_) async => const ReviewEntity(
          id: 'r1',
          bookingId: 'b-4',
          reviewerId: 'planner-1',
          revieweeId: 'creative-4',
          rating: 4,
          comment: 'Great work',
        ),
      );

      final auth = MockAuthRedirectNotifier();
      when(() => auth.user).thenReturn(
        const UserEntity(
          id: 'planner-1',
          email: 'p@test.com',
          role: UserRole.eventPlanner,
        ),
      );

      sl
        ..registerSingleton<ReviewRepository>(reviewRepo)
        ..registerSingleton<AuthRedirectNotifier>(auth);

      final cubit = MockEventApplicantsCubit();
      final booking = fakeBooking(
        id: 'b-4',
        eventId: eventId,
        creativeId: 'creative-4',
        plannerId: 'planner-1',
        status: BookingStatus.completed,
      );
      final seeded = EventApplicantsState(
        eventId: eventId,
        event: fakeEvent(id: eventId, title: 'Gala'),
        applicants: [booking],
        creativeUsers: {
          'creative-4': const UserEntity(
            id: 'creative-4',
            email: 'c4@test.com',
          ),
        },
        hasReviewedByBookingId: const {},
        loading: false,
      );
      when(() => cubit.state).thenReturn(seeded);
      whenListen<EventApplicantsState>(
        cubit,
        const Stream<EventApplicantsState>.empty(),
        initialState: seeded,
      );
      when(() => cubit.markReviewedForBooking(any())).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: EventApplicantsPage(
            eventId: eventId,
            eventApplicantsCubit: cubit,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Leave review'));
      await tester.pumpAndSettle();

      expect(find.text('Leave a review'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.star).at(3)); // 4 stars
      await tester.pump();

      await tester.enterText(find.byType(TextField).last, 'Great work');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(
        () => reviewRepo.createReview(
          bookingId: 'b-4',
          reviewerId: 'planner-1',
          revieweeId: 'creative-4',
          rating: 4,
          comment: 'Great work',
        ),
      ).called(1);
      verify(() => cubit.markReviewedForBooking('b-4')).called(1);
    },
  );
}
