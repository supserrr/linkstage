import '../../entities/user_entity.dart';
import '../../repositories/user_repository.dart';

/// Use case: upsert user document (create or update).
class UpsertUserUseCase {
  UpsertUserUseCase(this._repository);

  final UserRepository _repository;

  Future<void> call(UserEntity user) => _repository.upsertUser(user);
}
