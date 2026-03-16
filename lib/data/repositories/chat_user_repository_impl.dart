import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/chat_user_repository.dart';
import '../datasources/chat_user_remote_datasource.dart';

class ChatUserRepositoryImpl implements ChatUserRepository {
  ChatUserRepositoryImpl(this._dataSource);

  final ChatUserRemoteDataSource _dataSource;

  @override
  Future<void> ensureChatUser(UserEntity user) async {
    final displayName =
        user.displayName ?? user.username ?? user.email;
    await _dataSource.ensureChatUser(
      id: user.id,
      displayName: displayName,
      photoUrl: user.photoUrl,
    );
  }

  @override
  Future<void> ensureChatUserById(String userId) async {
    await _dataSource.ensureChatUserById(userId);
  }
}
