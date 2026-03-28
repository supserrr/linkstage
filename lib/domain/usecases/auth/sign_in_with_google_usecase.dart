import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

/// Use case: sign in with Google.
class SignInWithGoogleUseCase {
  SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call() {
    return _repository.signInWithGoogle();
  }
}
