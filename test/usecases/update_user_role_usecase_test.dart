import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/domain/usecases/user/update_user_role_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserRole.eventPlanner);
  });

  test('delegates updateRole', () async {
    final repo = MockUserRepository();
    when(
      () => repo.updateRole(any(), any()),
    ).thenAnswer((_) async => {});
    await UpdateUserRoleUseCase(repo).call('uid', UserRole.eventPlanner);
    verify(() => repo.updateRole('uid', UserRole.eventPlanner)).called(1);
  });
}
