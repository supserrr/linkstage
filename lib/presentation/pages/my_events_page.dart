import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../widgets/atoms/glass_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_borders.dart';
import '../bloc/my_events/my_events_cubit.dart';
import '../bloc/my_events/my_events_state.dart';
import '../bloc/my_events/planner_collaborations_tab_cubit.dart';
import '../bloc/my_events/planner_collaborations_tab_state.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/event_date_utils.dart';
import '../../core/utils/event_location_utils.dart';
import '../../core/utils/number_formatter.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/router/auth_redirect.dart';
import '../../domain/entities/collaboration_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../widgets/molecules/empty_state_illustrated.dart';
import '../widgets/molecules/profile_avatar.dart';
import '../widgets/molecules/connection_error_overlay.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/molecules/skeleton_loaders.dart';

/// Events list for event planners.
class MyEventsPage extends StatelessWidget {
  const MyEventsPage({super.key, this.myEventsCubit});

  /// Optional injected cubit (primarily for deterministic widget tests).
  /// When null, the page creates the default sl-backed [MyEventsCubit].
  final MyEventsCubit? myEventsCubit;

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.stretchedDots(
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
        ),
      );
    }
    final child = DefaultTabController(
      length: 2,
      child: _MyEventsView(plannerId: user.id),
    );

    if (myEventsCubit != null) {
      return BlocProvider<MyEventsCubit>.value(value: myEventsCubit!, child: child);
    }

    return BlocProvider(
      create: (_) => MyEventsCubit(
        sl<EventRepository>(),
        sl<BookingRepository>(),
        sl<CollaborationRepository>(),
        user.id,
      ),
      child: child,
    );
  }
}

class _MyEventsView extends StatelessWidget {
  const _MyEventsView({required this.plannerId});

  final String plannerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Events'),
            Tab(text: 'Collaborations'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push<bool?>(AppRoutes.createEvent),
            tooltip: 'Create event',
          ),
        ],
      ),
      body: TabBarView(
        children: [
          BlocBuilder<MyEventsCubit, MyEventsState>(
            builder: (context, state) {
              if (state.isLoading &&
                  state.events.isEmpty &&
                  state.error == null) {
                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => const EventCardSkeleton(),
                );
              }
              if (state.events.isEmpty && state.error == null) {
                return EmptyStateIllustrated(
                  assetPathDark: 'assets/images/no_events_empty_dark.svg',
                  assetPathLight: 'assets/images/no_events_empty_light.svg',
                  headline: "No events yet? Let's create your first one!",
                  description:
                      'Create events to find and book creatives for your next occasion.',
                  primaryLabel: 'Create event',
                  onPrimaryPressed: () =>
                      context.push<bool?>(AppRoutes.createEvent),
                );
              }
              final upcoming =
                  state.events.where(EventDateUtils.isUpcomingEvent).toList()
                    ..sort((a, b) {
                      final da = a.date ?? DateTime(0);
                      final db = b.date ?? DateTime(0);
                      return da.compareTo(db);
                    });
              final past =
                  state.events.where(EventDateUtils.isPastEvent).toList()
                    ..sort((a, b) {
                      final da = a.date ?? DateTime(0);
                      final db = b.date ?? DateTime(0);
                      return db.compareTo(da);
                    });
              final body = state.events.isEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: 6,
                      itemBuilder: (context, index) =>
                          const EventCardSkeleton(),
                    )
                  : _buildEventsSections(
                      context,
                      upcoming: upcoming,
                      past: past,
                      pendingCountByEventId: state.pendingCountByEventId,
                    );
              return ConnectionErrorOverlay(
                hasError: state.error != null,
                error: state.error,
                onRefresh: () async => context.read<MyEventsCubit>().load(),
                onBack: () => context.go(AppRoutes.home),
                child: body,
              );
            },
          ),
          _PlannerCollaborationsTabContent(plannerId: plannerId),
        ],
      ),
    );
  }
}

Widget _buildEventsSections(
  BuildContext context, {
  required List<EventEntity> upcoming,
  required List<EventEntity> past,
  required Map<String, int> pendingCountByEventId,
}) {
  const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.9,
  );
  final slivers = <Widget>[];
  if (upcoming.isNotEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Upcoming',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildBuilderDelegate((context, index) {
            final event = upcoming[index];
            return _EventCard(
              event: event,
              applicantCount: pendingCountByEventId[event.id] ?? 0,
              onTap: () => context.push(AppRoutes.eventDetail(event.id)),
              onDelete: () => _confirmDeleteEvent(context, event.id),
            );
          }, childCount: upcoming.length),
        ),
      ),
    );
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
  }
  if (past.isNotEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Past',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildBuilderDelegate((context, index) {
            final event = past[index];
            return _EventCard(
              event: event,
              applicantCount: pendingCountByEventId[event.id] ?? 0,
              onTap: () => context.push(AppRoutes.eventDetail(event.id)),
              onDelete: () => _confirmDeleteEvent(context, event.id),
            );
          }, childCount: past.length),
        ),
      ),
    );
  }
  return CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      const SliverPadding(padding: EdgeInsets.only(top: 16)),
      ...slivers,
      const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
    ],
  );
}

class _PlannerCollaborationsTabContent extends StatelessWidget {
  const _PlannerCollaborationsTabContent({required this.plannerId});

  final String plannerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final c = PlannerCollaborationsTabCubit(
          sl<CollaborationRepository>(),
          sl<UserRepository>(),
        );
        Future.microtask(() => c.load(plannerId));
        return c;
      },
      child:
          BlocBuilder<
            PlannerCollaborationsTabCubit,
            PlannerCollaborationsTabState
          >(
            builder: (context, state) {
              return _plannerCollaborationsTabBody(context, state, plannerId);
            },
          ),
    );
  }
}

Widget _plannerCollaborationsSkeletonList() => ListView.builder(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
  physics: const AlwaysScrollableScrollPhysics(),
  itemCount: 5,
  itemBuilder: (context, index) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: CollaborationProposalTileSkeleton(margin: EdgeInsets.zero),
  ),
);

Widget _plannerCollaborationsSections(
  BuildContext context, {
  required List<CollaborationEntity> active,
  required List<CollaborationEntity> past,
  required Map<String, String> targetNames,
  required Map<String, String?> targetPhotoUrls,
}) {
  final slivers = <Widget>[];
  if (active.isNotEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Active',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
    slivers.add(
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final c = active[index];
          final targetName = targetNames[c.targetUserId] ?? 'Creative';
          final targetPhotoUrl = targetPhotoUrls[c.targetUserId];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SentCollaborationTile(
              collaboration: c,
              targetName: targetName,
              targetPhotoUrl: targetPhotoUrl,
              onMessage: c.status == CollaborationStatus.accepted
                  ? () => context.go(AppRoutes.chatWithUser(c.targetUserId))
                  : null,
              onViewMore: () => context.push(
                AppRoutes.collaborationDetail,
                extra: {
                  'collaboration': c,
                  'otherPersonName': targetName,
                  'otherPersonId': c.targetUserId,
                  'otherPersonRole': UserRole.creativeProfessional,
                  'viewerIsCreative': false,
                  'otherPersonPhotoUrl': targetPhotoUrl,
                },
              ),
            ),
          );
        }, childCount: active.length),
      ),
    );
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
  }
  if (past.isNotEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Past',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
    slivers.add(
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final c = past[index];
          final targetName = targetNames[c.targetUserId] ?? 'Creative';
          final targetPhotoUrl = targetPhotoUrls[c.targetUserId];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SentCollaborationTile(
              collaboration: c,
              targetName: targetName,
              targetPhotoUrl: targetPhotoUrl,
              onMessage: null,
              onViewMore: () => context.push(
                AppRoutes.collaborationDetail,
                extra: {
                  'collaboration': c,
                  'otherPersonName': targetName,
                  'otherPersonId': c.targetUserId,
                  'otherPersonRole': UserRole.creativeProfessional,
                  'viewerIsCreative': false,
                  'otherPersonPhotoUrl': targetPhotoUrl,
                },
              ),
            ),
          );
        }, childCount: past.length),
      ),
    );
  }
  return CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      const SliverPadding(padding: EdgeInsets.only(top: 16)),
      ...slivers,
      const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
    ],
  );
}

Widget _plannerCollaborationsTabBody(
  BuildContext context,
  PlannerCollaborationsTabState state,
  String plannerId,
) {
  if (state.loading && state.collaborations.isEmpty && state.error == null) {
    return _plannerCollaborationsSkeletonList();
  }
  final active = state.collaborations
      .where(
        (c) =>
            c.status == CollaborationStatus.pending ||
            c.status == CollaborationStatus.accepted,
      )
      .toList();
  final past =
      state.collaborations
          .where((c) => c.status == CollaborationStatus.completed)
          .toList()
        ..sort((a, b) {
          final da = a.createdAt ?? DateTime(0);
          final db = b.createdAt ?? DateTime(0);
          return db.compareTo(da);
        });
  final hasAny = active.isNotEmpty || past.isNotEmpty;
  if (!hasAny && state.error == null) {
    return EmptyStateIllustrated(
      assetPathDark: 'assets/images/no_events_empty_dark.svg',
      assetPathLight: 'assets/images/no_events_empty_light.svg',
      headline: 'No proposals sent yet',
      description:
          "Visit a creative's profile and tap Collaborate to send a proposal.",
      primaryLabel: 'Browse creatives',
      onPrimaryPressed: () => context.go(AppRoutes.explore),
    );
  }
  final body = !hasAny
      ? _plannerCollaborationsSkeletonList()
      : _plannerCollaborationsSections(
          context,
          active: active,
          past: past,
          targetNames: state.targetNames,
          targetPhotoUrls: state.targetPhotoUrls,
        );
  return ConnectionErrorOverlay(
    hasError: state.error != null,
    error: state.error,
    onRefresh: () async =>
        context.read<PlannerCollaborationsTabCubit>().load(plannerId),
    onBack: () => context.go(AppRoutes.home),
    child: body,
  );
}

class _SentCollaborationTile extends StatelessWidget {
  const _SentCollaborationTile({
    required this.collaboration,
    required this.targetName,
    this.targetPhotoUrl,
    this.onMessage,
    required this.onViewMore,
  });

  final CollaborationEntity collaboration;
  final String targetName;
  final String? targetPhotoUrl;
  final VoidCallback? onMessage;
  final VoidCallback onViewMore;

  static String _relativeDateText(DateTime? d) {
    if (d == null) return 'Sent';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final then = DateTime(d.year, d.month, d.day);
    final diff = today.difference(then).inDays;
    if (diff == 0) return 'Sent today';
    if (diff == 1) return 'Sent yesterday';
    if (diff < 7) return 'Sent $diff days ago';
    if (diff < 30) return 'Sent ${(diff / 7).floor()} weeks ago';
    if (diff < 365) return 'Sent ${(diff / 30).floor()} months ago';
    return 'Sent ${(diff / 365).floor()} years ago';
  }

  static String _shortDate(DateTime? d) {
    if (d == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  static String _statusLabel(CollaborationStatus s) {
    switch (s) {
      case CollaborationStatus.pending:
        return 'Pending';
      case CollaborationStatus.accepted:
        return 'Accepted';
      case CollaborationStatus.declined:
        return 'Declined';
      case CollaborationStatus.completed:
        return 'Completed';
    }
  }

  String? _contextLine() {
    final hasType =
        collaboration.eventType != null && collaboration.eventType!.isNotEmpty;
    final hasDate = collaboration.date != null;
    if (hasType && hasDate) {
      return '${collaboration.eventType} · ${_shortDate(collaboration.date)}';
    }
    if (hasType) return collaboration.eventType;
    if (hasDate) return _shortDate(collaboration.date);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sentStr = _relativeDateText(collaboration.createdAt);
    final contextLine = _contextLine();
    final status = collaboration.status;
    final isPending = status == CollaborationStatus.pending;
    final isAccepted = status == CollaborationStatus.accepted;

    const padding = 16.0;
    const gap = 12.0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(padding),
      child: InkWell(
        onTap: onViewMore,
        borderRadius: AppBorders.borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  photoUrl: targetPhotoUrl,
                  displayName: targetName,
                  radius: 22,
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contextLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          contextLine,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: gap),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? colorScheme.primaryContainer
                        : isPending
                        ? colorScheme.tertiaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isAccepted
                          ? colorScheme.onPrimaryContainer
                          : isPending
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: gap),
            Text(
              sentStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: gap),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(height: gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onViewMore,
                  child: const Text('View details'),
                ),
                if (onMessage != null)
                  FilledButton.tonal(
                    onPressed: onMessage,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text('Message'),
                  )
                else if (isPending)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Awaiting response',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteEvent(BuildContext context, String eventId) async {
  final theme = Theme.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Event'),
      content: const Text(
        'Are you sure you want to delete this event? This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    try {
      await context.read<MyEventsCubit>().delete(eventId);
      if (context.mounted) {
        showToast(context, 'Event deleted');
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Failed to delete: $e', isError: true);
      }
    }
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.applicantCount,
    required this.onTap,
    this.onDelete,
  });

  final EventEntity event;
  final int applicantCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  String _statusLabel(EventStatus s) {
    return s == EventStatus.open ? 'Open' : 'Closed';
  }

  bool _isPublished(EventStatus s) {
    return s != EventStatus.draft;
  }

  String _daysLeftText(DateTime? date) {
    if (date == null) return 'No date set';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final diff = eventDay.difference(today).inDays;
    if (diff < 0) return '${NumberFormatter.formatInteger(-diff)} days ago';
    if (diff == 0) return 'Today';
    if (diff == 1) return '1 day left';
    return '${NumberFormatter.formatInteger(diff)} days left';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = event.date != null
        ? '${event.date!.month}/${event.date!.day}/${event.date!.year}'
        : '—';
    final location = getEventLocationDisplayLine(
      event,
      isPlanner: true,
      hasAcceptedBooking: false,
    );
    final daysLeft = _daysLeftText(event.date);

    return GlassCard(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppBorders.radius),
                    ),
                  ),
                  child: event.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppBorders.radius),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: event.imageUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Icon(
                          Icons.event,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
                Positioned(
                  top: 4,
                  left: 6,
                  right: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.95,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppBorders.radius,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isPublished(event.status)
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _statusLabel(event.status),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: onDelete,
                          tooltip: 'Delete event',
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                            backgroundColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          daysLeft,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '$dateStr \u2022 $location',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        applicantCount == 1
                            ? '1 applicant'
                            : '${NumberFormatter.formatInteger(applicantCount)} applicants',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
