import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/presentation/bloc/create_event/create_event_cubit.dart';
import 'package:linkstage/presentation/pages/create_event_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  group('CreateEventPage', () {
    late MockAuthRedirectNotifier authRedirect;
    late MockEventRepository eventRepository;
    late MockBookingRepository bookingRepository;

    setUp(() async {
      authRedirect = MockAuthRedirectNotifier();
      eventRepository = MockEventRepository();
      bookingRepository = MockBookingRepository();

      await sl.reset();
      sl
        ..registerLazySingleton<AuthRedirectNotifier>(() => authRedirect)
        ..registerLazySingleton<EventRepository>(() => eventRepository)
        ..registerLazySingleton<BookingRepository>(() => bookingRepository);

      when(
        () => authRedirect.user,
      ).thenReturn(const UserEntity(id: 'p1', email: 'p1@test.com'));
    });

    testWidgets('renders form and toggles Save/Publish label', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CreateEventPage()));
      await tester.pumpAndSettle();

      expect(find.text('Create Event'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Event Type'), findsOneWidget);

      await tester.fling(find.byType(ListView), const Offset(0, -2400), 2000);
      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(FilledButton, 'Save');
      expect(submitButton, findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Publish'), findsNothing);

      final cubit = BlocProvider.of<CreateEventCubit>(
        tester.element(find.byType(ListView)),
      );
      cubit.setStatus(EventStatus.open);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Publish'), findsOneWidget);
    });
  });
}
