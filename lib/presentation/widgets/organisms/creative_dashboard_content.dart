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
import '../../../core/utils/firestore_error_utils.dart';
import '../molecules/connection_error_overlay.dart';
import '../molecules/empty_state_dotted.dart';
import '../molecules/skeleton_loaders.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../bloc/creative_dashboard/creative_dashboard_cubit.dart';
import '../../bloc/creative_dashboard/creative_dashboard_state.dart';
import '../../bloc/unread_notifications/unread_notifications_cubit.dart';
import '../../bloc/unread_notifications/unread_notifications_state.dart';
import '../molecules/vendor_card.dart';

/// Home dashboard content for creatives: header (date, greeting, notifications),
/// search, filters, Recent events, Saved, and For: [Role] with Update Profile.
class CreativeDashboardContent extends StatelessWidget {
  const CreativeDashboardContent({super.key, required this.displayName});

  final String displayName;

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
    return BlocBuilder<CreativeDashboardCubit, CreativeDashboardState>(
      builder: (context, state) {
        if (state.isLoading && state.profile == null && state.error == null) {
          return const CreativeDashboardSkeleton();
        }
        final cubit = context.read<CreativeDashboardCubit>();
        final body = state.error != null
            ? _CreativeDashboardErrorState(
                error: state.error!,
                onRetry: () => cubit.load(),
              )
            : _buildRefreshIndicator(
                context: context,
                onRefresh: () => cubit.load(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                  child: _buildDashboardContent(context, state, displayName),
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

  Widget _buildRefreshIndicator({
    required BuildContext context,
    required Future<void> Function() onRefresh,
    required Widget child,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return CustomMaterialIndicator(
      onRefresh: onRefresh,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useMaterialContainer: false,
      indicatorBuilder: (context, controller) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: LoadingAnimationWidget.threeRotatingDots(color: color, size: 40),
      ),
      child: child,
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    CreativeDashboardState state,
    String displayName,
  ) {
    final name = state.displayName.isNotEmpty ? state.displayName : displayName;
    final now = DateTime.now();
    final dateText =
        '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hello, $name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<UnreadNotificationsCubit, UnreadNotificationsState>(
              builder: (context, unreadState) =>
                  _NotificationIcon(count: unreadState.unreadCount),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FindGigsCard(onTap: () => context.go(AppRoutes.explore)),
        const SizedBox(height: 20),
        _UnifiedStatsCard(
          savedCount: state.savedEventIds.length,
          gigsCount: state.gigsCount,
          followedCount: state.followedPlannersCount,
          onFollowingTap: () => context.push(AppRoutes.following),
        ),
        const SizedBox(height: 24),
        _RecentSection(
          filter: CreativeHomeFilter.events,
          openEvents: state.openEvents,
          fellowCreatives: state.fellowCreatives,
          pendingCountByEventId: state.pendingCountByEventId,
          savedEventIds: state.savedEventIds,
          acceptedEventIds: state.acceptedEventIds,
          onToggleSaved: (id) =>
              context.read<CreativeDashboardCubit>().toggleSavedEvent(id),
        ),
        const SizedBox(height: 24),
        _SavedSection(
          filter: CreativeHomeFilter.events,
          savedEventIds: state.savedEventIds,
          savedEvents: state.savedEvents,
          savedCreativeIds: state.savedCreativeIds,
          savedCreatives: state.savedCreatives,
          openEvents: state.openEvents,
          acceptedEventIds: state.acceptedEventIds,
          onToggleSaved: (id) =>
              context.read<CreativeDashboardCubit>().toggleSavedEvent(id),
          onToggleSavedCreative: (id) =>
              context.read<CreativeDashboardCubit>().toggleSavedCreative(id),
        ),
        const SizedBox(height: 24),
        _ForRoleSection(
          roleLabel: state.roleLabel,
          filter: CreativeHomeFilter.events,
          recommendedForYouEvents: state.recommendedForYouEvents,
          pendingCountByEventId: state.pendingCountByEventId,
          savedEventIds: state.savedEventIds,
          acceptedEventIds: state.acceptedEventIds,
          onToggleSaved: (id) =>
              context.read<CreativeDashboardCubit>().toggleSavedEvent(id),
        ),
        const SizedBox(height: 36),
      ],
    );
  }
}

class _CreativeDashboardErrorState extends StatelessWidget {
  const _CreativeDashboardErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load dashboard',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  firestoreErrorMessage(error),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GlassCard(
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
              color: colorScheme.onPrimaryContainer,
            ),
            if (count > 0)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  padding: count == 1
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 1.5),
                  ),
                  constraints: BoxConstraints(
                    minWidth: count == 1 ? 8 : 18,
                    minHeight: count == 1 ? 8 : 18,
                  ),
                  child: count == 1
                      ? null
                      : Center(
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onError,
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
    );
  }
}

class _FindGigsCard extends StatelessWidget {
  const _FindGigsCard({required this.onTap});

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
                    'Find Gigs',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse events that need you.',
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
              child: const Icon(AppIcons.search, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedStatsCard extends StatelessWidget {
  const _UnifiedStatsCard({
    required this.savedCount,
    required this.gigsCount,
    required this.followedCount,
    this.onFollowingTap,
  });

  final int savedCount;
  final int gigsCount;
  final int followedCount;
  final VoidCallback? onFollowingTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: AppIcons.savedOutline,
              value: savedCount,
              label: 'Saved',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _StatTile(
              icon: AppIcons.gigs,
              value: gigsCount,
              label: 'Gigs',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _StatTile(
              icon: AppIcons.person,
              value: followedCount,
              label: 'Following',
              onTap: onFollowingTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final content = Column(
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
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppBorders.borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: content,
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.filter,
    required this.openEvents,
    required this.fellowCreatives,
    required this.pendingCountByEventId,
    required this.savedEventIds,
    required this.acceptedEventIds,
    required this.onToggleSaved,
  });

  final CreativeHomeFilter filter;
  final List<EventEntity> openEvents;
  final List<ProfileEntity> fellowCreatives;
  final Map<String, int> pendingCountByEventId;
  final Set<String> savedEventIds;
  final Set<String> acceptedEventIds;
  final void Function(String eventId) onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEvents = filter == CreativeHomeFilter.events;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEvents ? 'Recent events' : 'Recent creatives',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.explore),
              child: const Text('All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: isEvents
              ? (openEvents.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: EmptyStateDotted(
                            icon: AppIcons.event,
                            headline: 'No open events right now',
                            compact: true,
                            primaryLabel: 'Explore',
                            onPrimaryPressed: () =>
                                context.go(AppRoutes.explore),
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: openEvents.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final event = openEvents[index];
                          return _CreativeEventCard(
                            event: event,
                            applicantCount:
                                pendingCountByEventId[event.id] ?? 0,
                            isSaved: savedEventIds.contains(event.id),
                            hasAcceptedBooking: acceptedEventIds.contains(
                              event.id,
                            ),
                            onTap: () =>
                                context.push(AppRoutes.eventDetail(event.id)),
                            onSaveTap: () => onToggleSaved(event.id),
                          );
                        },
                      ))
              : (fellowCreatives.isEmpty
                    ? ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _RecommendedCard(
                            title: 'Explore creatives',
                            subtitle: 'Find talent for your next gig',
                            tag: 'Discover',
                            onTap: () => context.go(AppRoutes.explore),
                          ),
                          const SizedBox(width: 12),
                          _RecommendedCard(
                            title: 'Build your profile',
                            subtitle: 'Stand out to planners',
                            tag: 'Profile',
                            onTap: () => context.push(AppRoutes.viewProfile),
                          ),
                        ],
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: fellowCreatives.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final profile = fellowCreatives[index];
                          return SizedBox(
                            width: 280,
                            child: VendorCard(
                              profile: profile,
                              onTap: () => context.push(
                                AppRoutes.creativeProfileView(profile.userId),
                              ),
                            ),
                          );
                        },
                      )),
        ),
      ],
    );
  }
}

class _CreativeEventCard extends StatelessWidget {
  const _CreativeEventCard({
    required this.event,
    required this.isSaved,
    required this.hasAcceptedBooking,
    required this.onTap,
    required this.onSaveTap,
    this.applicantCount = 0,
  });

  final EventEntity event;
  final bool isSaved;
  final bool hasAcceptedBooking;
  final VoidCallback onTap;
  final VoidCallback onSaveTap;
  final int applicantCount;

  static String _daysLeftText(DateTime? date) {
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
    final location = getEventLocationDisplayLine(
      event,
      isPlanner: false,
      hasAcceptedBooking: hasAcceptedBooking,
    );
    final daysLeft = _daysLeftText(event.date);

    return SizedBox(
      width: 180,
      height: 200,
      child: GlassCard(
        width: 180,
        height: 200,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                InkWell(
                  onTap: onTap,
                  child: Container(
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
                                  color: event.status == EventStatus.open
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                event.status == EventStatus.open
                                    ? 'Open'
                                    : 'Closed',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: onSaveTap,
                          borderRadius: AppBorders.borderRadius,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isSaved
                                  ? AppIcons.savedFilled
                                  : AppIcons.savedOutline,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onTap,
              child: Padding(
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
                            location,
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
                          applicantCount == 1
                              ? '1 applicant'
                              : '$applicantCount applicants',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: 280,
      child: GlassCard(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.8),
                    borderRadius: AppBorders.borderRadius,
                  ),
                  child: Text(
                    tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedSection extends StatelessWidget {
  const _SavedSection({
    required this.filter,
    required this.savedEventIds,
    required this.savedEvents,
    required this.savedCreativeIds,
    required this.savedCreatives,
    required this.openEvents,
    required this.acceptedEventIds,
    required this.onToggleSaved,
    required this.onToggleSavedCreative,
  });

  final CreativeHomeFilter filter;
  final Set<String> savedEventIds;
  final List<EventEntity> savedEvents;
  final Set<String> savedCreativeIds;
  final List<ProfileEntity> savedCreatives;
  final List<EventEntity> openEvents;
  final Set<String> acceptedEventIds;
  final void Function(String eventId) onToggleSaved;
  final void Function(String creativeUserId) onToggleSavedCreative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEvents = filter == CreativeHomeFilter.events;
    if (isEvents) {
      final openSaved = openEvents
          .where((e) => savedEventIds.contains(e.id))
          .toList();
      final combined = <EventEntity>[
        ...savedEvents,
        ...openSaved.where((e) => !savedEvents.any((s) => s.id == e.id)),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved events',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (combined.isEmpty)
            EmptyStateDotted(
              icon: AppIcons.savedOutline,
              headline: 'No saved events yet',
              description:
                  'Save events you\'re interested in to find them here.',
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: combined
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SavedEventTile(
                        event: e,
                        hasAcceptedBooking: acceptedEventIds.contains(e.id),
                        onTap: () => context.push(AppRoutes.eventDetail(e.id)),
                        onUnsave: () => onToggleSaved(e.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved creatives',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (savedCreatives.isEmpty)
          EmptyStateDotted(
            icon: AppIcons.savedOutline,
            headline: 'No saved creatives yet',
            description: 'Save creatives you like to find them here.',
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: savedCreatives.map((profile) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 160,
                    child: VendorCard(
                      profile: profile,
                      onTap: () => context.push(
                        AppRoutes.creativeProfileView(profile.userId),
                      ),
                      isSaved: savedCreativeIds.contains(profile.userId),
                      onSaveTap: () => onToggleSavedCreative(profile.userId),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _SavedEventTile extends StatelessWidget {
  const _SavedEventTile({
    required this.event,
    required this.hasAcceptedBooking,
    required this.onTap,
    required this.onUnsave,
  });

  final EventEntity event;
  final bool hasAcceptedBooking;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    final dateStr = event.date != null
        ? '${event.date!.day}/${event.date!.month}/${event.date!.year}'
        : '—';
    final theme = Theme.of(context);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: event.imageUrls.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: event.imageUrls.first,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Icon(AppIcons.event, color: theme.colorScheme.onSurfaceVariant),
        title: Text(event.title),
        subtitle: Text(
          '${getEventLocationDisplayLine(event, isPlanner: false, hasAcceptedBooking: hasAcceptedBooking)} · $dateStr',
        ),
        trailing: IconButton(
          icon: Icon(AppIcons.savedFilled, color: theme.colorScheme.primary),
          onPressed: onUnsave,
          tooltip: 'Remove from saved',
        ),
      ),
    );
  }
}

class _ForRoleSection extends StatelessWidget {
  const _ForRoleSection({
    this.roleLabel,
    required this.filter,
    this.recommendedForYouEvents = const [],
    this.pendingCountByEventId = const {},
    this.savedEventIds = const {},
    this.acceptedEventIds = const {},
    this.onToggleSaved,
  });

  final String? roleLabel;
  final CreativeHomeFilter filter;
  final List<EventEntity> recommendedForYouEvents;
  final Map<String, int> pendingCountByEventId;
  final Set<String> savedEventIds;
  final Set<String> acceptedEventIds;
  final void Function(String eventId)? onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEvents = filter == CreativeHomeFilter.events;
    final role = roleLabel ?? 'Creative';

    if (isEvents) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events for you',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (recommendedForYouEvents.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Picked for your skills and location',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (recommendedForYouEvents.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: AppBorders.borderRadius,
                    ),
                    child: Icon(
                      AppIcons.event,
                      size: 28,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find gigs that match your skills',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Browse and apply to events looking for talent like you.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.explore),
                    child: const Text('Browse events'),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendedForYouEvents.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final e = recommendedForYouEvents[index];
                      return _CreativeEventCard(
                        event: e,
                        applicantCount: pendingCountByEventId[e.id] ?? 0,
                        isSaved: savedEventIds.contains(e.id),
                        hasAcceptedBooking: acceptedEventIds.contains(e.id),
                        onTap: () => context.push(AppRoutes.eventDetail(e.id)),
                        onSaveTap: onToggleSaved != null
                            ? () => onToggleSaved!(e.id)
                            : () {},
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(AppRoutes.explore),
                  child: const Text('Browse all events'),
                ),
              ],
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For: $role',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: AppBorders.borderRadius,
                ),
                child: Icon(
                  AppIcons.gigs,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep your profile up to date',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Help planners find you for the right gigs.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.creativeProfile),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
