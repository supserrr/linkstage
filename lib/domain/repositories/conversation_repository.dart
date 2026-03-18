import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

/// Repository for conversations and messages (custom chat, no chatview).
abstract class ConversationRepository {
  /// Stream of the current user's conversation list (from user_chats + chat_users).
  Stream<List<ConversationEntity>> watchConversations(String userId);

  /// Gets existing 1:1 chat id or creates a new chat; returns chatId.
  Future<String> getOrCreateOneToOneChat(
    String currentUserId,
    String otherUserId,
  );

  /// Stream of messages for a chat, ordered by createdAt.
  Stream<List<MessageEntity>> watchMessages(String chatId);

  /// Sends a text message and updates last message on both user_chats entries.
  Future<void> sendMessage(String chatId, String senderId, String text);

  /// Resolves the other participant's id and display name for a chat (for app bar).
  Future<({String otherUserId, String displayName})?> getOtherParticipant(
    String chatId,
    String currentUserId,
  );

  /// Marks the chat as read for the current user.
  Future<void> markChatAsRead(String chatId, String userId);
}
