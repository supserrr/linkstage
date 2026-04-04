import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/conversation_remote_datasource.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._dataSource, this._userRepository);

  final ConversationRemoteDataSource _dataSource;
  final UserRepository _userRepository;

  @override
  Stream<List<ConversationEntity>> watchConversations(String userId) =>
      _dataSource.watchConversations(userId);

  @override
  Future<String> getOrCreateOneToOneChat(
    String currentUserId,
    String otherUserId,
  ) async {
    final canMessage = await _userRepository.canSendMessageTo(
      currentUserId,
      otherUserId,
    );
    if (!canMessage) {
      throw Exception('This user has restricted who can message them');
    }
    return _dataSource.getOrCreateOneToOneChat(currentUserId, otherUserId);
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) =>
      _dataSource.watchMessages(chatId);

  @override
  Future<void> sendMessage(String chatId, String senderId, String text) =>
      _dataSource.sendMessage(chatId, senderId, text);

  @override
  Future<({String otherUserId, String displayName})?> getOtherParticipant(
    String chatId,
    String currentUserId,
  ) => _dataSource.getOtherParticipant(chatId, currentUserId);

  @override
  Future<void> markChatAsRead(String chatId, String userId) =>
      _dataSource.markChatAsRead(chatId, userId);
}
