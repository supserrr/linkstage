import 'package:equatable/equatable.dart';

/// Domain entity for a conversation (list row).
class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.otherUserId,
    this.otherUserDisplayName,
    this.otherUserPhotoUrl,
    this.lastMessageText,
    this.lastMessageAt,
    this.createdAt,
    this.hasUnread = false,
    this.unreadCount = 0,
  });

  final String id;
  final String otherUserId;
  final String? otherUserDisplayName;
  final String? otherUserPhotoUrl;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final bool hasUnread;
  final int unreadCount;

  @override
  List<Object?> get props => [
    id,
    otherUserId,
    otherUserDisplayName,
    otherUserPhotoUrl,
    lastMessageText,
    lastMessageAt,
    createdAt,
    hasUnread,
    unreadCount,
  ];
}
