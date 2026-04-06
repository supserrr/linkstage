import '../../../domain/entities/user_entity.dart';

class ChatPageState {
  const ChatPageState({
    this.error,
    this.resolvedChatId,
    this.otherUserId,
    this.otherUserRole,
    this.otherUserName = 'Chat',
    this.otherUserPhotoUrl,
    this.lastSeenMessageCount = 0,
    this.showNewMessagesBanner = false,
    this.streamRefreshNonce = 0,
  });

  final Object? error;
  final String? resolvedChatId;
  final String? otherUserId;
  final UserRole? otherUserRole;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final int lastSeenMessageCount;
  final bool showNewMessagesBanner;
  final int streamRefreshNonce;

  ChatPageState copyWith({
    Object? error,
    String? resolvedChatId,
    String? otherUserId,
    UserRole? otherUserRole,
    String? otherUserName,
    String? otherUserPhotoUrl,
    int? lastSeenMessageCount,
    bool? showNewMessagesBanner,
    int? streamRefreshNonce,
    bool clearError = false,
    bool clearResolvedChat = false,
    bool clearOtherUser = false,
  }) {
    return ChatPageState(
      error: clearError ? null : (error ?? this.error),
      resolvedChatId: clearResolvedChat
          ? null
          : (resolvedChatId ?? this.resolvedChatId),
      otherUserId: clearOtherUser ? null : (otherUserId ?? this.otherUserId),
      otherUserRole: clearOtherUser
          ? null
          : (otherUserRole ?? this.otherUserRole),
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhotoUrl: clearOtherUser
          ? null
          : (otherUserPhotoUrl ?? this.otherUserPhotoUrl),
      lastSeenMessageCount: lastSeenMessageCount ?? this.lastSeenMessageCount,
      showNewMessagesBanner:
          showNewMessagesBanner ?? this.showNewMessagesBanner,
      streamRefreshNonce: streamRefreshNonce ?? this.streamRefreshNonce,
    );
  }
}
