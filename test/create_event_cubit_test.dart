import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/presentation/bloc/create_event/create_event_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  late EventRepository eventRepository;
  late BookingRepository bookingRepository;

  setUp(() {
    eventRepository = MockEventRepository();
    bookingRepository = MockBookingRepository();
  });

  group('CreateEventCubit', () {
    group('setLocationVisibility', () {
      test('updates state to private visibility', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setLocationVisibility(LocationVisibility.private);
        expect(cubit.state.locationVisibility, LocationVisibility.private);
      });

      test('updates state to acceptedCreatives visibility', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setLocationVisibility(LocationVisibility.acceptedCreatives);
        expect(
          cubit.state.locationVisibility,
          LocationVisibility.acceptedCreatives,
        );
      });

      test('updates state to public visibility', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setLocationVisibility(LocationVisibility.private);
        cubit.setLocationVisibility(LocationVisibility.public);
        expect(cubit.state.locationVisibility, LocationVisibility.public);
      });
    });

    group('initial state from event', () {
      test('loads locationVisibility from initial event', () {
        final event = EventEntity(
          id: 'e1',
          plannerId: 'p1',
          title: 'My Event',
          locationVisibility: LocationVisibility.private,
        );
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'p1',
          initialEvent: event,
        );
        expect(cubit.state.locationVisibility, LocationVisibility.private);
        expect(cubit.state.title, 'My Event');
      });

      test('defaults to public when creating new event', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        expect(cubit.state.locationVisibility, LocationVisibility.public);
      });
    });

    group('setters', () {
      test('setTitle updates state', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setTitle('New Title');
        expect(cubit.state.title, 'New Title');
      });

      test('setDate updates state', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        final date = DateTime(2025, 6, 15);
        cubit.setDate(date);
        expect(cubit.state.date, date);
      });

      test('setLocation updates state', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setLocation('123 Main St');
        expect(cubit.state.location, '123 Main St');
      });

      test('setDescription updates state', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setDescription('Event description');
        expect(cubit.state.description, 'Event description');
      });

      test('setBudget updates state', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setBudget(5000);
        expect(cubit.state.budget, 5000);
      });

      test('setEventType updates state', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setEventType('Wedding');
        expect(cubit.state.eventType, 'Wedding');
      });

      test('setVenueName updates state', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setVenueName('Convention Center');
        expect(cubit.state.venueName, 'Convention Center');
      });

      test('setStartTime and setEndTime update state', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setStartTime('10:00');
        cubit.setEndTime('18:00');
        expect(cubit.state.startTime, '10:00');
        expect(cubit.state.endTime, '18:00');
      });

      test('addImageUrl appends to imageUrls', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.addImageUrl('https://example.com/1.jpg');
        expect(cubit.state.imageUrls, ['https://example.com/1.jpg']);
        cubit.addImageUrl('https://example.com/2.jpg');
        expect(
          cubit.state.imageUrls,
          ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
        );
      });

      test('removeImageUrl removes from imageUrls', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.addImageUrl('https://example.com/1.jpg');
        cubit.addImageUrl('https://example.com/2.jpg');
        cubit.removeImageUrl('https://example.com/1.jpg');
        expect(cubit.state.imageUrls, ['https://example.com/2.jpg']);
      });

      test('setLocationFromPlace sets location, lat, and lng', () {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setLocationFromPlace(
          address: '123 Main St',
          lat: -1.95,
          lng: 30.06,
        );
        expect(cubit.state.location, '123 Main St');
        expect(cubit.state.locationLat, -1.95);
        expect(cubit.state.locationLng, 30.06);
      });
    });

    group('save', () {
      test('returns null and sets error when title is empty', () async {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        final result = await cubit.save();
        expect(result, isNull);
        expect(cubit.state.error, 'Title is required');
      });

      test('returns null and sets error when title is whitespace only',
          () async {
        final cubit = CreateEventCubit(
          eventRepository,
          bookingRepository,
          'planner-1',
        );
        cubit.setTitle('   ');
        final result = await cubit.save();
        expect(result, isNull);
        expect(cubit.state.error, 'Title is required');
      });
    });
  });
}
