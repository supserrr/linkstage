import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:go_router/go_router.dart';

import '../atoms/glass_card.dart';
import '../../../core/constants/app_borders.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/event_location_utils.dart';
import '../molecules/connection_error_overlay.dart';
import '../molecules/empty_state_dotted.dart';
import '../molecules/skeleton_loaders.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/event_entity.dart';
import '../../bloc/planner_dashboard/planner_dashboard_cubit.dart';
import '../../bloc/planner_dashboard/planner_dashboard_state.dart';
import '../../bloc/unread_notifications/unread_notifications_cubit.dart';
import '../../bloc/unread_notifications/unread_notifications_state.dart';

/// Dashboard content for event planner home: header, Post a Gig CTA,
/// summary cards, Your Events, Recent Activity.
class PlannerDashboardContent extends StatelessWidget {
  const PlannerDashboardContent({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlannerDashboardCubit, PlannerDashboardState>(
      builder: (context, state) {
        if (state.isLoading &&
            state.events.isEmpty &&
            state.recentActivities.isEmpty &&
            state.error == null) {
          return const PlannerDashboardSkeleton();
        }
        final cubit = context.read<PlannerDashboardCubit>();
        final body = state.error != null
            ? const PlannerDashboardSkeleton()
            : CustomMaterialIndicator(
                onRefresh: () async => cubit.load(),
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
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<
                        UnreadNotificationsCubit,
                        UnreadNotificationsState
                      >(
                        builder: (context, unreadState) => _DashboardHeader(
                          displayName: displayName,
                          notificationCount: unreadState.unreadCount,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PostAGigCard(
                        onTap: () => context.push<bool?>(AppRoutes.createEvent),
                      ),
                      const SizedBox(height: 20),
                      _UnifiedSummaryCard(
                        applicantsCount: state.applicantsCount,
                        eventsCount: state.eventsCount,
                        unreadCount: state.unreadCount,
                      ),
                      const SizedBox(height: 24),
                      _YourEventsSection(
                        events: state.events
                            .where((e) => e.status == EventStatus.open)
                            .toList(),
                        pendingCountByEventId: state.pendingCountByEventId,
                        onViewAll: () => context.go(AppRoutes.bookings),
                      ),
                      const SizedBox(height: 24),
                      _RecentActivitySection(
                        activities: state.recentActivities,
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              );
        return ConnectionErrorOverlay(
          hasError: state.error != null,
          error: state.error,
          onRefresh: () async => cubit.load(),
          onBack: null,
          child: body,
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.displayName,
    required this.notificationCount,
  });

  final String displayName;
  final int notificationCount;

  static const List<String> _weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  static const List<String> _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateText =
        '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, $displayName',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(10),
            child: InkWell(
              onTap: () => context.go(AppRoutes.notifications),
              borderRadius: AppBorders.borderRadius,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    AppIcons.notifications,
                    size: 24,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        padding: notificationCount == 1
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        constraints: BoxConstraints(
                          minWidth: notificationCount == 1 ? 8 : 18,
                          minHeight: notificationCount == 1 ? 8 : 18,
                        ),
                        child: notificationCount == 1
                            ? null
                            : Center(
                                child: Text(
                                  notificationCount > 99
                                      ? '99+'
                                      : '$notificationCount',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onError,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAGigCard extends StatelessWidget {
  const _PostAGigCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorders.borderRadius,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Post a Gig',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find talent for your event.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(12),
                minimumSize: const Size(48, 48),
                shape: const CircleBorder(),
              ),
              child: const Icon(AppIcons.add, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedSummaryCard extends StatelessWidget {
  const _UnifiedSummaryCard({
    required this.applicantsCount,
    required this.eventsCount,
    required this.unreadCount,
  });

  final int applicantsCount;
  final int eventsCount;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _PlannerStatTile(
              icon: AppIcons.applicants,
              value: applicantsCount,
              label: 'Applicants',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _PlannerStatTile(
              icon: AppIcons.event,
              value: eventsCount,
              label: 'Events',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _PlannerStatTile(
              icon: AppIcons.unread,
              value: unreadCount,
              label: 'Unread',
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerStatTile extends StatelessWidget {
  const _PlannerStatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _YourEventsSection extends StatelessWidget {
  const _YourEventsSection({
    required this.events,
    required this.pendingCountByEventId,
    required this.onViewAll,
  });

  final List<EventEntity> events;
  final Map<String, int> pendingCountByEventId;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your active events',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: events.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EmptyStateDotted(
                      icon: AppIcons.event,
                      headline: 'No active events',
                      description:
                          'Post a gig to get proposals from creatives.',
                      compact: true,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final newCount = pendingCountByEventId[event.id] ?? 0;
                    return _StageCard(
                      event: event,
                      newCount: newCount,
                      onTap: () =>
                          context.push(AppRoutes.eventDetail(event.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.event,
    required this.newCount,
    required this.onTap,
  });

  final EventEntity event;
  final int newCount;
  final VoidCallback onTap;

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
    if (diff < 0) return '${-diff} days ago';
    if (diff == 0) return 'Today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
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

    return SizedBox(
      width: 180,
      height: 200,
      child: GlassCard(
        width: 180,
        height: 200,
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
                            AppIcons.event,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                  Positioned(
                    top: 14,
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
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          AppIcons.date,
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          AppIcons.location,
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          AppIcons.applicants,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          newCount == 1
                              ? '1 applicant'
                              : '$newCount applicants',
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
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.activities});

  final List<PlannerDashboardActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: EmptyStateDotted(
                  icon: AppIcons.proposal,
                  headline: 'No proposals yet',
                  description: 'Proposals from creatives will appear here.',
                  compact: true,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = activities[index];
              return _ActivityTile(
                creativeName: a.creativeName,
                eventTitle: a.eventTitle,
                createdAt: a.createdAt,
              );
            },
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.creativeName,
    required this.eventTitle,
    required this.createdAt,
  });

  final String creativeName;
  final String eventTitle;
  final DateTime createdAt;

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dateTime.month}/${dateTime.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.proposal, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$creativeName sent a proposal for $eventTitle',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                _timeAgo(createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
