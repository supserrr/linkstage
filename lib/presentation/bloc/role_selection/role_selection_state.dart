import '../../../domain/entities/user_entity.dart';

enum RoleSelectionStatus { initial, loading, success, error }

class RoleSelectionState {
  const RoleSelectionState({
    this.status = RoleSelectionStatus.initial,
    this.role,
    this.user,
    this.error,
    this.highlightedRole,
  });

  const RoleSelectionState.initial({this.highlightedRole})
    : status = RoleSelectionStatus.initial,
      role = null,
      user = null,
      error = null;

  const RoleSelectionState.loading({this.highlightedRole})
    : status = RoleSelectionStatus.loading,
      role = null,
      user = null,
      error = null;

  RoleSelectionState.success(this.role, [this.user])
    : status = RoleSelectionStatus.success,
      error = null,
      highlightedRole = role;

  RoleSelectionState.error(this.error, {this.highlightedRole})
    : status = RoleSelectionStatus.error,
      role = null,
      user = null;

  final UserEntity? user;

  final RoleSelectionStatus status;
  final UserRole? role;
  final String? error;
  final UserRole? highlightedRole;
}
