import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/services/event_recommendation.dart';

void main() {
  EventEntity baseEvent({
    String title = 'Event',
    String description = '',
    String eventType = '',
    String location = 'Kigali',
  }) {
    return EventEntity(
      id: 'e1',
      plannerId: 'p1',
      title: title,
      description: description,
      eventType: eventType,
      location: location,
    );
  }

  ProfileEntity baseProfile({
    ProfileCategory? category = ProfileCategory.photographer,
    List<String> professions = const ['photographer'],
    List<String> services = const [],
    String location = 'Kigali',
  }) {
    return ProfileEntity(
      id: 'u1',
      userId: 'u1',
      category: category,
      professions: professions,
      services: services,
      location: location,
    );
  }

  test('scoreEventForCreative returns 0 when profile is null', () {
    expect(scoreEventForCreative(baseEvent(), null), 0);
  });

  test('profession word overlap adds weight', () {
    final event = baseEvent(
      title: 'wedding photography',
      description: 'great',
    );
    final profile = baseProfile(professions: ['photography', 'wedding']);
    final s = scoreEventForCreative(event, profile);
    expect(s, greaterThan(0));
  });

  test('category keyword matches add score (<=2 matches uses match count)', () {
    final event = baseEvent(
      title: 'wedding',
      eventType: 'corporate',
    );
    final profile = baseProfile(category: ProfileCategory.photographer);
    final s = scoreEventForCreative(event, profile);
    expect(s, greaterThan(0));
  });

  test('category matches >2 uses multiplier branch', () {
    final event = baseEvent(
      title: 'wedding photography corporate portrait event film',
      description: '',
    );
    final profile = baseProfile(category: ProfileCategory.photographer);
    final s = scoreEventForCreative(event, profile);
    expect(s, greaterThan(0));
  });

  test('location match adds weight', () {
    final event = baseEvent(location: 'Kigali Convention Centre');
    final profile = baseProfile(location: 'Kigali');
    final s = scoreEventForCreative(event, profile);
    expect(s, greaterThan(0));
  });

  test('location mismatch when empty yields no location bonus', () {
    final event = baseEvent(
      title: 'a',
      description: '',
      eventType: '',
      location: '',
    );
    final profile = baseProfile(location: 'Kigali');
    final sNoLoc = scoreEventForCreative(event, profile);
    expect(sNoLoc, 0);
  });

  test('dj category keywords', () {
    final event = baseEvent(title: 'club music party');
    final profile = baseProfile(category: ProfileCategory.dj);
    expect(scoreEventForCreative(event, profile), greaterThan(0));
  });

  test('decorator category keywords', () {
    final event = baseEvent(title: 'floral design venue');
    final profile = baseProfile(category: ProfileCategory.decorator);
    expect(scoreEventForCreative(event, profile), greaterThan(0));
  });

  test('contentCreator category keywords', () {
    final event = baseEvent(title: 'social media brand');
    final profile = baseProfile(category: ProfileCategory.contentCreator);
    expect(scoreEventForCreative(event, profile), greaterThan(0));
  });

  test('scores from services list when professions empty', () {
    final event = baseEvent(title: 'photography portrait');
    final profile = ProfileEntity(
      id: 'u1',
      userId: 'u1',
      category: ProfileCategory.photographer,
      professions: const [],
      services: const ['photography', 'portrait'],
    );
    expect(scoreEventForCreative(event, profile), greaterThan(0));
  });

  test('null category skips category branch', () {
    final event = baseEvent(title: 'photography wedding');
    final profile = ProfileEntity(
      id: 'u1',
      userId: 'u1',
      category: null,
      professions: ['photography'],
    );
    expect(scoreEventForCreative(event, profile), greaterThan(0));
  });
}
