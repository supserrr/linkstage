import 'package:flutter/material.dart';

import '../atoms/glass_card.dart';
import '../../../core/constants/app_borders.dart';
import '../atoms/skeleton_box.dart';

/// Skeleton for event card in grid (matches _StageCard/_CreativeEventCard layout).
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
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
            SkeletonBox(
              height: 110,
              width: double.infinity,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppBorders.radius),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 16, width: 140),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      SkeletonBox(
                        width: 12,
                        height: 12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(width: 3),
                      Expanded(child: SkeletonBox(height: 12, width: 70)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      SkeletonBox(
                        width: 12,
                        height: 12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(width: 3),
                      Expanded(child: SkeletonBox(height: 11, width: 100)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      SkeletonBox(
                        width: 12,
                        height: 12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(width: 3),
                      SkeletonBox(height: 11, width: 85),
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

/// Skeleton for following planner card (matches _FollowingPlannerCard layout).
/// Use for Following page - 72x72 image, compact layout, Unfollow button.
class FollowingPlannerCardSkeleton extends StatelessWidget {
  const FollowingPlannerCardSkeleton({super.key});

  static const double _imageSize = 72;
  static const double _imageRadius = AppBorders.radius;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonBox(
            width: _imageSize,
            height: _imageSize,
            borderRadius: BorderRadius.all(Radius.circular(_imageRadius)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 18, width: 130),
                const SizedBox(height: 2),
                SkeletonBox(height: 14, width: 90),
                const SizedBox(height: 4),
                SkeletonBox(height: 14, width: 120),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SkeletonBox(
                      width: 14,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: SkeletonBox(height: 14, width: 80)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SkeletonBox(
            height: 36,
            width: 85,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for planner profile card (matches _PlannerProfileCard layout).
/// Use for Event Planners tab in explore - padding all 16, event types row, no rating/price.
class PlannerProfileCardSkeleton extends StatelessWidget {
  const PlannerProfileCardSkeleton({super.key});

  static const double _imageSize = 96;
  static const double _imageRadius = AppBorders.radius;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonBox(
            width: _imageSize,
            height: _imageSize,
            borderRadius: BorderRadius.all(Radius.circular(_imageRadius)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 22, width: 140),
                const SizedBox(height: 4),
                SkeletonBox(height: 16, width: 100),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SkeletonBox(
                      width: 16,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: SkeletonBox(height: 14, width: 120)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SkeletonBox(
                      width: 14,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: SkeletonBox(height: 14, width: 100)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for vendor/profile card in list (matches VendorCard layout).
class VendorCardSkeleton extends StatelessWidget {
  const VendorCardSkeleton({super.key});

  static const double _imageSize = 96;
  static const double _imageRadius = AppBorders.radius;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SkeletonBox(
              width: _imageSize,
              height: _imageSize,
              borderRadius: BorderRadius.all(Radius.circular(_imageRadius)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonBox(height: 22, width: 160),
                  const SizedBox(height: 4),
                  SkeletonBox(height: 16, width: 100),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SkeletonBox(
                        width: 16,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(width: 6),
                      SkeletonBox(height: 16, width: 28),
                      const SizedBox(width: 6),
                      SkeletonBox(height: 14, width: 60),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SkeletonBox(
                        width: 14,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: SkeletonBox(height: 14, width: 100)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SkeletonBox(height: 20, width: 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for explore event card in list (matches _ExploreEventCard layout).
/// Use for Events tab in explore - full-width card with 140px image, date, title, location.
class ExploreEventCardSkeleton extends StatelessWidget {
  const ExploreEventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(
            height: 140,
            width: double.infinity,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppBorders.radius),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 16, width: 140),
                const SizedBox(height: 6),
                SkeletonBox(height: 20, width: double.infinity),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SkeletonBox(
                      width: 16,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: SkeletonBox(height: 14, width: 120)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for booking/gig event tile (matches _BookingEventTile layout).
/// Use for Gigs tab in bookings - 88x88 image, event title, date, status, action.
class BookingEventTileSkeleton extends StatelessWidget {
  const BookingEventTileSkeleton({super.key});

  static const double _imageSize = 88;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonBox(
            width: _imageSize,
            height: _imageSize,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 18, width: 160),
                const SizedBox(height: 4),
                SkeletonBox(height: 14, width: 100),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(height: 14, width: 70),
                    SkeletonBox(
                      height: 28,
                      width: 100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for collaboration proposal tile (matches _CollaborationProposalTile layout).
/// Use for Collaborations tab in bookings - avatar, name, status chip, description, chips, divider, buttons.
/// For my_events (sent proposals), use margin: EdgeInsets.only(bottom: 12).
class CollaborationProposalTileSkeleton extends StatelessWidget {
  const CollaborationProposalTileSkeleton({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  static const double _avatarSize = 56;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(
                width: _avatarSize,
                height: _avatarSize,
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(height: 20, width: 120),
                        const Spacer(),
                        SkeletonBox(
                          height: 24,
                          width: 72,
                          borderRadius: BorderRadius.circular(
                            AppBorders.chipRadius,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SkeletonBox(height: 14, width: 100),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SkeletonBox(height: 16, width: double.infinity),
          const SizedBox(height: 4),
          SkeletonBox(height: 16, width: 200),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SkeletonBox(
                height: 28,
                width: 80,
                borderRadius: BorderRadius.circular(AppBorders.chipRadius),
              ),
              SkeletonBox(
                height: 28,
                width: 70,
                borderRadius: BorderRadius.circular(AppBorders.chipRadius),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(height: 40, width: 100),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonBox(
                    height: 40,
                    width: 85,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 8),
                  SkeletonBox(
                    height: 40,
                    width: 75,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for notification card (matches _NotificationCard layout).
class NotificationItemSkeleton extends StatelessWidget {
  const NotificationItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 16, width: double.infinity),
                const SizedBox(height: 4),
                SkeletonBox(height: 14, width: 200),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(height: 11, width: 32),
              const SizedBox(height: 4),
              SkeletonBox(
                width: 20,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for notifications page (section headers + notification cards).
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 11,
      itemBuilder: (context, index) {
        if (index == 0 || index == 5) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 10),
            child: SkeletonBox(height: 14, width: 60),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: const NotificationItemSkeleton(),
        );
      },
    );
  }
}

/// Skeleton for conversation list item (matches ConversationListItem layout).
class ConversationItemSkeleton extends StatelessWidget {
  const ConversationItemSkeleton({super.key, this.showDivider = true});

  final bool showDivider;

  static const double _avatarSize = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SkeletonBox(
            width: _avatarSize,
            height: _avatarSize,
            borderRadius: BorderRadius.all(Radius.circular(26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 16, width: 140),
                const SizedBox(height: 2),
                SkeletonBox(height: 14, width: 200),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SkeletonBox(height: 11, width: 36),
        ],
      ),
    );
    return Material(
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
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
}

/// Skeleton for planner dashboard (header + cards + event grid).
class PlannerDashboardSkeleton extends StatelessWidget {
  const PlannerDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 12, width: 120),
                    const SizedBox(height: 4),
                    SkeletonBox(height: 24, width: 180),
                  ],
                ),
              ),
              const SkeletonBox(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(
                  Radius.circular(AppBorders.radius),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PostAGigCardSkeleton(),
          const SizedBox(height: 20),
          _StatCardSkeleton(),
          const SizedBox(height: 24),
          SkeletonBox(height: 22, width: 160),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const EventCardSkeleton(),
            ),
          ),
          const SizedBox(height: 24),
          SkeletonBox(height: 22, width: 140),
          const SizedBox(height: 12),
          const _ActivityTileSkeleton(),
          const SizedBox(height: 12),
          const _ActivityTileSkeleton(),
          const SizedBox(height: 12),
          const _ActivityTileSkeleton(),
        ],
      ),
    );
  }
}

/// Skeleton for Post a Gig card (matches _PostAGigCard layout).
class _PostAGigCardSkeleton extends StatelessWidget {
  const _PostAGigCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 22, width: 120),
                const SizedBox(height: 4),
                SkeletonBox(height: 16, width: 180),
              ],
            ),
          ),
          SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(24),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for stat card (matches _UnifiedSummaryCard / _UnifiedStatsCard).
/// Row of 3 tiles: icon circle, value, label per tile, with vertical dividers.
class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _StatTileSkeleton()),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(child: _StatTileSkeleton()),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(child: _StatTileSkeleton()),
        ],
      ),
    );
  }
}

class _StatTileSkeleton extends StatelessWidget {
  const _StatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonBox(
            width: 34,
            height: 34,
            borderRadius: BorderRadius.circular(17),
          ),
          const SizedBox(height: 8),
          SkeletonBox(height: 24, width: 28),
          const SizedBox(height: 2),
          SkeletonBox(height: 14, width: 56),
        ],
      ),
    );
  }
}

class _ActivityTileSkeleton extends StatelessWidget {
  const _ActivityTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 16, width: double.infinity),
              const SizedBox(height: 2),
              SkeletonBox(height: 14, width: 100),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton for creative dashboard.
class CreativeDashboardSkeleton extends StatelessWidget {
  const CreativeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
                    SkeletonBox(height: 12, width: 120),
                    const SizedBox(height: 4),
                    SkeletonBox(height: 24, width: 180),
                  ],
                ),
              ),
              const SkeletonBox(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(
                  Radius.circular(AppBorders.radius),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonBox(height: 22, width: 100),
                      const SizedBox(height: 4),
                      SkeletonBox(height: 16, width: 180),
                    ],
                  ),
                ),
                SkeletonBox(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _StatCardSkeleton(),
          const SizedBox(height: 24),
          SkeletonBox(height: 22, width: 140),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const EventCardSkeleton(),
            ),
          ),
          const SizedBox(height: 24),
          SkeletonBox(height: 22, width: 120),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const EventCardSkeleton(),
            ),
          ),
          const SizedBox(height: 24),
          SkeletonBox(height: 22, width: 130),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const EventCardSkeleton(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Skeleton for chat AppBar (avatar + name). Use as AppBar title.
class ChatAppBarSkeleton extends StatelessWidget {
  const ChatAppBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SkeletonBox(
          width: 56,
          height: 56,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        SizedBox(height: 6),
        SkeletonBox(height: 16, width: 100),
      ],
    );
  }
}

/// Skeleton for chat messages loading (matches MessageBubble layout).
class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      children: [
        const SizedBox(height: 12),
        _buildBubbleSkeleton(alignment: Alignment.centerRight, width: 120),
        const SizedBox(height: 8),
        _buildBubbleSkeleton(alignment: Alignment.centerLeft, width: 160),
        const SizedBox(height: 8),
        _buildBubbleSkeleton(alignment: Alignment.centerRight, width: 80),
        const SizedBox(height: 8),
        _buildBubbleSkeleton(alignment: Alignment.centerLeft, width: 200),
      ],
    );
  }

  Widget _buildBubbleSkeleton({
    required Alignment alignment,
    required double width,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Column(
          crossAxisAlignment: alignment == Alignment.centerRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(
              width: width,
              height: 44,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(
                  alignment == Alignment.centerRight ? 18 : 5,
                ),
                bottomRight: Radius.circular(
                  alignment == Alignment.centerRight ? 5 : 18,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SkeletonBox(height: 11, width: 40),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for past work card (thumbnail 48x48, title, metadata, planner avatar 24px).
/// Matches _PastEventCard and _PastCollaborationCard layout.
class PastWorkCardSkeleton extends StatelessWidget {
  const PastWorkCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(
              Radius.circular(AppBorders.chipRadius),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 16, width: 180),
                const SizedBox(height: 4),
                SkeletonBox(height: 14, width: 140),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBox(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for event detail page (hero + content).
class EventDetailSkeleton extends StatelessWidget {
  const EventDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(height: 280, borderRadius: BorderRadius.zero),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 36, width: 200),
                    const SizedBox(height: 8),
                    SkeletonBox(height: 20, width: 140),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SkeletonBox(
                          width: 20,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(height: 20, width: 160),
                              const SizedBox(height: 2),
                              SkeletonBox(height: 16, width: 120),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SkeletonBox(
                          width: 20,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(height: 20, width: 100),
                              const SizedBox(height: 2),
                              SkeletonBox(height: 16, width: 180),
                            ],
                          ),
                        ),
                        SkeletonBox(
                          width: 22,
                          height: 22,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SkeletonBox(height: 20, width: 80),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SkeletonBox(
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(height: 20, width: 100),
                              const SizedBox(height: 2),
                              SkeletonBox(height: 16, width: 80),
                            ],
                          ),
                        ),
                        SkeletonBox(
                          height: 36,
                          width: 90,
                          borderRadius: BorderRadius.circular(
                            AppBorders.chipRadius,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SkeletonBox(height: 20, width: 100),
                    const SizedBox(height: 12),
                    SkeletonBox(height: 14, width: double.infinity),
                    const SizedBox(height: 8),
                    SkeletonBox(height: 14, width: 260),
                    const SizedBox(height: 8),
                    SkeletonBox(height: 14, width: 200),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
