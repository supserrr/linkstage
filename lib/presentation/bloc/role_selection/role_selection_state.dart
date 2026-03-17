import '../../../domain/entities/user_entity.dart';

enum RoleSelectionStatus { initial, loading, success, error }

class RoleSelectionState {
  const RoleSelectionState({
    this.status = RoleSelectionStatus.initial,
    this.role,
    this.user,
    this.error,
  });

  const RoleSelectionState.initial()
    : status = RoleSelectionStatus.initial,
      role = null,
      user = null,
      error = null;

  const RoleSelectionState.loading()
    : status = RoleSelectionStatus.loading,
      role = null,
      user = null,
      error = null;

  RoleSelectionState.success(this.role, [this.user])
    : status = RoleSelectionStatus.success,
      error = null;

  final UserEntity? user;

  RoleSelectionState.error(this.error)
    : status = RoleSelectionStatus.error,
      role = null,
      user = null;

  final RoleSelectionStatus status;
  final UserRole? role;
  final String? error;
}
