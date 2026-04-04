import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/event_entity.dart';

void main() {
  test('locationVisibilityFromKey and locationVisibilityKey', () {
    expect(
      EventEntity.locationVisibilityFromKey('public'),
      LocationVisibility.public,
    );
    expect(
      EventEntity.locationVisibilityFromKey('private'),
      LocationVisibility.private,
    );
    expect(
      EventEntity.locationVisibilityFromKey('acceptedCreatives'),
      LocationVisibility.acceptedCreatives,
    );
    expect(EventEntity.locationVisibilityFromKey('bad'), null);

    const ev = EventEntity(
      id: '1',
      plannerId: 'p',
      title: 'T',
      locationVisibility: LocationVisibility.private,
    );
    expect(ev.locationVisibilityKey, 'private');

    expect(
      const EventEntity(
        id: '1',
        plannerId: 'p',
        title: 'T',
        locationVisibility: LocationVisibility.acceptedCreatives,
      ).locationVisibilityKey,
      'acceptedCreatives',
    );
    expect(
      const EventEntity(
        id: '1',
        plannerId: 'p',
        title: 'T',
        locationVisibility: LocationVisibility.public,
      ).locationVisibilityKey,
      'public',
    );
  });

  test('statusFromKey and statusKey', () {
    expect(EventEntity.statusFromKey('open'), EventStatus.open);
    expect(EventEntity.statusFromKey('draft'), EventStatus.draft);
    expect(EventEntity.statusFromKey('booked'), EventStatus.booked);
    expect(EventEntity.statusFromKey('completed'), EventStatus.completed);
    expect(EventEntity.statusFromKey('x'), null);
    expect(
      const EventEntity(
        id: '1',
        plannerId: 'p',
        title: 'T',
        status: EventStatus.open,
      ).statusKey,
      'open',
    );
    expect(
      const EventEntity(
        id: '1',
        plannerId: 'p',
        title: 'T',
        status: EventStatus.draft,
      ).statusKey,
      'draft',
    );
    expect(
      const EventEntity(
        id: '1',
        plannerId: 'p',
        title: 'T',
        status: EventStatus.booked,
      ).statusKey,
      'booked',
    );
    expect(
      const EventEntity(
        id: '1',
        plannerId: 'p',
        title: 'T',
        status: EventStatus.completed,
      ).statusKey,
      'completed',
    );
  });

  test('props', () {
    final d = DateTime.utc(2025);
    final e1 = EventEntity(
      id: '1',
      plannerId: 'p',
      title: 'T',
      date: d,
      location: 'L',
      description: 'D',
      status: EventStatus.open,
      imageUrls: const ['u'],
      eventType: 'E',
      budget: 1.0,
      startTime: '9',
      endTime: '5',
      venueName: 'V',
      showOnProfile: false,
      locationVisibility: LocationVisibility.public,
    );
    expect(e1.props.length, 15);
    expect(e1, e1);
  });
}
