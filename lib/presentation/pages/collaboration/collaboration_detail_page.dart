import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../widgets/atoms/glass_card.dart';
import '../../widgets/molecules/app_detail_chip.dart';
import '../../widgets/molecules/profile_avatar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_borders.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/review_repository.dart';

/// Page showing full collaboration details with option to view the other person's profile.
class CollaborationDetailPage extends StatefulWidget {
  const CollaborationDetailPage({
    super.key,
    required this.collaboration,
    required this.otherPersonName,
    required this.otherPersonId,
    this.otherPersonPhotoUrl,
    this.otherPersonRole,
    required this.viewerIsCreative,
  });

  final CollaborationEntity collaboration;
  final String otherPersonName;
  final String otherPersonId;
  final String? otherPersonPhotoUrl;
  final UserRole? otherPersonRole;
  final bool viewerIsCreative;

  @override
  State<CollaborationDetailPage> createState() =>
      _CollaborationDetailPageState();
}

class _CollaborationDetailPageState extends State<CollaborationDetailPage> {
  bool? _hasReviewed;
  CollaborationStatus? _overrideStatus;
  DateTime? _overrideCreativeConfirmedAt;
  bool _isConfirmingCompletion = false;

  CollaborationStatus get _effectiveStatus =>
      _overrideStatus ?? widget.collaboration.status;

  DateTime? get _effectiveCreativeConfirmedAt =>
      _overrideCreativeConfirmedAt ?? widget.collaboration.creativeConfirmedAt;

  @override
  void initState() {
    super.initState();
    _loadHasReviewed();
  }

  Future<void> _loadHasReviewed() async {
    final status = _effectiveStatus;
    if (status != CollaborationStatus.accepted &&
        status != CollaborationStatus.completed) {
      setState(() => _hasReviewed = false);
      return;
    }
    final userId = sl<AuthRedirectNotifier>().user?.id;
    if (userId == null || userId.isEmpty) {
      setState(() => _hasReviewed = false);
      return;
    }
    try {
      final review = await sl<ReviewRepository>()
          .getReviewByCollaborationAndReviewer(widget.collaboration.id, userId);
      if (mounted) setState(() => _hasReviewed = review != null);
    } catch (_) {
      if (mounted) setState(() => _hasReviewed = false);
    }
  }

  void _openProfile(BuildContext context) {
    if (!widget.viewerIsCreative) {
      context.push(AppRoutes.creativeProfileView(widget.otherPersonId));
    } else if (widget.otherPersonRole == UserRole.eventPlanner) {
      context.push(AppRoutes.plannerProfileView(widget.otherPersonId));
    } else {
      context.push(AppRoutes.creativeProfileView(widget.otherPersonId));
    }
  }

  Future<void> _showLeaveReviewDialog() async {
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
    ).whenComplete(() => controller.dispose());
    if (submitted != true || !mounted) return;
    final reviewerId = sl<AuthRedirectNotifier>().user?.id;
    if (reviewerId == null || reviewerId.isEmpty) return;
    try {
      await sl<ReviewRepository>().createCollaborationReview(
        collaborationId: widget.collaboration.id,
        reviewerId: reviewerId,
        revieweeId: widget.otherPersonId,
        rating: rating,
        comment: controller.text.trim(),
      );
      if (mounted) {
        showToast(context, 'Review submitted');
        setState(() => _hasReviewed = true);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed to submit review: $e', isError: true);
      }
    }
  }

  static String _dateText(DateTime? d) {
    if (d == null) return '—';
    return '${d.month}/${d.day}/${d.year}';
  }

  static String _formatTime(String? s) {
    if (s == null || s.isEmpty) return '';
    final parts = s.split(RegExp(r'[:\s]'));
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        final period = h >= 12 ? 'PM' : 'AM';
        final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        return '$hour:${m.toString().padLeft(2, '0')} $period';
      }
    }
    return s;
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

  Future<void> _confirmCompletionByCreative() async {
    if (_isConfirmingCompletion) return;
    setState(() => _isConfirmingCompletion = true);
    try {
      await sl<CollaborationRepository>().confirmCompletionByCreative(
        widget.collaboration.id,
      );
      if (mounted) {
        setState(() {
          _isConfirmingCompletion = false;
          _overrideCreativeConfirmedAt = DateTime.now();
        });
        showToast(context, 'Confirmed completion');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirmingCompletion = false);
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

  Future<void> _markAsDone() async {
    try {
      await sl<CollaborationRepository>().updateStatus(
        widget.collaboration.id,
        CollaborationStatus.completed,
        confirmingIsPlanner: !widget.viewerIsCreative,
      );
      if (mounted) {
        setState(() {
          _overrideStatus = CollaborationStatus.completed;
          if (widget.viewerIsCreative) {
            _overrideCreativeConfirmedAt = DateTime.now();
          }
        });
        showToast(context, 'Collaboration marked as done');
        _loadHasReviewed();
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _effectiveStatus;
    final isPending = status == CollaborationStatus.pending;
    final isAccepted = status == CollaborationStatus.accepted;
    final isCompleted = status == CollaborationStatus.completed;
    final canReview = isAccepted || isCompleted;
    final hasPlannerDetails =
        widget.collaboration.eventType != null ||
        widget.collaboration.date != null ||
        widget.collaboration.budget != null ||
        (widget.collaboration.location != null &&
            widget.collaboration.location!.isNotEmpty) ||
        (widget.collaboration.startTime != null &&
            widget.collaboration.startTime!.isNotEmpty) ||
        (widget.collaboration.endTime != null &&
            widget.collaboration.endTime!.isNotEmpty);

    const pagePadding = 20.0;
    const sectionGap = 16.0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final collabDateInPast =
        widget.collaboration.date != null &&
        DateTime(
          widget.collaboration.date!.year,
          widget.collaboration.date!.month,
          widget.collaboration.date!.day,
        ).isBefore(today);
    final daysAgo = collabDateInPast && widget.collaboration.date != null
        ? today
              .difference(
                DateTime(
                  widget.collaboration.date!.year,
                  widget.collaboration.date!.month,
                  widget.collaboration.date!.day,
                ),
              )
              .inDays
        : 0;
    final showReminderBanner = isAccepted && collabDateInPast && daysAgo > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Collaboration Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showReminderBanner)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        daysAgo == 1
                            ? 'This gig was yesterday. Mark as done when complete to leave a review.'
                            : 'This gig was $daysAgo days ago. Mark as done when complete to leave a review.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _openProfile(context),
                    borderRadius: BorderRadius.circular(40),
                    child: ProfileAvatar(
                      photoUrl: widget.otherPersonPhotoUrl,
                      displayName: widget.otherPersonName,
                      radius: 40,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _openProfile(context),
                                borderRadius: BorderRadius.circular(
                                  AppBorders.chipRadius,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    widget.otherPersonName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? colorScheme.surfaceContainerHighest
                                    : isAccepted
                                    ? colorScheme.primaryContainer
                                    : isPending
                                    ? colorScheme.tertiaryContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppBorders.chipRadius,
                                ),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? colorScheme.onSurfaceVariant
                                      : isAccepted
                                      ? colorScheme.onPrimaryContainer
                                      : isPending
                                      ? colorScheme.onTertiaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (canReview) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (_hasReviewed == true)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.rate_review_outlined,
                                      size: 18,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reviewed',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                )
                              else
                                InkWell(
                                  onTap: () => _showLeaveReviewDialog(),
                                  borderRadius: BorderRadius.circular(
                                    AppBorders.chipRadius,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Leave review',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: sectionGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: AppBorders.borderRadius,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Text(
                widget.collaboration.description,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
            if (hasPlannerDetails) ...[
              const SizedBox(height: 24),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Event details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: sectionGap),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.collaboration.eventType != null)
                    AppDetailChip(
                      icon: Icons.event_outlined,
                      label: widget.collaboration.eventType!,
                      colorScheme: colorScheme,
                    ),
                  if (widget.collaboration.date != null)
                    AppDetailChip(
                      icon: Icons.calendar_today_outlined,
                      label: _dateText(widget.collaboration.date),
                      colorScheme: colorScheme,
                    ),
                  if (widget.collaboration.budget != null)
                    AppDetailChip(
                      icon: Icons.attach_money_outlined,
                      label:
                          '${NumberFormatter.formatMoney(widget.collaboration.budget!)} RWF',
                      colorScheme: colorScheme,
                    ),
                  if (widget.collaboration.location != null &&
                      widget.collaboration.location!.isNotEmpty)
                    AppDetailChip(
                      icon: Icons.location_on_outlined,
                      label: widget.collaboration.location!,
                      colorScheme: colorScheme,
                    ),
                  if (widget.collaboration.startTime != null &&
                      widget.collaboration.startTime!.isNotEmpty)
                    AppDetailChip(
                      icon: Icons.schedule_outlined,
                      label:
                          widget.collaboration.endTime != null &&
                              widget.collaboration.endTime!.isNotEmpty
                          ? '${_formatTime(widget.collaboration.startTime)} – ${_formatTime(widget.collaboration.endTime)}'
                          : _formatTime(widget.collaboration.startTime),
                      colorScheme: colorScheme,
                    )
                  else if (widget.collaboration.endTime != null &&
                      widget.collaboration.endTime!.isNotEmpty)
                    AppDetailChip(
                      icon: Icons.schedule_outlined,
                      label: _formatTime(widget.collaboration.endTime),
                      colorScheme: colorScheme,
                    ),
                ],
              ),
            ],
            if (widget.viewerIsCreative && isPending) ...[
              const SizedBox(height: 24),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              _AcceptDeclineButtons(collaboration: widget.collaboration),
            ] else if (isAccepted || isCompleted) ...[
              const SizedBox(height: 24),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        context.go(
                          AppRoutes.chatWithUser(
                            widget.viewerIsCreative
                                ? widget.collaboration.requesterId
                                : widget.collaboration.targetUserId,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(0, 48),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: Text(
                        isCompleted
                            ? 'View conversation'
                            : 'Start conversation',
                      ),
                    ),
                  ),
                  if (isAccepted) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _markAsDone,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text('Mark as done'),
                      ),
                    ),
                  ],
                  if (isCompleted &&
                      widget.viewerIsCreative &&
                      _effectiveCreativeConfirmedAt == null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isConfirmingCompletion
                            ? null
                            : _confirmCompletionByCreative,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(0, 48),
                        ),
                        icon: _isConfirmingCompletion
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: LoadingAnimationWidget.stretchedDots(
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              )
                            : const Icon(Icons.thumb_up_outlined, size: 20),
                        label: const Text('Confirm I completed my work'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AcceptDeclineButtons extends StatefulWidget {
  const _AcceptDeclineButtons({required this.collaboration});

  final CollaborationEntity collaboration;

  @override
  State<_AcceptDeclineButtons> createState() => _AcceptDeclineButtonsState();
}

class _AcceptDeclineButtonsState extends State<_AcceptDeclineButtons> {
  bool _isBusy = false;

  Future<void> _accept() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await sl<CollaborationRepository>().updateStatus(
        widget.collaboration.id,
        CollaborationStatus.accepted,
      );
      final user = sl<AuthRedirectNotifier>().user;
      final accepterName =
          user?.displayName ?? user?.username ?? user?.email ?? 'Someone';
      sl<PushNotificationService>().notifyUser(
        targetUserId: widget.collaboration.requesterId,
        title: 'Proposal accepted',
        body: '$accepterName accepted your proposal',
        data: {
          'route': '/collaboration/detail',
          'collaborationId': widget.collaboration.id,
          'type': 'collaboration_accepted',
        },
      );
      if (!mounted) return;
      showToast(context, 'Proposal accepted');
      context.go(AppRoutes.chatWithUser(widget.collaboration.requesterId));
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

  Future<void> _decline() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await sl<CollaborationRepository>().updateStatus(
        widget.collaboration.id,
        CollaborationStatus.declined,
      );
      final user = sl<AuthRedirectNotifier>().user;
      final declinerName =
          user?.displayName ?? user?.username ?? user?.email ?? 'Someone';
      sl<PushNotificationService>().notifyUser(
        targetUserId: widget.collaboration.requesterId,
        title: 'Proposal declined',
        body: '$declinerName declined your proposal',
        data: {
          'route': '/collaboration/detail',
          'collaborationId': widget.collaboration.id,
          'type': 'collaboration_declined',
        },
      );
      if (!mounted) return;
      showToast(context, 'Proposal declined');
      context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isBusy ? null : _decline,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text('Decline'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _isBusy ? null : _accept,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: _isBusy
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: LoadingAnimationWidget.stretchedDots(
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  )
                : const Text('Accept'),
          ),
        ),
      ],
    );
  }
}
