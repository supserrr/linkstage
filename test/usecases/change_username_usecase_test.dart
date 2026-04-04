import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/domain/usecases/user/change_username_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const UserEntity(id: 'fallback', email: 'f@f.com'),
    );
    registerFallbackValue(
      const ProfileEntity(id: 'fallback', userId: 'fallback'),
    );
  });

  late MockUserRepository users;
  late MockProfileRepository profiles;
  late ChangeUsernameUseCase uc;

  setUp(() {
    users = MockUserRepository();
    profiles = MockProfileRepository();
    uc = ChangeUsernameUseCase(users, profiles);
  });

  group('validate', () {
    test('invalid username returns message', () async {
      final err = await uc.validate('ab');
      expect(err, isNotNull);
    });

    test('username longer than 20 returns validation message', () async {
      final err = await uc.validate('a' * 21);
      expect(err, isNotNull);
    });

    test('valid username unavailable returns taken message', () async {
      when(
        () => users.checkUsernameAvailable(any(), excludeUserId: any(named: 'excludeUserId')),
      ).thenAnswer((_) async => false);
      final err = await uc.validate('valid_name');
      expect(err, contains('taken'));
    });

    test('valid username available returns null', () async {
      when(
        () => users.checkUsernameAvailable(any(), excludeUserId: any(named: 'excludeUserId')),
      ).thenAnswer((_) async => true);
      expect(await uc.validate('valid_name'), null);
    });
  });

  group('call', () {
    test('invalid username returns ChangeUsernameInvalid', () async {
      const user = UserEntity(id: '1', email: 'a@b.com');
      final r = await uc.call(user, 'ab');
      expect(r, isA<ChangeUsernameInvalid>());
    });

    test('cooldown returns ChangeUsernameCooldown', () async {
      final last = DateTime.now().subtract(const Duration(days: 1));
      final user = UserEntity(
        id: '1',
        email: 'a@b.com',
        username: 'old_name',
        lastUsernameChangeAt: last,
      );
      final r = await uc.call(user, 'new_valid');
      expect(r, isA<ChangeUsernameCooldown>());
    });

    test('same username returns invalid', () async {
      const user = UserEntity(
        id: '1',
        email: 'a@b.com',
        username: 'same_name',
      );
      final r = await uc.call(user, 'same_name');
      expect(r, isA<ChangeUsernameInvalid>());
    });

    test('success path returns ChangeUsernameSuccess', () async {
      when(
        () => users.checkUsernameAvailable(any(), excludeUserId: any(named: 'excludeUserId')),
      ).thenAnswer((_) async => true);
      when(
        () => users.changeUsernameAtomic(
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => {});
      when(() => profiles.getProfileByUserId(any())).thenAnswer(
        (_) async => const ProfileEntity(
          id: 'old',
          userId: '1',
          username: 'old',
        ),
      );

      const user = UserEntity(
        id: '1',
        email: 'a@b.com',
        username: 'oldname',
        lastUsernameChangeAt: null,
      );
      final r = await uc.call(user, 'newname12');
      expect(r, isA<ChangeUsernameSuccess>());
      verify(
        () => users.changeUsernameAtomic(
          '1',
          'newname12',
          'oldname',
          any(),
          any(),
        ),
      ).called(1);
    });

    test('username taken after availability check', () async {
      when(
        () => users.checkUsernameAvailable(
          'taken12',
          excludeUserId: '1',
        ),
      ).thenAnswer((_) async => false);
      const user = UserEntity(
        id: '1',
        email: 'a@b.com',
        username: 'old',
      );
      final r = await uc.call(user, 'taken12');
      expect(r, isA<ChangeUsernameTaken>());
    });

    test('missing profile returns invalid', () async {
      when(
        () => users.checkUsernameAvailable(any(), excludeUserId: any(named: 'excludeUserId')),
      ).thenAnswer((_) async => true);
      when(() => profiles.getProfileByUserId(any())).thenAnswer((_) async => null);
      const user = UserEntity(
        id: '1',
        email: 'a@b.com',
        username: 'old',
      );
      final r = await uc.call(user, 'newname12');
      expect(r, isA<ChangeUsernameInvalid>());
    });

    test('atomic throws StateError yields taken', () async {
      when(
        () => users.checkUsernameAvailable(any(), excludeUserId: any(named: 'excludeUserId')),
      ).thenAnswer((_) async => true);
      when(() => profiles.getProfileByUserId(any())).thenAnswer(
        (_) async => const ProfileEntity(
          id: 'old',
          userId: '1',
          username: 'old',
        ),
      );
      when(
        () => users.changeUsernameAtomic(
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenThrow(StateError('race'));

      const user = UserEntity(
        id: '1',
        email: 'a@b.com',
        username: 'old',
      );
      final r = await uc.call(user, 'newname12');
      expect(r, isA<ChangeUsernameTaken>());
    });
  });
}
