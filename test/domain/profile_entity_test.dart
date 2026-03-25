import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';

void main() {
  final base = ProfileEntity(
    id: 'alice',
    userId: 'u1',
    username: 'alice',
    category: ProfileCategory.photographer,
  );

  test('availabilityFromKey and availabilityKey', () {
    expect(
      ProfileEntity.availabilityFromKey('open_to_work'),
      ProfileAvailability.openToWork,
    );
    expect(
      ProfileEntity.availabilityFromKey('not_available'),
      ProfileAvailability.notAvailable,
    );
    expect(ProfileEntity.availabilityFromKey('x'), null);
    const p = ProfileEntity(
      id: '1',
      userId: 'u',
      availability: ProfileAvailability.openToWork,
    );
    expect(p.availabilityKey, 'open_to_work');
    const p2 = ProfileEntity(id: '1', userId: 'u');
    expect(p2.availabilityKey, '');
  });

  test('categoryKey and categoryFromKey', () {
    expect(base.categoryKey, 'photographer');
    expect(
      const ProfileEntity(id: '1', userId: 'u', category: ProfileCategory.dj)
          .categoryKey,
      'dj',
    );
    expect(
      const ProfileEntity(
        id: '1',
        userId: 'u',
        category: ProfileCategory.decorator,
      ).categoryKey,
      'decorator',
    );
    expect(
      const ProfileEntity(
        id: '1',
        userId: 'u',
        category: ProfileCategory.contentCreator,
      ).categoryKey,
      'content_creator',
    );
    expect(const ProfileEntity(id: '1', userId: 'u').categoryKey, '');
    expect(ProfileEntity.categoryFromKey('dj'), ProfileCategory.dj);
    expect(ProfileEntity.categoryFromKey('decorator'), ProfileCategory.decorator);
    expect(ProfileEntity.categoryFromKey('content_creator'),
        ProfileCategory.contentCreator);
    expect(ProfileEntity.categoryFromKey('bad'), null);
  });

  test('copyWith', () {
    final u = base.copyWith(
      photoUrl: 'http://x',
      profileVisibility: ProfileVisibility.onlyMe,
      displayName: 'A',
    );
    expect(u.photoUrl, 'http://x');
    expect(u.profileVisibility, ProfileVisibility.onlyMe);
    expect(u.displayName, 'A');
  });

  test('props', () {
    expect(base, base);
  });

  test('inequality when props fields differ', () {
    const a = ProfileEntity(
      id: '1',
      userId: 'u',
      bio: 'a',
      professions: ['p'],
      priceRange: '1',
      location: 'Kigali',
      portfolioUrls: ['x'],
      portfolioVideoUrls: ['v'],
      services: ['s'],
      languages: ['en'],
      photoUrl: 'http://p',
      profileVisibility: ProfileVisibility.everyone,
    );
    const b = ProfileEntity(
      id: '1',
      userId: 'u',
      bio: 'b',
    );
    expect(a == b, isFalse);
  });
}
