import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_borders.dart';
import '../../core/constants/app_icons.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/firestore_error_utils.dart';
import '../../core/utils/toast_utils.dart';
import '../widgets/molecules/connection_error_overlay.dart';
import '../widgets/molecules/skeleton_loaders.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_user_repository.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../widgets/molecules/chat_input_bar.dart';
import '../widgets/molecules/message_bubble.dart';

/// Screen showing a single chat thread (custom UI, no chatview).
/// Opened either by [chatId] (from messages list) or by [otherUserId] (from profile).
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.chatId, this.otherUserId});

  final String? chatId;
  final String? otherUserId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();
  int _lastSeenMessageCount = 0;
  int _currentMessageCount = 0;
  bool _showNewMessagesBanner = false;
  static const double _atBottomThreshold = 100;

  String? _resolvedChatId;
  String? _otherUserId;
  UserRole? _otherUserRole;
  String _otherUserName = 'Chat';
  String? _otherUserPhotoUrl;
  Object? _error;

  static String _displayNameFor(UserEntity? u, String fallbackId) {
    if (u == null) return fallbackId;
    return u.displayName?.isNotEmpty == true
        ? u.displayName!
        : (u.username?.isNotEmpty == true ? u.username! : u.email);
  }

  void _navigateToProfile() {
    if (_otherUserId == null || _otherUserId!.isEmpty) return;
    final userId = _otherUserId!;
    final route = _otherUserRole == UserRole.eventPlanner
        ? AppRoutes.plannerProfileView(userId)
        : AppRoutes.creativeProfileView(userId);
    context.push(route);
  }

  Widget _buildAppBarTitle(ColorScheme colorScheme, ThemeData theme) {
    final canNavigate = _otherUserId != null && _otherUserId!.isNotEmpty;
    const pillBorder = StadiumBorder();
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canNavigate ? _navigateToProfile : null,
            customBorder: pillBorder,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: _otherUserPhotoUrl != null && _otherUserPhotoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(_otherUserPhotoUrl!)
                  : null,
              child: _otherUserPhotoUrl == null || _otherUserPhotoUrl!.isEmpty
                  ? Icon(AppIcons.person, size: 32, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canNavigate ? _navigateToProfile : null,
            customBorder: pillBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Text(
                _otherUserName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initChat());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels <= _atBottomThreshold;
    if (atBottom) {
      if (_showNewMessagesBanner || _lastSeenMessageCount != _currentMessageCount) {
        setState(() {
          _showNewMessagesBanner = false;
          _lastSeenMessageCount = _currentMessageCount;
        });
      }
    }
  }

  void _scrollToNewMessages() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() {
      _showNewMessagesBanner = false;
      _lastSeenMessageCount = _currentMessageCount;
    });
  }

  Future<void> _initChat() async {
    final authRepo = sl<AuthRepository>();
    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _error = 'Not signed in');
      return;
    }

    try {
      await sl<ChatUserRepository>().ensureChatUser(currentUser);

      if (widget.chatId != null && widget.chatId!.isNotEmpty) {
        _resolvedChatId = widget.chatId;
        unawaited(
          sl<ConversationRepository>().markChatAsRead(widget.chatId!, currentUser.id),
        );
        final other = await sl<ConversationRepository>().getOtherParticipant(
          widget.chatId!,
          currentUser.id,
        );
        if (mounted && other != null) {
          final otherUser = await sl<UserRepository>().getUser(other.otherUserId);
          setState(() {
            _otherUserId = other.otherUserId;
            _otherUserRole = otherUser?.role;
            _otherUserName = _displayNameFor(otherUser, other.displayName);
            _otherUserPhotoUrl = otherUser?.photoUrl;
          });
        }
      } else if (widget.otherUserId != null && widget.otherUserId!.isNotEmpty) {
        final otherUser = await sl<UserRepository>().getUser(widget.otherUserId!);
        if (otherUser != null) {
          await sl<ChatUserRepository>().ensureChatUser(otherUser);
        } else {
          await sl<ChatUserRepository>().ensureChatUserById(widget.otherUserId!);
        }
        _resolvedChatId = await sl<ConversationRepository>().getOrCreateOneToOneChat(
          currentUser.id,
          widget.otherUserId!,
        );
        if (mounted) {
          setState(() {
            _otherUserId = widget.otherUserId;
            _otherUserRole = otherUser?.role;
            _otherUserName = _displayNameFor(otherUser, widget.otherUserId!);
            _otherUserPhotoUrl = otherUser?.photoUrl;
          });
        }
        unawaited(
          sl<ConversationRepository>().markChatAsRead(_resolvedChatId!, currentUser.id),
        );
      } else {
        if (mounted) setState(() => _error = 'Missing chat or user');
        return;
      }
      if (mounted) setState(() {});
    } catch (e, st) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('restricted') || msg.contains('who can message')) {
          showToast(context, 'This user has restricted who can message them', isError: true);
          context.pop();
          return;
        }
        setState(() => _error = e);
        debugPrint('Chat init error: $e $st');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to open chat: $_error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final chatId = _resolvedChatId;
    if (chatId == null || chatId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 92,
          title: const ChatAppBarSkeleton(),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
                child: const ChatMessagesSkeleton(),
              ),
            ),
            ChatInputBar(
              onSend: (_) {},
              enabled: false,
              disabledHint: 'Connecting...',
            ),
          ],
        ),
      );
    }

    final currentUser = sl<AuthRepository>().currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.messages),
          ),
          title: Text(_otherUserName),
        ),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final messagesStream = sl<ConversationRepository>().watchMessages(chatId);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return StreamBuilder<List<MessageEntity>>(
      stream: messagesStream,
      builder: (context, snapshot) {
        final showAppBarSkeleton = !snapshot.hasData;
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.messages),
            ),
            toolbarHeight: 92,
            title: showAppBarSkeleton
                ? const ChatAppBarSkeleton()
                : _buildAppBarTitle(colorScheme, theme),
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
                  child: _buildMessagesContent(
                    context,
                    snapshot,
                    chatId,
                    currentUser,
                  ),
                ),
              ),
              ChatInputBar(
                onSend: (text) async {
                  try {
                    await sl<ConversationRepository>().sendMessage(
                      chatId,
                      currentUser.id,
                      text,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      showToast(
                        context,
                        'Send failed: ${firestoreErrorMessage(e)}',
                        isError: true,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesContent(
    BuildContext context,
    AsyncSnapshot<List<MessageEntity>> snapshot,
    String chatId,
    UserEntity currentUser,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (snapshot.hasError) {
      return ConnectionErrorOverlay(
        hasError: true,
        error: snapshot.error,
        onRefresh: () async {
          if (mounted) setState(() {});
        },
        onBack: () => context.pop(),
        child: const ChatMessagesSkeleton(),
      );
    }
    if (!snapshot.hasData) {
      return const ChatMessagesSkeleton();
    }
    final messages = snapshot.data!;
    _currentMessageCount = messages.length;
    if (messages.length > _lastSeenMessageCount && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_scrollController.hasClients) return;
        final atBottom = _scrollController.position.pixels <= _atBottomThreshold;
        if (!atBottom && !_showNewMessagesBanner) {
          setState(() => _showNewMessagesBanner = true);
        } else if (atBottom) {
          _lastSeenMessageCount = messages.length;
        }
      });
    }
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Send a message to start the conversation',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  borderRadius: AppBorders.borderRadius,
                ),
                child: Text(
                  _formatDateHeader(messages.isNotEmpty ? messages.last.createdAt : DateTime.now()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }
        final message = messages[messages.length - 1 - index];
        final isSentByMe = message.senderId == currentUser.id;
        return MessageBubble(
          message: message,
          isSentByMe: isSentByMe,
        );
      },
        ),
        if (_showNewMessagesBanner)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _scrollToNewMessages,
                  borderRadius: AppBorders.borderRadius,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppBorders.borderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'New messages',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _formatDateHeader(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(t.year, t.month, t.day);
    if (msgDay == today) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return 'Yesterday';
    if (now.difference(msgDay).inDays < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[t.weekday - 1];
    }
    return '${t.day}/${t.month}/${t.year}';
  }
}
