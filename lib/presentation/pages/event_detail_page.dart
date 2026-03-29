import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/toast_utils.dart';
import '../widgets/molecules/connection_error_overlay.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/molecules/skeleton_loaders.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_borders.dart';
import '../../core/utils/event_location_utils.dart';
import '../../core/di/injection.dart';
import '../../core/utils/number_formatter.dart';
import '../../core/router/app_router.dart';
import '../../core/router/auth_redirect.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/planner_profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/followed_planners_repository.dart';
import '../../domain/repositories/planner_profile_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../bloc/event_detail/event_detail_cubit.dart';
import '../bloc/event_detail/event_detail_state.dart';

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const List<String> _months = [
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

String _formatEventDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

String _formatTimeForDisplay(String stored) {
  if (stored.isEmpty) return stored;
  final parts = stored
      .split(RegExp(r'[:\s]'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
      final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      final period = h < 12 ? 'AM' : 'PM';
      return '$hour:${m.toString().padLeft(2, '0')} $period';
    }
  }
  return stored;
}

/// Event detail page - collaboration-focused.
/// Matches reference design: hero, event type tag, budget, date/time, location,
/// applications strip, hosted by, about, sticky bottom bar.
class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.eventId});

  final String eventId;

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
    final isCreative = user.role == UserRole.creativeProfessional;

    return BlocProvider(
      create: (_) => EventDetailCubit(
        sl<EventRepository>(),
        sl<BookingRepository>(),
        sl<UserRepository>(),
        sl<PlannerProfileRepository>(),
        eventId,
        user.id,
        isCreative,
      ),
      child: const _EventDetailView(),
    );
  }
}

class _EventDetailView extends StatelessWidget {
  const _EventDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventDetailCubit, EventDetailState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state.isLoading && state.event == null && state.error == null) {
          return Scaffold(body: EventDetailSkeleton());
        }
        if (state.event == null) {
          final cubit = context.read<EventDetailCubit>();
          return Scaffold(
            body: ConnectionErrorOverlay(
              hasError: state.error != null,
              error: state.error,
              onRefresh: () async => cubit.load(),
              onBack: () => context.pop(),
              child: const EventDetailSkeleton(),
            ),
          );
        }
        final event = state.event!;
        final user = sl<AuthRedirectNotifier>().user!;
        final isCreator = event.plannerId == user.id;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildHero(context, event, isCreator),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.budget != null
                            ? 'Budget: RWF ${NumberFormatter.formatMoney(event.budget!)}'
                            : 'Budget not specified',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 20),
                      _DateTimeRow(event: event),
                      const SizedBox(height: 16),
                      _LocationRow(
                        event: event,
                        isPlanner: isCreator,
                        hasAcceptedBooking: state.hasAcceptedBooking,
                      ),
                      const SizedBox(height: 24),
                      _HostedBySection(
                        planner: state.planner,
                        plannerProfile: state.plannerProfile,
                        plannerId: event.plannerId,
                        currentUserId: user.id,
                      ),
                      const SizedBox(height: 24),
                      if (event.description.isNotEmpty) ...[
                        Text(
                          'About Event',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ],
                      if (event.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Gallery',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _EventGallery(imageUrls: event.imageUrls),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(
            context,
            state,
            event,
            isCreator,
            user,
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context, EventEntity event, bool isCreator) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (!isCreator)
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _shareEvent(context, event),
            tooltip: 'Share',
          ),
        if (isCreator)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'delete') {
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
                    await sl<EventRepository>().deleteEvent(event.id);
                    if (context.mounted) {
                      showToast(context, 'Event deleted');
                      context.go(AppRoutes.bookings);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showToast(context, 'Failed to delete: $e', isError: true);
                    }
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete event')),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (event.imageUrls.isNotEmpty)
              CachedNetworkImage(
                imageUrl: event.imageUrls.first,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.event,
                  size: 80,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (event.eventType.isNotEmpty)
              Positioned(
                left: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                  ),
                  child: Text(
                    event.eventType,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    EventDetailState state,
    EventEntity event,
    bool isCreator,
    UserEntity user,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isCreator) {
      return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // Use top-level edit route so extra (event) is preserved (shell child routes can lose extra).
                    final updated = await context.push<bool?>(
                      AppRoutes.editEvent,
                      extra: event,
                    );
                    if (updated == true && context.mounted) {
                      context.read<EventDetailCubit>().load();
                    }
                  },
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      context.push(AppRoutes.eventApplicants(event.id)),
                  child: const Text('Applications'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (user.role == UserRole.creativeProfessional) {
      final cubit = context.read<EventDetailCubit>();
      return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.budget != null
                          ? 'RWF ${NumberFormatter.formatMoney(event.budget!)}'
                          : 'Not specified',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: state.hasApplied || state.isApplying
                      ? null
                      : () => cubit.applyToCollaborate(),
                  child: state.isApplying
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: LoadingAnimationWidget.stretchedDots(
                            color: colorScheme.onPrimary,
                            size: 24,
                          ),
                        )
                      : Text(
                          state.hasApplied
                              ? 'Application sent'
                              : 'Apply to collaborate',
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  void _shareEvent(BuildContext context, EventEntity event) {
    final url = 'https://linkstage.app/event/${event.id}';
    final text = '${event.title}\n$url';
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showToast(context, 'Link copied to clipboard');
    }
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({required this.event});

  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String dateLine = 'Date not set';
    String timeLine = 'Time not specified';
    if (event.date != null) {
      dateLine = _formatEventDate(event.date!);
      if (event.startTime.isNotEmpty || event.endTime.isNotEmpty) {
        final start = _formatTimeForDisplay(event.startTime);
        final end = _formatTimeForDisplay(event.endTime);
        timeLine = event.endTime.isNotEmpty ? '$start - $end' : start;
      }
    }

    final iconSize = (theme.textTheme.titleMedium?.fontSize ?? 16) + 4;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: iconSize,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateLine,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeLine,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: timeLine == 'Time not specified'
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.event,
    required this.isPlanner,
    required this.hasAcceptedBooking,
  });

  final EventEntity event;
  final bool isPlanner;
  final bool hasAcceptedBooking;

  String get _placeName => getEventVenueDisplay(
    event,
    isPlanner: isPlanner,
    hasAcceptedBooking: hasAcceptedBooking,
  );
  String get _address => getEventAddressDisplay(
    event,
    isPlanner: isPlanner,
    hasAcceptedBooking: hasAcceptedBooking,
  );
  String? get _mapsDestination => eventMapsDestinationIfVisible(
    event,
    isPlanner: isPlanner,
    hasAcceptedBooking: hasAcceptedBooking,
  );

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final dest = _mapsDestination;
    if (dest == null || dest.isEmpty) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(dest)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      showToast(context, 'Could not open maps', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconSize = (theme.textTheme.titleMedium?.fontSize ?? 16) + 4;
    final canOpenMaps =
        _mapsDestination != null && _mapsDestination!.isNotEmpty;

    return InkWell(
      onTap: canOpenMaps ? () => _openInGoogleMaps(context) : null,
      borderRadius: AppBorders.borderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: iconSize,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _placeName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _address,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (canOpenMaps)
              Icon(
                Icons.directions_outlined,
                size: 22,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _HostedBySection extends StatefulWidget {
  const _HostedBySection({
    this.planner,
    this.plannerProfile,
    required this.plannerId,
    this.currentUserId,
  });

  final UserEntity? planner;
  final PlannerProfileEntity? plannerProfile;
  final String plannerId;
  final String? currentUserId;

  @override
  State<_HostedBySection> createState() => _HostedBySectionState();
}

class _HostedBySectionState extends State<_HostedBySection> {
  late final _HostedByFollowCubit _followingCubit;
  StreamSubscription<Set<String>>? _subscription;

  @override
  void initState() {
    super.initState();
    _followingCubit = _HostedByFollowCubit();
    _subscribe();
  }

  void _subscribe() {
    final currentUserId = widget.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return;
    final plannerId = widget.planner?.id ?? widget.plannerId;
    if (plannerId.isEmpty) return;
    _subscription = sl<FollowedPlannersRepository>()
        .watchFollowedPlannerIds(currentUserId)
        .listen((ids) {
          if (!mounted) return;
          _followingCubit.sync(ids.contains(plannerId));
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _followingCubit.close();
    super.dispose();
  }

  Future<void> _onFollowTap() async {
    final plannerId = widget.planner?.id ?? widget.plannerId;
    final currentUserId = widget.currentUserId;
    if (plannerId.isEmpty || currentUserId == null || currentUserId.isEmpty) {
      return;
    }
    await sl<FollowedPlannersRepository>().toggleFollow(
      currentUserId,
      plannerId,
    );
    if (mounted) {
      showToast(context, 'You are now following this host');
    }
  }

  Future<void> _onUnfollowTap() async {
    final plannerId = widget.planner?.id ?? widget.plannerId;
    final currentUserId = widget.currentUserId;
    if (plannerId.isEmpty || currentUserId == null || currentUserId.isEmpty) {
      return;
    }
    await sl<FollowedPlannersRepository>().toggleFollow(
      currentUserId,
      plannerId,
    );
    if (mounted) {
      showToast(context, 'Unfollowed');
    }
  }

  void _openEnlargedPhoto(BuildContext context) {
    final planner = widget.planner;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name =
        planner?.displayName ??
        planner?.username ??
        planner?.email.split('@').first ??
        'Host';
    final hasPhoto = planner?.photoUrl != null && planner!.photoUrl!.isNotEmpty;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: hasPhoto
              ? ClipRRect(
                  borderRadius: AppBorders.borderRadius,
                  child: CachedNetworkImage(
                    imageUrl: planner.photoUrl!,
                    fit: BoxFit.contain,
                  ),
                )
              : CircleAvatar(
                  radius: 80,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _openPlannerProfile(BuildContext context) {
    final plannerId = widget.planner?.id ?? widget.plannerId;
    if (plannerId.isEmpty) return;
    context.push(AppRoutes.plannerProfileView(plannerId));
  }

  @override
  Widget build(BuildContext context) {
    final planner = widget.planner;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name =
        planner?.displayName ??
        planner?.username ??
        planner?.email.split('@').first ??
        'Host';
    final isSelf =
        planner?.id != null &&
        widget.currentUserId != null &&
        planner!.id == widget.currentUserId;

    return BlocProvider.value(
      value: _followingCubit,
      child: BlocBuilder<_HostedByFollowCubit, bool>(
        builder: (context, isFollowing) {
          final canFollow = !isSelf && !isFollowing;
          final canUnfollow = !isSelf && isFollowing;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hosted by',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _openEnlargedPhoto(context),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: (planner?.photoUrl ?? '').isNotEmpty
                          ? CachedNetworkImageProvider(planner!.photoUrl!)
                          : null,
                      child: (planner?.photoUrl ?? '').isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openPlannerProfile(context),
                      borderRadius: BorderRadius.circular(
                        AppBorders.chipRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.plannerProfile?.role?.isNotEmpty == true
                                  ? widget.plannerProfile!.role!
                                  : 'Event Planner',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: canFollow
                        ? _onFollowTap
                        : canUnfollow
                        ? _onUnfollowTap
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isSelf && !isFollowing
                          ? colorScheme.onSurfaceVariant
                          : null,
                    ),
                    child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HostedByFollowCubit extends Cubit<bool> {
  _HostedByFollowCubit() : super(false);

  void sync(bool following) => emit(following);
}

class _EventGallery extends StatelessWidget {
  const _EventGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 2;
    const spacing = 8.0;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final url = imageUrls[index];
        return GestureDetector(
          onTap: () => _showFullImage(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorders.chipRadius),
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: AppBorders.borderRadius,
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
