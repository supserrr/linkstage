import '../../repositories/auth_repository.dart';

/// Use case: update email (sends verification to new address).
class UpdateEmailUseCase {
  UpdateEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String newEmail) {
    return _repository.updateEmail(newEmail);
  }
}
