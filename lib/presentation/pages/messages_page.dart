import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_borders.dart';
import '../../core/constants/app_icons.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_user_repository.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../widgets/molecules/app_filter_chip.dart';
import '../widgets/molecules/connection_error_overlay.dart';
import '../widgets/molecules/empty_state_illustrated.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/molecules/skeleton_loaders.dart';
import '../widgets/molecules/conversation_list_item.dart';

/// Chat list: conversations for the current user (custom UI, no chatview).
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

enum _ChatFilter { all, unread, favorites }

class _MessagesPageState extends State<MessagesPage> {
  bool _chatUserSynced = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  _ChatFilter _filter = _ChatFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static bool _matchesSearch(ConversationEntity c, String q) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    final name = c.otherUserDisplayName?.toLowerCase() ?? '';
    final id = c.otherUserId.toLowerCase();
    return name.contains(lower) || id.contains(lower);
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();
    final currentUser = authRepo.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Sign in to view conversations')),
      );
    }

    if (!_chatUserSynced) {
      _chatUserSynced = true;
      unawaited(
        sl<ChatUserRepository>().ensureChatUser(currentUser).then((_) {}),
      );
    }

    final stream = sl<ConversationRepository>().watchConversations(
      currentUser.id,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.go(AppRoutes.explore),
            tooltip: 'New conversation',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: Icon(
                  AppIcons.search,
                  size: 22,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppBorders.borderRadius,
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorders.borderRadius,
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorders.borderRadius,
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchFocusNode.unfocus(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                AppFilterChip(
                  label: 'All',
                  selected: _filter == _ChatFilter.all,
                  onTap: () => setState(() => _filter = _ChatFilter.all),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Unread',
                  selected: _filter == _ChatFilter.unread,
                  onTap: () => setState(() => _filter = _ChatFilter.unread),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Favorites',
                  selected: _filter == _ChatFilter.favorites,
                  onTap: () => setState(() => _filter = _ChatFilter.favorites),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomMaterialIndicator(
              onRefresh: () async {
                if (mounted) setState(() {});
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              useMaterialContainer: false,
              indicatorBuilder: (context, controller) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: LoadingAnimationWidget.threeRotatingDots(
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),
              child: StreamBuilder<List<ConversationEntity>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ConnectionErrorOverlay(
                      hasError: true,
                      error: snapshot.error,
                      onRefresh: () async {
                        if (mounted) setState(() {});
                      },
                      onBack: () => context.go(AppRoutes.home),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: 8,
                        itemBuilder: (context, index) =>
                            const ConversationItemSkeleton(),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return ListView.builder(
                      itemCount: 8,
                      itemBuilder: (context, index) =>
                          const ConversationItemSkeleton(),
                    );
                  }
                  var list = snapshot.data!
                      .where((c) => _matchesSearch(c, _searchQuery))
                      .toList();
                  if (_filter == _ChatFilter.unread) {
                    list = list.where((c) => c.unreadCount > 0).toList();
                  }
                  list.sort((a, b) {
                    final at = b.lastMessageAt ?? b.createdAt ?? DateTime(0);
                    final bt = a.lastMessageAt ?? a.createdAt ?? DateTime(0);
                    return at.compareTo(bt);
                  });
                  if (list.isEmpty) {
                    return _searchQuery.isNotEmpty
                        ? _buildNoResults(context)
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.sizeOf(context).height - 220,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: EmptyStateIllustrated(
                                  assetPathDark:
                                      'assets/images/no_chats_empty_dark.svg',
                                  assetPathLight:
                                      'assets/images/no_chats_empty_light.svg',
                                  headline:
                                      "No conversations yet — let's find someone to connect with!",
                                  description:
                                      'Search for creatives or planners and start a conversation.',
                                  primaryLabel: 'Search',
                                  onPrimaryPressed: () =>
                                      context.go(AppRoutes.explore),
                                  illustrationHeight: 200,
                                ),
                              ),
                            ),
                          );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final conversation = list[index];
                      return ConversationListItem(
                        conversation: conversation,
                        showDivider: true,
                        onTap: () =>
                            context.push(AppRoutes.chat(conversation.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.search,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations match your search',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
