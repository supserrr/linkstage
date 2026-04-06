import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

/// Use case: complete sign-in using the email link.
class SignInWithEmailLinkUseCase {
  SignInWithEmailLinkUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call(String email, String emailLink) {
    return _repository.signInWithEmailLink(email, emailLink);
  }
}
