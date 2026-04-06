import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/usecases/user/change_username_usecase.dart';
import 'package:linkstage/presentation/bloc/change_username/change_username_cubit.dart';
import 'package:linkstage/presentation/bloc/change_username/change_username_state.dart';
import 'package:mocktail/mocktail.dart';

class MockChangeUsernameUseCase extends Mock implements ChangeUsernameUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      UserEntity(
        id: 'fb',
        email: 'e@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
  });

  final user = UserEntity(
    id: 'u1',
    email: 'a@b.com',
    username: 'oldname',
    role: UserRole.creativeProfessional,
  );

  test('checkAvailability short username sets validation error', () async {
    final uc = MockChangeUsernameUseCase();
    final cubit = ChangeUsernameCubit(uc, user);
    await cubit.checkAvailability('ab');
    expect(cubit.state.validationError, 'At least 3 characters required');
    expect(cubit.state.isAvailable, isFalse);
  });

  test('checkAvailability delegates to use case', () async {
    final uc = MockChangeUsernameUseCase();
    when(
      () => uc.validate('newname', excludeUserId: 'u1'),
    ).thenAnswer((_) async => null);
    final cubit = ChangeUsernameCubit(uc, user);
    await cubit.checkAvailability('newname');
    expect(cubit.state.isAvailable, isTrue);
    expect(cubit.state.isCheckingAvailability, isFalse);
  });

  test('submit success updates current username', () async {
    final uc = MockChangeUsernameUseCase();
    when(
      () => uc(user, 'freshname'),
    ).thenAnswer((_) async => ChangeUsernameSuccess());
    final cubit = ChangeUsernameCubit(uc, user);
    await cubit.submit('freshname');
    expect(cubit.state.status, ChangeUsernameStatus.success);
    expect(cubit.state.currentUsername, 'freshname');
  });

  test('submit cooldown sets nextChangeDate string', () async {
    final uc = MockChangeUsernameUseCase();
    final next = DateTime.utc(2027, 6, 15);
    when(
      () => uc(user, 'coolname'),
    ).thenAnswer((_) async => ChangeUsernameCooldown(next));
    final cubit = ChangeUsernameCubit(uc, user);
    await cubit.submit('coolname');
    expect(cubit.state.status, ChangeUsernameStatus.error);
    expect(cubit.state.nextChangeDate, '2027-06-15');
  });

  test('submit invalid and taken', () async {
    final uc = MockChangeUsernameUseCase();
    when(
      () => uc(user, 'bad'),
    ).thenAnswer((_) async => ChangeUsernameInvalid('bad format'));
    when(
      () => uc(user, 'taken1'),
    ).thenAnswer((_) async => ChangeUsernameTaken());

    final cubit = ChangeUsernameCubit(uc, user);
    await cubit.submit('bad');
    expect(cubit.state.errorMessage, 'bad format');

    await cubit.submit('taken1');
    expect(cubit.state.errorMessage, 'This username is taken');
  });

  test('submit short username is no-op', () async {
    final uc = MockChangeUsernameUseCase();
    final cubit = ChangeUsernameCubit(uc, user);
    await cubit.submit('ab');
    verifyNever(() => uc(any<UserEntity>(), any<String>()));
  });

  test('clearValidation clears errors', () async {
    final uc = MockChangeUsernameUseCase();
    final cubit = ChangeUsernameCubit(uc, user);
    await cubit.checkAvailability('ab');
    cubit.clearValidation();
    expect(cubit.state.validationError, isNull);
  });
}
