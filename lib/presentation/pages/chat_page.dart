import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/chat_page/chat_page_cubit.dart';
import '../bloc/chat_page/chat_page_state.dart';
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
  late final ChatPageCubit _chatCubit;
  int _layoutMessageCount = 0;
  static const double _atBottomThreshold = 100;

  static String _displayNameFor(UserEntity? u, String fallbackId) {
    if (u == null) return fallbackId;
    return u.displayName?.isNotEmpty == true
        ? u.displayName!
        : (u.username?.isNotEmpty == true ? u.username! : u.email);
  }

  void _navigateToProfile() {
    final otherUserId = _chatCubit.state.otherUserId;
    if (otherUserId == null || otherUserId.isEmpty) return;
    final route = _chatCubit.state.otherUserRole == UserRole.eventPlanner
        ? AppRoutes.plannerProfileView(otherUserId)
        : AppRoutes.creativeProfileView(otherUserId);
    context.push(route);
  }

  Widget _buildAppBarTitle(
    ColorScheme colorScheme,
    ThemeData theme,
    ChatPageState chatState,
  ) {
    final canNavigate =
        chatState.otherUserId != null && chatState.otherUserId!.isNotEmpty;
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
              backgroundImage:
                  chatState.otherUserPhotoUrl != null &&
                      chatState.otherUserPhotoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(chatState.otherUserPhotoUrl!)
                  : null,
              child:
                  chatState.otherUserPhotoUrl == null ||
                      chatState.otherUserPhotoUrl!.isEmpty
                  ? Icon(
                      AppIcons.person,
                      size: 32,
                      color: colorScheme.onSurfaceVariant,
                    )
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
                chatState.otherUserName,
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
    _chatCubit = ChatPageCubit();
    unawaited(_initChat());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _chatCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels <= _atBottomThreshold;
    if (atBottom) {
      _chatCubit.syncScrollAtBottom(_layoutMessageCount);
    }
  }

  void _scrollToNewMessages() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _chatCubit.scrollToNewMessagesConsumed(_layoutMessageCount);
  }

  Future<void> _initChat() async {
    final authRepo = sl<AuthRepository>();
    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      if (mounted) _chatCubit.setError('Not signed in');
      return;
    }

    try {
      await sl<ChatUserRepository>().ensureChatUser(currentUser);

      if (widget.chatId != null && widget.chatId!.isNotEmpty) {
        _chatCubit.setChatSession(resolvedChatId: widget.chatId!);
        unawaited(
          sl<ConversationRepository>().markChatAsRead(
            widget.chatId!,
            currentUser.id,
          ),
        );
        final other = await sl<ConversationRepository>().getOtherParticipant(
          widget.chatId!,
          currentUser.id,
        );
        if (mounted && other != null) {
          final otherUser = await sl<UserRepository>().getUser(
            other.otherUserId,
          );
          _chatCubit.setChatSession(
            resolvedChatId: widget.chatId!,
            otherUserId: other.otherUserId,
            otherUserRole: otherUser?.role,
            otherUserName: _displayNameFor(otherUser, other.displayName),
            otherUserPhotoUrl: otherUser?.photoUrl,
          );
        }
      } else if (widget.otherUserId != null && widget.otherUserId!.isNotEmpty) {
        final otherUser = await sl<UserRepository>().getUser(
          widget.otherUserId!,
        );
        if (otherUser != null) {
          await sl<ChatUserRepository>().ensureChatUser(otherUser);
        } else {
          await sl<ChatUserRepository>().ensureChatUserById(
            widget.otherUserId!,
          );
        }
        final resolvedId = await sl<ConversationRepository>()
            .getOrCreateOneToOneChat(currentUser.id, widget.otherUserId!);
        if (mounted) {
          _chatCubit.setChatSession(
            resolvedChatId: resolvedId,
            otherUserId: widget.otherUserId,
            otherUserRole: otherUser?.role,
            otherUserName: _displayNameFor(otherUser, widget.otherUserId!),
            otherUserPhotoUrl: otherUser?.photoUrl,
          );
        }
        unawaited(
          sl<ConversationRepository>().markChatAsRead(
            resolvedId,
            currentUser.id,
          ),
        );
      } else {
        if (mounted) _chatCubit.setError('Missing chat or user');
        return;
      }
    } catch (e, st) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('restricted') || msg.contains('who can message')) {
          showToast(
            context,
            'This user has restricted who can message them',
            isError: true,
          );
          context.pop();
          return;
        }
        _chatCubit.setError(e);
        debugPrint('Chat init error: $e $st');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatPageCubit>.value(
      value: _chatCubit,
      child: BlocBuilder<ChatPageCubit, ChatPageState>(
        builder: (context, chatState) {
          if (chatState.error != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Chat')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to open chat: ${chatState.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final chatId = chatState.resolvedChatId;
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
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLowest
                          .withValues(alpha: 0.3),
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
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.messages),
                ),
                title: Text(chatState.otherUserName),
              ),
              body: const Center(child: Text('Not signed in')),
            );
          }

          final messagesStream = sl<ConversationRepository>().watchMessages(
            chatId,
          );
          final colorScheme = Theme.of(context).colorScheme;
          final theme = Theme.of(context);

          return StreamBuilder<List<MessageEntity>>(
            stream: messagesStream,
            builder: (context, snapshot) {
              final showAppBarSkeleton = !snapshot.hasData;
              return Scaffold(
                appBar: AppBar(
                  leading: BackButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.messages),
                  ),
                  toolbarHeight: 92,
                  title: showAppBarSkeleton
                      ? const ChatAppBarSkeleton()
                      : _buildAppBarTitle(colorScheme, theme, chatState),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: colorScheme.surfaceContainerLowest.withValues(
                          alpha: 0.3,
                        ),
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
        },
      ),
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
          if (context.mounted) {
            context.read<ChatPageCubit>().bumpStreamRefresh();
          }
        },
        onBack: () => context.pop(),
        child: const ChatMessagesSkeleton(),
      );
    }
    if (!snapshot.hasData) {
      return const ChatMessagesSkeleton();
    }
    final messages = snapshot.data!;
    _layoutMessageCount = messages.length;
    _chatCubit.afterMessagesLayout(
      scrollController: _scrollController,
      messageCount: messages.length,
      atBottomThreshold: _atBottomThreshold,
    );
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
    return BlocBuilder<ChatPageCubit, ChatPageState>(
      buildWhen: (prev, curr) =>
          prev.showNewMessagesBanner != curr.showNewMessagesBanner,
      builder: (context, bannerState) {
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: AppBorders.borderRadius,
                        ),
                        child: Text(
                          _formatDateHeader(
                            messages.isNotEmpty
                                ? messages.last.createdAt
                                : DateTime.now(),
                          ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
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
                return MessageBubble(message: message, isSentByMe: isSentByMe);
              },
            ),
            if (bannerState.showNewMessagesBanner)
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
      },
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
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[t.weekday - 1];
    }
    return '${t.day}/${t.month}/${t.year}';
  }
}
