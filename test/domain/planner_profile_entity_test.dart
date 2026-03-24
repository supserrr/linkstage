import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';

void main() {
  test('copyWith', () {
    const p = PlannerProfileEntity(userId: 'u1');
    final n = p.copyWith(
      photoUrl: 'http://p',
      profileVisibility: ProfileVisibility.connectionsOnly,
      displayName: 'N',
    );
    expect(n.photoUrl, 'http://p');
    expect(n.profileVisibility, ProfileVisibility.connectionsOnly);
    expect(n.displayName, 'N');
  });

  test('props', () {
    final p = PlannerProfileEntity(
      userId: 'u1',
      bio: 'b',
      location: 'Kigali',
      eventTypes: const ['Wedding'],
      languages: const ['en'],
      portfolioUrls: const ['http://x'],
      displayName: 'D',
      role: 'Planner',
      photoUrl: 'http://p',
      profileVisibility: ProfileVisibility.everyone,
    );
    expect(p.props.length, 10);
    expect(p, p);
  });
}
