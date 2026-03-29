import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../bloc/event_applicants/event_applicants_cubit.dart';
import '../bloc/event_applicants/event_applicants_state.dart';
import '../../core/constants/app_borders.dart';
import '../../core/constants/app_icons.dart';
import '../../core/di/injection.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/router/app_router.dart';
import '../../core/router/auth_redirect.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../widgets/atoms/glass_card.dart';
import '../widgets/molecules/empty_state_dotted.dart';
import '../widgets/molecules/profile_avatar.dart';

/// For event planners: list of applicants (pending and accepted) for an event.
/// Pending: View profile, Accept, Reject. Accepted: View profile, Message.
class EventApplicantsPage extends StatefulWidget {
  const EventApplicantsPage({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventApplicantsPage> createState() => _EventApplicantsPageState();
}

class _EventApplicantsPageState extends State<EventApplicantsPage> {
  late final EventApplicantsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = EventApplicantsCubit(widget.eventId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _accept(BookingEntity booking) async {
    _cubit.setAcceptingBookingId(booking.id);
    try {
      await sl<BookingRepository>().updateBookingStatus(
        booking.id,
        BookingStatus.accepted,
      );
      sl<PushNotificationService>().syncAcceptedEventId(
        creativeId: booking.creativeId,
        eventId: booking.eventId,
        add: true,
      );
      sl<PushNotificationService>().notifyUser(
        targetUserId: booking.creativeId,
        title: 'Application accepted',
        body:
            'Your application for ${_cubit.state.event?.title ?? 'Event'} has been accepted',
        data: {
          'route': '/bookings',
          'bookingId': booking.id,
          'eventId': booking.eventId,
          'type': 'booking_accepted',
        },
      );
      if (mounted) {
        showToast(context, 'Application accepted');
        // Go to Chat list first so it builds and subscribes to Firestore, then open
        // the thread. When the room is created the list receives the update, so the
        // creative appears in the list when the user taps back.
        context.go(AppRoutes.messages);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.push(AppRoutes.chatWithUser(booking.creativeId));
          }
        });
        _cubit.load();
      }
    } catch (e) {
      if (mounted) {
        _cubit.clearAcceptingBookingId();
        showToast(context, 'Failed to accept: $e', isError: true);
      }
    }
  }

  Future<void> _reject(BookingEntity booking) async {
    _cubit.setRejectingBookingId(booking.id);
    try {
      if (booking.status == BookingStatus.accepted) {
        sl<PushNotificationService>().syncAcceptedEventId(
          creativeId: booking.creativeId,
          eventId: booking.eventId,
          add: false,
        );
      }
      await sl<BookingRepository>().updateBookingStatus(
        booking.id,
        BookingStatus.declined,
      );
      final eventTitle = _cubit.state.event?.title ?? 'Event';
      final isInvitation = booking.status == BookingStatus.invited;
      sl<PushNotificationService>().notifyUser(
        targetUserId: booking.creativeId,
        title: isInvitation ? 'Invitation cancelled' : 'Application declined',
        body: isInvitation
            ? 'Your invitation to $eventTitle was cancelled'
            : 'Your application for $eventTitle has been declined',
        data: {
          'route': '/bookings',
          'bookingId': booking.id,
          'eventId': booking.eventId,
          'type': 'booking_declined',
        },
      );
      if (mounted) {
        showToast(context, 'Application declined');
        _cubit.load();
      }
    } catch (e) {
      if (mounted) {
        _cubit.clearRejectingBookingId();
        showToast(context, 'Failed to decline: $e', isError: true);
      }
    }
  }

  Future<void> _markComplete(BookingEntity booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as complete'),
        content: const Text(
          'Mark this gig as completed? You can then leave a review for the creative.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _cubit.setCompletingBookingId(booking.id);
    try {
      await sl<BookingRepository>().updateBookingStatus(
        booking.id,
        BookingStatus.completed,
      );
      if (mounted) {
        showToast(context, 'Gig marked as complete');
        _cubit.load();
      }
    } catch (e) {
      if (mounted) {
        _cubit.clearCompletingBookingId();
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

  Future<void> _showLeaveReviewDialog(BookingEntity booking) async {
    int rating = 5;
    final controller = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => GlassBottomSheet(
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Leave a review',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          onPressed: () => setModalState(() => rating = star),
                          icon: Icon(
                            star <= rating ? Icons.star : Icons.star_border,
                            color: Theme.of(ctx).colorScheme.primary,
                            size: 36,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Write your review (optional)...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (submitted != true || !mounted) return;
    final plannerId = sl<AuthRedirectNotifier>().user?.id;
    if (plannerId == null || plannerId.isEmpty) return;
    try {
      await sl<ReviewRepository>().createReview(
        bookingId: booking.id,
        reviewerId: plannerId,
        revieweeId: booking.creativeId,
        rating: rating,
        comment: controller.text.trim(),
      );
      if (mounted) {
        showToast(context, 'Review submitted');
        _cubit.markReviewedForBooking(booking.id);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed to submit review: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EventApplicantsCubit>.value(
      value: _cubit,
      child: BlocBuilder<EventApplicantsCubit, EventApplicantsState>(
        builder: (context, state) {
          final theme = Theme.of(context);

          if (state.loading && state.event == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Applications')),
              body: Center(
                child: LoadingAnimationWidget.stretchedDots(
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
              ),
            );
          }

          if (state.error != null && state.event == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Applications')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            context.read<EventApplicantsCubit>().load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final event = state.event;
          final eventTitle = event?.title ?? 'Event';
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final eventDate = event?.date;
          final eventDateInPast =
              eventDate != null &&
              DateTime(
                eventDate.year,
                eventDate.month,
                eventDate.day,
              ).isBefore(today);
          final hasAcceptedNotCompleted = state.applicants.any(
            (b) => b.status == BookingStatus.accepted,
          );
          final daysAgo = eventDateInPast
              ? today
                    .difference(
                      DateTime(eventDate.year, eventDate.month, eventDate.day),
                    )
                    .inDays
              : 0;
          final showReminderBanner =
              eventDateInPast && hasAcceptedNotCompleted && daysAgo > 0;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Applications'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: state.applicants.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(context).height - 200,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: EmptyStateDotted(
                            icon: AppIcons.applicants,
                            headline: 'No applications yet for "$eventTitle"',
                            description:
                                'Creatives who apply will show up here.',
                          ),
                        ),
                      ),
                    ),
                  )
                : CustomMaterialIndicator(
                    onRefresh: () =>
                        context.read<EventApplicantsCubit>().load(),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    useMaterialContainer: false,
                    indicatorBuilder: (context, controller) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LoadingAnimationWidget.threeRotatingDots(
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showReminderBanner)
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(
                                AppBorders.chipRadius,
                              ),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    daysAgo == 1
                                        ? 'This event was yesterday. Mark completed gigs to leave reviews.'
                                        : 'This event was $daysAgo days ago. Mark completed gigs to leave reviews.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (showReminderBanner) const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            itemCount: state.applicants.length,
                            itemBuilder: (context, index) {
                              final booking = state.applicants[index];
                              final user =
                                  state.creativeUsers[booking.creativeId];
                              final name =
                                  user?.displayName ??
                                  user?.username ??
                                  user?.email ??
                                  'Creative';
                              final photoUrl = user?.photoUrl;
                              final isInvited =
                                  booking.status == BookingStatus.invited;
                              final isPending =
                                  booking.status == BookingStatus.pending;
                              final isCompleted =
                                  booking.status == BookingStatus.completed;
                              final isAccepting =
                                  state.acceptingBookingId == booking.id;
                              final isRejecting =
                                  state.rejectingBookingId == booking.id;
                              final isCompleting =
                                  state.completingBookingId == booking.id;
                              final hasReviewed =
                                  state.hasReviewedByBookingId[booking.id] ??
                                  false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: AppBorders.borderRadius,
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.6,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ProfileAvatar(
                                            photoUrl: photoUrl,
                                            displayName: name,
                                            radius: 32,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isPending
                                                        ? theme
                                                              .colorScheme
                                                              .primaryContainer
                                                              .withValues(
                                                                alpha: 0.6,
                                                              )
                                                        : isInvited
                                                        ? theme
                                                              .colorScheme
                                                              .tertiaryContainer
                                                              .withValues(
                                                                alpha: 0.7,
                                                              )
                                                        : isCompleted
                                                        ? theme
                                                              .colorScheme
                                                              .secondaryContainer
                                                              .withValues(
                                                                alpha: 0.7,
                                                              )
                                                        : theme
                                                              .colorScheme
                                                              .tertiaryContainer
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppBorders.chipRadius,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    isPending
                                                        ? 'Pending application'
                                                        : isInvited
                                                        ? 'Invited'
                                                        : isCompleted
                                                        ? 'Completed'
                                                        : 'Accepted',
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      color: isPending
                                                          ? theme
                                                                .colorScheme
                                                                .onPrimaryContainer
                                                          : isInvited
                                                          ? theme
                                                                .colorScheme
                                                                .onTertiaryContainer
                                                          : isCompleted
                                                          ? theme
                                                                .colorScheme
                                                                .onSecondaryContainer
                                                          : theme
                                                                .colorScheme
                                                                .onTertiaryContainer,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                if (isCompleted &&
                                                    (booking.plannerConfirmedAt !=
                                                            null ||
                                                        booking.creativeConfirmedAt !=
                                                            null)) ...[
                                                  const SizedBox(height: 4),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 4,
                                                    children: [
                                                      if (booking
                                                              .plannerConfirmedAt !=
                                                          null)
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .check_circle_outline,
                                                              size: 14,
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Planner confirmed',
                                                              style: theme
                                                                  .textTheme
                                                                  .labelSmall
                                                                  ?.copyWith(
                                                                    color: theme
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      if (booking
                                                              .creativeConfirmedAt !=
                                                          null)
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .check_circle_outline,
                                                              size: 14,
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Creative confirmed',
                                                              style: theme
                                                                  .textTheme
                                                                  .labelSmall
                                                                  ?.copyWith(
                                                                    color: theme
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      !isInvited && !isPending && !isCompleted
                                          ? Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () => context.push(
                                                    AppRoutes.creativeProfileView(
                                                      booking.creativeId,
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.person_outline,
                                                    size: 16,
                                                  ),
                                                  label: const Text('Profile'),
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 10,
                                                        ),
                                                  ),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: isCompleting
                                                      ? null
                                                      : () => _markComplete(
                                                          booking,
                                                        ),
                                                  icon: isCompleting
                                                      ? SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              LoadingAnimationWidget.stretchedDots(
                                                                color: theme
                                                                    .colorScheme
                                                                    .onSurface,
                                                                size: 16,
                                                              ),
                                                        )
                                                      : const Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                          size: 16,
                                                        ),
                                                  label: Text(
                                                    isCompleting
                                                        ? '...'
                                                        : 'Complete',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 10,
                                                        ),
                                                  ),
                                                ),
                                                FilledButton.icon(
                                                  onPressed: () => context.go(
                                                    AppRoutes.chatWithUser(
                                                      booking.creativeId,
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.message_outlined,
                                                    size: 16,
                                                  ),
                                                  label: const Text('Message'),
                                                  style: FilledButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 10,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => context.push(
                                                      AppRoutes.creativeProfileView(
                                                        booking.creativeId,
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.person_outline,
                                                      size: 16,
                                                    ),
                                                    label: const Text(
                                                      'Profile',
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 10,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                if (isInvited) ...[
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _reject(booking),
                                                      icon: const Icon(
                                                        Icons.close,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'Cancel invitation',
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: theme
                                                            .colorScheme
                                                            .error,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ] else if (isPending) ...[
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: isRejecting
                                                          ? null
                                                          : () => _reject(
                                                              booking,
                                                            ),
                                                      icon: isRejecting
                                                          ? SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child: LoadingAnimationWidget.stretchedDots(
                                                                color: theme
                                                                    .colorScheme
                                                                    .onSurface,
                                                                size: 16,
                                                              ),
                                                            )
                                                          : const Icon(
                                                              Icons.close,
                                                              size: 16,
                                                            ),
                                                      label: Text(
                                                        isRejecting
                                                            ? '...'
                                                            : 'Reject',
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: theme
                                                            .colorScheme
                                                            .error,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: FilledButton.icon(
                                                      onPressed: isAccepting
                                                          ? null
                                                          : () => _accept(
                                                              booking,
                                                            ),
                                                      icon: isAccepting
                                                          ? SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child: LoadingAnimationWidget.stretchedDots(
                                                                color: theme
                                                                    .colorScheme
                                                                    .onPrimary,
                                                                size: 16,
                                                              ),
                                                            )
                                                          : const Icon(
                                                              Icons.check,
                                                              size: 16,
                                                            ),
                                                      label: Text(
                                                        isAccepting
                                                            ? '...'
                                                            : 'Accept',
                                                      ),
                                                      style: FilledButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ] else if (isCompleted) ...[
                                                  if (!hasReviewed) ...[
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: FilledButton.icon(
                                                        onPressed: () =>
                                                            _showLeaveReviewDialog(
                                                              booking,
                                                            ),
                                                        icon: const Icon(
                                                          Icons
                                                              .rate_review_outlined,
                                                          size: 16,
                                                        ),
                                                        label: const Text(
                                                          'Leave review',
                                                        ),
                                                        style: FilledButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 10,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: null,
                                                        icon: const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                        ),
                                                        label: const Text(
                                                          'Reviewed',
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 10,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ],
                                            ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
