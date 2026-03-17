import '../../entities/user_entity.dart';
import '../../repositories/user_repository.dart';

/// Use case: update user role.
class UpdateUserRoleUseCase {
  UpdateUserRoleUseCase(this._repository);

  final UserRepository _repository;

  Future<void> call(String userId, UserRole role) {
    return _repository.updateRole(userId, role);
  }
}
