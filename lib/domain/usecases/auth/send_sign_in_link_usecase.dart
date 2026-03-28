import '../../repositories/auth_repository.dart';

/// Use case: send a sign-in link to the given email (passwordless).
class SendSignInLinkUseCase {
  SendSignInLinkUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) {
    return _repository.sendSignInLinkToEmail(email);
  }
}
