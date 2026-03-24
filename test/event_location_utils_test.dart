import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/utils/event_location_utils.dart';
import 'package:linkstage/domain/entities/event_entity.dart';

void main() {
  group('eventLocationIsVisible', () {
    test('returns true when viewer is planner regardless of visibility', () {
      for (final vis in LocationVisibility.values) {
        final event = EventEntity(
          id: '1',
          plannerId: 'planner-1',
          title: 'Event',
          locationVisibility: vis,
        );
        expect(
          eventLocationIsVisible(
            event,
            isPlanner: true,
            hasAcceptedBooking: false,
          ),
          isTrue,
        );
      }
    });

    test('returns true for public visibility when not planner', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'planner-1',
        title: 'Event',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        eventLocationIsVisible(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        isTrue,
      );
    });

    test('returns false for private visibility when not planner', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'planner-1',
        title: 'Event',
        locationVisibility: LocationVisibility.private,
      );
      expect(
        eventLocationIsVisible(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        isFalse,
      );
    });

    test(
      'returns false for acceptedCreatives when not planner and no accepted booking',
      () {
        final event = EventEntity(
          id: '1',
          plannerId: 'planner-1',
          title: 'Event',
          locationVisibility: LocationVisibility.acceptedCreatives,
        );
        expect(
          eventLocationIsVisible(
            event,
            isPlanner: false,
            hasAcceptedBooking: false,
          ),
          isFalse,
        );
      },
    );

    test('returns true for acceptedCreatives when has accepted booking', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'planner-1',
        title: 'Event',
        locationVisibility: LocationVisibility.acceptedCreatives,
      );
      expect(
        eventLocationIsVisible(
          event,
          isPlanner: false,
          hasAcceptedBooking: true,
        ),
        isTrue,
      );
    });
  });

  group('getEventLocationDisplayLine', () {
    test('returns placeholder when location is hidden', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: '123 Main St',
        locationVisibility: LocationVisibility.private,
      );
      expect(
        getEventLocationDisplayLine(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        kEventLocationHiddenPlaceholder,
      );
    });

    test('returns actual location when visible and non-empty', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: '123 Main St',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        getEventLocationDisplayLine(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        '123 Main St',
      );
    });

    test('returns em dash when visible but location empty', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: '',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        getEventLocationDisplayLine(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        '—',
      );
    });
  });

  group('getEventVenueDisplay', () {
    test('returns placeholder when hidden', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        venueName: 'Convention Center',
        locationVisibility: LocationVisibility.private,
      );
      expect(
        getEventVenueDisplay(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        kEventVenueHiddenPlaceholder,
      );
    });

    test('returns venue name when visible', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        venueName: 'Convention Center',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        getEventVenueDisplay(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        'Convention Center',
      );
    });

    test('returns Place when visible but venue empty', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        venueName: '',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        getEventVenueDisplay(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        'Place',
      );
    });
  });

  group('getEventAddressDisplay', () {
    test('returns placeholder when hidden', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: 'Addr',
        locationVisibility: LocationVisibility.private,
      );
      expect(
        getEventAddressDisplay(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        kEventLocationHiddenPlaceholder,
      );
    });

    test('returns address when visible and non-empty', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: 'KN 4',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        getEventAddressDisplay(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        'KN 4',
      );
    });

    test('returns default text when visible but location empty', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: '',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        getEventAddressDisplay(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        'Address not specified',
      );
    });
  });

  group('eventMapsDestinationIfVisible', () {
    test('returns null when location hidden', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: '123 Main St',
        venueName: 'Hall',
        locationVisibility: LocationVisibility.private,
      );
      expect(
        eventMapsDestinationIfVisible(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        isNull,
      );
    });

    test('returns combined venue and address when visible', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: '123 Main St',
        venueName: 'Hall',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        eventMapsDestinationIfVisible(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        'Hall, 123 Main St',
      );
    });

    test('returns only venue when location empty but venue set', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: '',
        venueName: 'Intare Arena',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        eventMapsDestinationIfVisible(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        'Intare Arena',
      );
    });

    test('returns null when visible but both venue and location empty', () {
      final event = EventEntity(
        id: '1',
        plannerId: 'p1',
        title: 'Event',
        location: '',
        venueName: '',
        locationVisibility: LocationVisibility.public,
      );
      expect(
        eventMapsDestinationIfVisible(
          event,
          isPlanner: false,
          hasAcceptedBooking: false,
        ),
        isNull,
      );
    });
  });
}
