import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/usecases/user/upsert_user_usecase.dart';
import 'package:linkstage/presentation/bloc/role_selection/role_selection_cubit.dart';
import 'package:linkstage/presentation/bloc/role_selection/role_selection_state.dart';
import 'package:mocktail/mocktail.dart';

class MockUpsertUserUseCase extends Mock implements UpsertUserUseCase {}

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
    role: UserRole.creativeProfessional,
  );

  test('setHighlightedRole updates state', () {
    final uc = MockUpsertUserUseCase();
    final cubit = RoleSelectionCubit(uc);
    cubit.setHighlightedRole(UserRole.eventPlanner);
    expect(cubit.state.highlightedRole, UserRole.eventPlanner);
  });

  test('selectRole success emits success', () async {
    final uc = MockUpsertUserUseCase();
    when(() => uc(any())).thenAnswer((_) async {});

    final cubit = RoleSelectionCubit(uc);
    await cubit.selectRole(user, UserRole.eventPlanner);

    expect(cubit.state.status, RoleSelectionStatus.success);
    expect(cubit.state.role, UserRole.eventPlanner);
  });

  test('selectRole failure emits error', () async {
    final uc = MockUpsertUserUseCase();
    when(() => uc(any())).thenThrow(Exception('fail'));

    final cubit = RoleSelectionCubit(uc);
    await cubit.selectRole(user, UserRole.eventPlanner);

    expect(cubit.state.status, RoleSelectionStatus.error);
    expect(cubit.state.error, contains('fail'));
  });
}
