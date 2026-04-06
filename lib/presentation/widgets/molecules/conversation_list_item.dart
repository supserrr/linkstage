import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../domain/entities/conversation_entity.dart';

/// A single row in the conversation list: avatar, name, last message preview, time.
class ConversationListItem extends StatelessWidget {
  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.showDivider = true,
  });

  final ConversationEntity conversation;
  final VoidCallback onTap;
  final bool showDivider;

  static const double _avatarSize = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = conversation.otherUserDisplayName?.isNotEmpty == true
        ? conversation.otherUserDisplayName!
        : (conversation.otherUserId.isNotEmpty ? 'User' : 'Unknown');
    final hasLastMessage = conversation.lastMessageText?.isNotEmpty == true;
    final subtitle = hasLastMessage
        ? conversation.lastMessageText!
        : 'No messages yet';
    final time = conversation.lastMessageAt ?? conversation.createdAt;
    final timeStr = time != null ? _formatTime(time) : '';

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: SizedBox(
                width: _avatarSize,
                height: _avatarSize,
                child:
                    conversation.otherUserPhotoUrl != null &&
                        conversation.otherUserPhotoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: conversation.otherUserPhotoUrl!,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          AppIcons.person,
                          size: 28,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w700
                        : FontWeight.w600,
                    letterSpacing: -0.2,
                    color: conversation.unreadCount > 0
                        ? colorScheme.onSurface
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasLastMessage
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w600
                        : (hasLastMessage
                              ? FontWeight.normal
                              : FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
          if (timeStr.isNotEmpty || conversation.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: conversation.unreadCount > 0
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (conversation.unreadCount > 0) ...[
                  if (timeStr.isNotEmpty) const SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: conversation.unreadCount > 99 ? 4 : 6,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation.unreadCount > 99
                          ? '99+'
                          : '${conversation.unreadCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    return Material(
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(onTap: onTap, child: content),
          if (showDivider)
            Divider(
              height: 1,
              indent: 16 + _avatarSize + 14,
              endIndent: 16,
              color: theme.dividerColor,
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(t.year, t.month, t.day);
    if (msgDay == today) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return 'Yesterday';
    if (now.difference(msgDay).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[t.weekday - 1];
    }
    return '${t.day}/${t.month}';
  }
}
