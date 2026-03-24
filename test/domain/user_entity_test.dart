import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/user_entity.dart';

void main() {
  const user = UserEntity(id: '1', email: 'a@b.com');

  test('roleKey returns empty when role null', () {
    expect(user.roleKey, '');
  });

  test('roleKey when role set', () {
    const u = UserEntity(
      id: '1',
      email: 'a@b.com',
      role: UserRole.eventPlanner,
    );
    expect(u.roleKey, 'event_planner');
  });

  test('roleFromKey', () {
    expect(UserEntity.roleFromKey('event_planner'), UserRole.eventPlanner);
    expect(UserEntity.roleFromKey('creative_professional'),
        UserRole.creativeProfessional);
    expect(UserEntity.roleFromKey('x'), null);
  });

  test('profileVisibilityFromKey and toKey', () {
    expect(
      UserEntity.profileVisibilityFromKey('everyone'),
      ProfileVisibility.everyone,
    );
    expect(
      UserEntity.profileVisibilityFromKey('connections_only'),
      ProfileVisibility.connectionsOnly,
    );
    expect(
      UserEntity.profileVisibilityFromKey('only_me'),
      ProfileVisibility.onlyMe,
    );
    expect(UserEntity.profileVisibilityFromKey(null), null);
    expect(
      UserEntity.profileVisibilityToKey(ProfileVisibility.everyone),
      'everyone',
    );
  });

  test('whoCanMessageFromKey and toKey', () {
    expect(UserEntity.whoCanMessageFromKey('everyone'), WhoCanMessage.everyone);
    expect(
      UserEntity.whoCanMessageFromKey('worked_with'),
      WhoCanMessage.workedWith,
    );
    expect(UserEntity.whoCanMessageFromKey('no_one'), WhoCanMessage.noOne);
    expect(UserEntity.whoCanMessageFromKey('bad'), null);
    expect(
      UserEntity.whoCanMessageToKey(WhoCanMessage.workedWith),
      'worked_with',
    );
  });

  test('props equality', () {
    expect(
      const UserEntity(id: '1', email: 'a@b.com'),
      const UserEntity(id: '1', email: 'a@b.com'),
    );
    expect(
      const UserEntity(id: '1', email: 'a@b.com'),
      isNot(const UserEntity(id: '2', email: 'a@b.com')),
    );
  });
}
