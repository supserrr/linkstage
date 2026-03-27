import '../../repositories/auth_repository.dart';

/// Use case: sign out.
class SignOutUseCase {
  SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() {
    return _repository.signOut();
  }
}
