import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/user/upsert_user_usecase.dart';
import 'role_selection_state.dart';

class RoleSelectionCubit extends Cubit<RoleSelectionState> {
  RoleSelectionCubit(this._upsertUser)
    : super(const RoleSelectionState.initial());

  final UpsertUserUseCase _upsertUser;

  Future<void> selectRole(UserEntity user, UserRole role) async {
    emit(const RoleSelectionState.loading());
    try {
      final userWithRole = UserEntity(
        id: user.id,
        email: user.email,
        emailVerified: user.emailVerified,
        username: user.username,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        role: role,
      );
      await _upsertUser(userWithRole);
      emit(RoleSelectionState.success(role, userWithRole));
    } catch (e) {
      emit(RoleSelectionState.error(e.toString()));
    }
  }
}
