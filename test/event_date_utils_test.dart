import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/utils/event_date_utils.dart';
import 'package:linkstage/domain/entities/event_entity.dart';

void main() {
  group('EventDateUtils', () {
    group('isUpcomingEvent', () {
      test('returns false when status is completed', () {
        final event = EventEntity(
          id: '1',
          plannerId: 'p1',
          title: 'Event',
          status: EventStatus.completed,
          date: DateTime(2030, 1, 1),
        );
        expect(EventDateUtils.isUpcomingEvent(event), isFalse);
      });

      test('returns true when date is null', () {
        final event = EventEntity(
          id: '1',
          plannerId: 'p1',
          title: 'Event',
          date: null,
        );
        expect(EventDateUtils.isUpcomingEvent(event), isTrue);
      });

      test('returns true when date is in future', () {
        final event = EventEntity(
          id: '1',
          plannerId: 'p1',
          title: 'Event',
          date: DateTime(2030, 6, 15),
        );
        expect(EventDateUtils.isUpcomingEvent(event), isTrue);
      });

      test('returns false when date is in past', () {
        final event = EventEntity(
          id: '1',
          plannerId: 'p1',
          title: 'Event',
          date: DateTime(2000, 1, 1),
        );
        expect(EventDateUtils.isUpcomingEvent(event), isFalse);
      });
    });

    group('isPastEvent', () {
      test('returns true when status is completed', () {
        final event = EventEntity(
          id: '1',
          plannerId: 'p1',
          title: 'Event',
          status: EventStatus.completed,
          date: DateTime(2030, 1, 1),
        );
        expect(EventDateUtils.isPastEvent(event), isTrue);
      });

      test('returns false when date is null', () {
        final event = EventEntity(
          id: '1',
          plannerId: 'p1',
          title: 'Event',
          date: null,
        );
        expect(EventDateUtils.isPastEvent(event), isFalse);
      });

      test('returns true when date is in past', () {
        final event = EventEntity(
          id: '1',
          plannerId: 'p1',
          title: 'Event',
          date: DateTime(2000, 1, 1),
        );
        expect(EventDateUtils.isPastEvent(event), isTrue);
      });

      test('returns false when date is in future', () {
        final event = EventEntity(
          id: '1',
          plannerId: 'p1',
          title: 'Event',
          date: DateTime(2030, 6, 15),
        );
        expect(EventDateUtils.isPastEvent(event), isFalse);
      });
    });
  });
}
