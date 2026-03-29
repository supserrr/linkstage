import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../widgets/atoms/glass_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_borders.dart';
import '../../../core/utils/event_location_utils.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/creative_past_work_preferences_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../widgets/atoms/section_header.dart';
import '../../widgets/atoms/skeleton_box.dart';
import '../../bloc/creative_past_work/creative_past_work_cubit.dart';
import '../../bloc/creative_past_work/creative_past_work_state.dart';
import '../../widgets/molecules/connection_error_overlay.dart';
import '../../widgets/molecules/empty_state_dotted.dart';
import '../../widgets/molecules/profile_avatar.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../widgets/molecules/skeleton_loaders.dart';

/// Past Work page for a creative: past events (from completed bookings) and
/// past collaborations.
class CreativePastWorkPage extends StatelessWidget {
  const CreativePastWorkPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final authNotifier = sl<AuthRedirectNotifier>();
    final viewerUserId = authNotifier.user?.id ?? '';
    final isViewingOwn = viewerUserId == userId;
    return BlocProvider(
      create: (_) => CreativePastWorkCubit(
        sl<BookingRepository>(),
        sl<CollaborationRepository>(),
        sl<EventRepository>(),
        sl<UserRepository>(),
        sl<ProfileRepository>(),
        sl<CreativePastWorkPreferencesRepository>(),
        userId,
        viewerUserId,
      ),
      child: _CreativePastWorkView(isViewingOwn: isViewingOwn),
    );
  }
}

class _CreativePastWorkView extends StatelessWidget {
  const _CreativePastWorkView({required this.isViewingOwn});

  final bool isViewingOwn;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreativePastWorkCubit, CreativePastWorkState>(
      builder: (context, state) {
        if (state.isLoading &&
            state.pastEvents.isEmpty &&
            state.pastCollaborations.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isViewingOwn ? 'Your Past Work' : 'Past Work'),
            ),
            body: _buildRefreshIndicator(
              context: context,
              onRefresh: () => context.read<CreativePastWorkCubit>().load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SkeletonBox(
                            width: 20,
                            height: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(width: 8),
                          SkeletonBox(height: 16, width: 110),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: const PastWorkCardSkeleton(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: const PastWorkCardSkeleton(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: const PastWorkCardSkeleton(),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SkeletonBox(
                            width: 20,
                            height: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(width: 8),
                          SkeletonBox(height: 16, width: 150),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: const PastWorkCardSkeleton(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: const PastWorkCardSkeleton(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final cubit = context.read<CreativePastWorkCubit>();
        final body = _buildRefreshIndicator(
          context: context,
          onRefresh: () => cubit.load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Past Events', icon: Icons.event),
                const SizedBox(height: 12),
                if (state.pastEvents.isEmpty)
                  EmptyStateDotted(
                    icon: Icons.event_outlined,
                    headline: 'No past events yet',
                    description: 'Completed bookings will appear here.',
                  )
                else
                  ...state.pastEvents.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PastEventCard(
                        item: item,
                        isViewingOwnPastWork: isViewingOwn,
                        showOnProfile: !state.hiddenIds.contains(
                          item.bookingId,
                        ),
                        showVisibilityToggle: isViewingOwn && state.configMode,
                        onVisibilityChanged: (show) =>
                            cubit.setItemVisibility(item.bookingId, show),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Past Collaborations',
                  icon: Icons.handshake,
                ),
                const SizedBox(height: 12),
                if (state.pastCollaborations.isEmpty)
                  EmptyStateDotted(
                    icon: Icons.handshake_outlined,
                    headline: 'No past collaborations yet',
                    description: 'Completed collaborations will appear here.',
                  )
                else
                  ...state.pastCollaborations.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PastCollaborationCard(
                        item: item,
                        showOnProfile: !state.hiddenIds.contains(
                          item.collaboration.id,
                        ),
                        showVisibilityToggle: isViewingOwn && state.configMode,
                        onVisibilityChanged: (show) => cubit.setItemVisibility(
                          item.collaboration.id,
                          show,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.configMode
                  ? 'Configure past work'
                  : (isViewingOwn ? 'Your Past Work' : 'Past Work'),
            ),
            actions: [
              if (isViewingOwn &&
                  (state.pastEvents.isNotEmpty ||
                      state.pastCollaborations.isNotEmpty))
                IconButton(
                  icon: Icon(state.configMode ? Icons.check : Icons.edit),
                  onPressed: () =>
                      context.read<CreativePastWorkCubit>().toggleConfigMode(),
                  tooltip: state.configMode ? 'Done' : 'Configure visibility',
                ),
            ],
          ),
          body: ConnectionErrorOverlay(
            hasError: state.error != null,
            error: state.error,
            onRefresh: () => cubit.load(),
            child: body,
          ),
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
}

class _PastEventCard extends StatelessWidget {
  const _PastEventCard({
    required this.item,
    required this.isViewingOwnPastWork,
    this.showOnProfile = true,
    this.showVisibilityToggle = false,
    this.onVisibilityChanged,
  });

  final PastEventItem item;
  final bool isViewingOwnPastWork;
  final bool showOnProfile;
  final bool showVisibilityToggle;
  final void Function(bool)? onVisibilityChanged;

  static String _dateStr(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final event = item.event;
    final colorScheme = Theme.of(context).colorScheme;
    final viewerId = sl<AuthRedirectNotifier>().user?.id ?? '';
    final isPlanner = viewerId.isNotEmpty && viewerId == event.plannerId;
    final locationLine = getEventLocationDisplayLine(
      event,
      isPlanner: isPlanner,
      hasAcceptedBooking: isViewingOwnPastWork,
    );
    final metadata = '$locationLine · ${_dateStr(event.date)}';
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.eventDetail(event.id)),
          borderRadius: AppBorders.borderRadius,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              event.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppBorders.chipRadius,
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CachedNetworkImage(
                          imageUrl: event.imageUrls.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.event,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata.isEmpty ? '—' : metadata,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showVisibilityToggle) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Show on profile',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Switch(
                      value: showOnProfile,
                      onChanged: onVisibilityChanged,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(width: 8),
                ProfileAvatar(
                  photoUrl: item.plannerPhotoUrl,
                  displayName: item.plannerName,
                  radius: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PastCollaborationCard extends StatelessWidget {
  const _PastCollaborationCard({
    required this.item,
    this.showOnProfile = true,
    this.showVisibilityToggle = false,
    this.onVisibilityChanged,
  });

  final PastCollaborationItem item;
  final bool showOnProfile;
  final bool showVisibilityToggle;
  final void Function(bool)? onVisibilityChanged;

  static String _dateStr(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = item.collaboration;
    final event = item.event;
    final colorScheme = Theme.of(context).colorScheme;
    final title = c.displayTitle;
    final metadataParts = <String>[];
    if (c.location != null && c.location!.isNotEmpty) {
      metadataParts.add(c.location!);
    }
    if (event?.date != null) {
      metadataParts.add(_dateStr(event!.date));
    } else if (c.date != null) {
      metadataParts.add(_dateStr(c.date));
    }
    final metadata = metadataParts.isEmpty ? '—' : metadataParts.join(' · ');
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.collaborationDetail,
            extra: {
              'collaboration': c,
              'otherPersonName': item.plannerName,
              'otherPersonId': item.plannerId,
              'otherPersonPhotoUrl': item.plannerPhotoUrl,
              'otherPersonRole': UserRole.eventPlanner,
              'viewerIsCreative': true,
            },
          ),
          borderRadius: AppBorders.borderRadius,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeading(context, event, colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showVisibilityToggle) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Show on profile',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Switch(
                      value: showOnProfile,
                      onChanged: onVisibilityChanged,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(width: 8),
                ProfileAvatar(
                  photoUrl: item.plannerPhotoUrl,
                  displayName: item.plannerName,
                  radius: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(
    BuildContext context,
    EventEntity? event,
    ColorScheme colorScheme,
  ) {
    if (event != null && event.imageUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppBorders.chipRadius),
        child: SizedBox(
          width: 48,
          height: 48,
          child: CachedNetworkImage(
            imageUrl: event.imageUrls.first,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppBorders.chipRadius),
      ),
      child: Icon(
        item.collaboration.eventType != null &&
                item.collaboration.eventType!.isNotEmpty
            ? Icons.event_outlined
            : Icons.handshake_outlined,
        size: 28,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
