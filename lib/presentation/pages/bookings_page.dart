import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/atoms/glass_card.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_borders.dart';
import '../../core/di/injection.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/number_formatter.dart';
import '../../core/router/auth_redirect.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/collaboration_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../widgets/molecules/app_detail_chip.dart';
import '../widgets/molecules/connection_error_overlay.dart';
import '../widgets/molecules/empty_state_illustrated.dart';
import '../widgets/molecules/skeleton_loaders.dart';
import '../widgets/molecules/profile_avatar.dart';

/// Gigs tab for creatives: shows events they applied to (pending) and accepted gigs.
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingEntity> _invited = [];
  List<BookingEntity> _applications = [];
  List<BookingEntity> _accepted = [];
  List<BookingEntity> _completed = [];
  List<CollaborationEntity> _collaborations = [];
  Map<String, EventEntity?> _events = {};
  Map<String, String> _requesterNames = {};
  Map<String, String?> _requesterPhotoUrls = {};
  Map<String, UserRole?> _requesterRoles = {};
  String? _confirmingBookingId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = sl<AuthRedirectNotifier>().user;
    if (user?.id == null || user?.role != UserRole.creativeProfessional) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final collaborations = await sl<CollaborationRepository>()
          .getCollaborationsByTargetUserId(user!.id);
      final invited = await sl<BookingRepository>()
          .getInvitedBookingsByCreativeId(user.id);
      final pending = await sl<BookingRepository>()
          .getPendingBookingsByCreativeId(user.id);
      final accepted = await sl<BookingRepository>()
          .getAcceptedBookingsByCreativeId(user.id);
      final completed = await sl<BookingRepository>()
          .getCompletedBookingsByCreativeId(user.id);
      final eventRepo = sl<EventRepository>();
      final eventIds = {
        ...invited.map((b) => b.eventId),
        ...pending.map((b) => b.eventId),
        ...accepted.map((b) => b.eventId),
        ...completed.map((b) => b.eventId),
      };
      final events = <String, EventEntity?>{};
      for (final id in eventIds) {
        events[id] = await eventRepo.getEventById(id);
      }
      final requesterIds = collaborations
          .map((c) => c.requesterId)
          .toSet()
          .toList();
      final requesterNames = <String, String>{};
      final requesterPhotoUrls = <String, String?>{};
      final requesterRoles = <String, UserRole?>{};
      for (final id in requesterIds) {
        final u = await sl<UserRepository>().getUser(id);
        requesterNames[id] = u?.displayName ?? u?.email ?? 'Someone';
        requesterPhotoUrls[id] = u?.photoUrl;
        requesterRoles[id] = u?.role;
      }
      final filtered = collaborations
          .where((c) => c.status != CollaborationStatus.declined)
          .toList();
      final sorted = List<CollaborationEntity>.from(filtered)
        ..sort((a, b) {
          final order = {
            CollaborationStatus.pending: 0,
            CollaborationStatus.accepted: 1,
            CollaborationStatus.completed: 2,
          };
          final diff = (order[a.status] ?? 2) - (order[b.status] ?? 2);
          if (diff != 0) return diff;
          final da = a.createdAt ?? DateTime(0);
          final db = b.createdAt ?? DateTime(0);
          return db.compareTo(da);
        });
      if (mounted) {
        setState(() {
          _collaborations = sorted;
          _requesterNames = requesterNames;
          _requesterPhotoUrls = requesterPhotoUrls;
          _requesterRoles = requesterRoles;
          _invited = invited;
          _applications = pending;
          _accepted = accepted;
          _completed = completed;
          _events = events;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _acceptInvitation(BookingEntity booking) async {
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
      final eventTitle = _events[booking.eventId]?.title ?? 'Event';
      final user = sl<AuthRedirectNotifier>().user;
      final accepterName =
          user?.displayName ?? user?.username ?? user?.email ?? 'Someone';
      sl<PushNotificationService>().notifyUser(
        targetUserId: booking.plannerId,
        title: 'Invitation accepted',
        body: '$accepterName accepted your invitation to $eventTitle',
        data: {
          'route': '/event/${booking.eventId}/applicants',
          'bookingId': booking.id,
          'eventId': booking.eventId,
          'type': 'booking_invitation_accepted',
        },
      );
      if (mounted) {
        showToast(context, 'Invitation accepted');
        _load();
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

  Future<void> _declineInvitation(BookingEntity booking) async {
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
      final eventTitle = _events[booking.eventId]?.title ?? 'Event';
      final user = sl<AuthRedirectNotifier>().user;
      final declinerName =
          user?.displayName ?? user?.username ?? user?.email ?? 'Someone';
      sl<PushNotificationService>().notifyUser(
        targetUserId: booking.plannerId,
        title: 'Invitation declined',
        body: '$declinerName declined your invitation to $eventTitle',
        data: {
          'route': '/event/${booking.eventId}/applicants',
          'bookingId': booking.id,
          'eventId': booking.eventId,
          'type': 'booking_invitation_declined',
        },
      );
      if (mounted) {
        showToast(context, 'Invitation declined');
        _load();
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

  Future<void> _confirmCompletionByCreative(BookingEntity booking) async {
    setState(() => _confirmingBookingId = booking.id);
    try {
      await sl<BookingRepository>().confirmCompletionByCreative(booking.id);
      if (mounted) {
        showToast(context, 'Confirmed completion');
        _load();
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _confirmingBookingId = null);
    }
  }

  Future<void> _acceptCollaboration(CollaborationEntity c) async {
    try {
      await sl<CollaborationRepository>().updateStatus(
        c.id,
        CollaborationStatus.accepted,
      );
      final user = sl<AuthRedirectNotifier>().user;
      final accepterName =
          user?.displayName ?? user?.username ?? user?.email ?? 'Someone';
      sl<PushNotificationService>().notifyUser(
        targetUserId: c.requesterId,
        title: 'Proposal accepted',
        body: '$accepterName accepted your proposal',
        data: {
          'route': '/collaboration/detail',
          'collaborationId': c.id,
          'type': 'collaboration_accepted',
        },
      );
      if (mounted) {
        showToast(context, 'Proposal accepted');
        context.go(AppRoutes.messages);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.push(AppRoutes.chatWithUser(c.requesterId));
          }
        });
        _load();
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

  Future<void> _declineCollaboration(CollaborationEntity c) async {
    try {
      await sl<CollaborationRepository>().updateStatus(
        c.id,
        CollaborationStatus.declined,
      );
      final user = sl<AuthRedirectNotifier>().user;
      final declinerName =
          user?.displayName ?? user?.username ?? user?.email ?? 'Someone';
      sl<PushNotificationService>().notifyUser(
        targetUserId: c.requesterId,
        title: 'Proposal declined',
        body: '$declinerName declined your proposal',
        data: {
          'route': '/collaboration/detail',
          'collaborationId': c.id,
          'type': 'collaboration_declined',
        },
      );
      if (mounted) {
        showToast(context, 'Proposal declined');
        _load();
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed: $e', isError: true);
      }
    }
  }

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
    if (user.role != UserRole.creativeProfessional) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gigs')),
        body: EmptyStateIllustrated(
          assetPathDark: 'assets/images/no_gigs_empty_dark.svg',
          assetPathLight: 'assets/images/no_gigs_empty_light.svg',
          headline: "No gigs yet — let's find events to book!",
          description: 'Browse events and apply to get booked.',
          primaryLabel: 'Browse events',
          onPrimaryPressed: () => context.go(AppRoutes.explore),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gigs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gigs'),
            Tab(text: 'Collaborations'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CustomMaterialIndicator(
            onRefresh: _load,
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
            child: _buildGigsBody(),
          ),
          CustomMaterialIndicator(
            onRefresh: _load,
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
            child: _buildCollaborationsBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildGigsBody() {
    final hasInvited = _invited.isNotEmpty;
    final hasApplications = _applications.isNotEmpty;
    final hasAccepted = _accepted.isNotEmpty;
    final hasCompleted = _completed.isNotEmpty;
    final hasAnyGigs =
        hasInvited || hasApplications || hasAccepted || hasCompleted;

    if (_loading && !hasAnyGigs && _error == null) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) => const BookingEventTileSkeleton(),
      );
    }
    if (!hasAnyGigs && _error == null) {
      return EmptyStateIllustrated(
        assetPathDark: 'assets/images/no_gigs_empty_dark.svg',
        assetPathLight: 'assets/images/no_gigs_empty_light.svg',
        headline: "No gigs yet — let's find events to book!",
        description: 'Browse events and apply to get booked.',
        primaryLabel: 'Browse events',
        onPrimaryPressed: () => context.go(AppRoutes.explore),
      );
    }
    final gigsBody = !hasAnyGigs
        ? ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 96),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => const BookingEventTileSkeleton(),
          )
        : _buildGigsSliverList();
    return ConnectionErrorOverlay(
      hasError: _error != null,
      error: _error,
      onRefresh: () async => _load(),
      onBack: () => context.go(AppRoutes.home),
      child: gigsBody,
    );
  }

  Widget _buildCollaborationsBody() {
    if (_loading && _collaborations.isEmpty && _error == null) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) =>
            const CollaborationProposalTileSkeleton(),
      );
    }
    if (_collaborations.isEmpty && _error == null) {
      return EmptyStateIllustrated(
        assetPathDark: 'assets/images/no_gigs_empty_dark.svg',
        assetPathLight: 'assets/images/no_gigs_empty_light.svg',
        headline: 'No collaboration proposals yet',
        description:
            'When someone sends you a collaboration proposal, it will appear here.',
        primaryLabel: 'Browse events',
        onPrimaryPressed: () => context.go(AppRoutes.explore),
      );
    }
    final activeCollabs = _collaborations
        .where(
          (c) =>
              c.status == CollaborationStatus.pending ||
              c.status == CollaborationStatus.accepted,
        )
        .toList();
    final pastCollabs = _collaborations
        .where((c) => c.status == CollaborationStatus.completed)
        .toList();
    final collabBody = _collaborations.isEmpty
        ? ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 96),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) =>
                const CollaborationProposalTileSkeleton(),
          )
        : _buildCollaborationsSliverList(
            active: activeCollabs,
            past: pastCollabs,
          );
    return ConnectionErrorOverlay(
      hasError: _error != null,
      error: _error,
      onRefresh: () async => _load(),
      onBack: () => context.go(AppRoutes.home),
      child: collabBody,
    );
  }

  Widget _buildCollaborationsSliverList({
    required List<CollaborationEntity> active,
    required List<CollaborationEntity> past,
  }) {
    final slivers = <Widget>[
      const SliverPadding(
        padding: EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 8),
      ),
    ];
    if (active.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
            final requesterName = _requesterNames[c.requesterId] ?? 'Someone';
            final requesterPhotoUrl = _requesterPhotoUrls[c.requesterId];
            return _CollaborationProposalTile(
              collaboration: c,
              requesterName: requesterName,
              requesterPhotoUrl: requesterPhotoUrl,
              requesterRole: _requesterRoles[c.requesterId],
              onAccept: () => _acceptCollaboration(c),
              onDecline: () => _declineCollaboration(c),
              onViewMore: () => context.push(
                AppRoutes.collaborationDetail,
                extra: {
                  'collaboration': c,
                  'otherPersonName': requesterName,
                  'otherPersonId': c.requesterId,
                  'otherPersonRole': _requesterRoles[c.requesterId],
                  'viewerIsCreative': true,
                  'otherPersonPhotoUrl': requesterPhotoUrl,
                },
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
            final requesterName = _requesterNames[c.requesterId] ?? 'Someone';
            final requesterPhotoUrl = _requesterPhotoUrls[c.requesterId];
            return _CollaborationProposalTile(
              collaboration: c,
              requesterName: requesterName,
              requesterPhotoUrl: requesterPhotoUrl,
              requesterRole: _requesterRoles[c.requesterId],
              onAccept: () => _acceptCollaboration(c),
              onDecline: () => _declineCollaboration(c),
              onViewMore: () => context.push(
                AppRoutes.collaborationDetail,
                extra: {
                  'collaboration': c,
                  'otherPersonName': requesterName,
                  'otherPersonId': c.requesterId,
                  'otherPersonRole': _requesterRoles[c.requesterId],
                  'viewerIsCreative': true,
                  'otherPersonPhotoUrl': requesterPhotoUrl,
                },
              ),
            );
          }, childCount: past.length),
        ),
      );
    }
    slivers.add(
      const SliverPadding(
        padding: EdgeInsets.only(top: 8, left: 0, right: 0, bottom: 96),
      ),
    );
    return CustomScrollView(slivers: slivers);
  }

  Widget _buildGigsSliverList() {
    final hasInvited = _invited.isNotEmpty;
    final hasApplications = _applications.isNotEmpty;
    final hasAccepted = _accepted.isNotEmpty;
    final hasCompleted = _completed.isNotEmpty;
    return CustomScrollView(
      slivers: [
        if (hasInvited) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Invitations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final booking = _invited[index];
              return _BookingEventTile(
                booking: booking,
                event: _events[booking.eventId],
                status: BookingStatus.invited,
                onTap: () =>
                    context.push(AppRoutes.eventDetail(booking.eventId)),
                onAccept: () => _acceptInvitation(booking),
                onDecline: () => _declineInvitation(booking),
              );
            }, childCount: _invited.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        if (hasAccepted) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, hasInvited ? 0 : 16, 16, 8),
              child: Text(
                'Accepted',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _BookingEventTile(
                booking: _accepted[index],
                event: _events[_accepted[index].eventId],
                status: BookingStatus.accepted,
                onTap: () => context.push(
                  AppRoutes.eventDetail(_accepted[index].eventId),
                ),
              ),
              childCount: _accepted.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        if (hasApplications) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                (hasInvited || hasAccepted) ? 0 : 16,
                16,
                8,
              ),
              child: Text(
                'Applications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _BookingEventTile(
                booking: _applications[index],
                event: _events[_applications[index].eventId],
                status: BookingStatus.pending,
                onTap: () => context.push(
                  AppRoutes.eventDetail(_applications[index].eventId),
                ),
              ),
              childCount: _applications.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        if (hasCompleted) ...[
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
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final booking = _completed[index];
              return _BookingEventTile(
                booking: booking,
                event: _events[booking.eventId],
                status: BookingStatus.completed,
                onTap: () =>
                    context.push(AppRoutes.eventDetail(booking.eventId)),
                canLeaveReview: false,
                onLeaveReview: null,
                canConfirmCompletion: booking.creativeConfirmedAt == null,
                hasConfirmedCompletion: booking.creativeConfirmedAt != null,
                onConfirmCompletion: () =>
                    _confirmCompletionByCreative(booking),
                isConfirmingCompletion: _confirmingBookingId == booking.id,
              );
            }, childCount: _completed.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ],
    );
  }
}

class _CollaborationProposalTile extends StatelessWidget {
  const _CollaborationProposalTile({
    required this.collaboration,
    required this.requesterName,
    this.requesterPhotoUrl,
    this.requesterRole,
    required this.onAccept,
    required this.onDecline,
    required this.onViewMore,
  });

  final CollaborationEntity collaboration;
  final String requesterName;
  final String? requesterPhotoUrl;
  final UserRole? requesterRole;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onViewMore;

  static String _dateText(DateTime? d) {
    if (d == null) return '—';
    return '${d.month}/${d.day}/${d.year}';
  }

  static String _relativeDateText(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final then = DateTime(d.year, d.month, d.day);
    final diff = today.difference(then).inDays;
    if (diff == 0) return 'Received today';
    if (diff == 1) return 'Received yesterday';
    if (diff < 7) return 'Received $diff days ago';
    if (diff < 30) return 'Received ${(diff / 7).floor()} weeks ago';
    if (diff < 365) return 'Received ${(diff / 30).floor()} months ago';
    return 'Received ${(diff / 365).floor()} years ago';
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

  List<Widget> _buildTopChips(ColorScheme colorScheme) {
    final chips = <Widget>[];
    if (collaboration.eventType != null) {
      chips.add(
        AppDetailChip(
          icon: Icons.event_outlined,
          label: collaboration.eventType!,
          colorScheme: colorScheme,
        ),
      );
    }
    if (chips.length < 3 && collaboration.date != null) {
      chips.add(
        AppDetailChip(
          icon: Icons.calendar_today_outlined,
          label: _dateText(collaboration.date),
          colorScheme: colorScheme,
        ),
      );
    }
    if (chips.length < 3 && collaboration.budget != null) {
      chips.add(
        AppDetailChip(
          icon: Icons.attach_money_outlined,
          label: '${NumberFormatter.formatMoney(collaboration.budget!)} RWF',
          colorScheme: colorScheme,
        ),
      );
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final descriptionSnippet = collaboration.description.length > 80
        ? '${collaboration.description.substring(0, 80)}...'
        : collaboration.description;
    final dateStr = _relativeDateText(collaboration.createdAt);
    final topChips = _buildTopChips(colorScheme);
    final status = collaboration.status;
    final statusBg = status == CollaborationStatus.pending
        ? colorScheme.tertiaryContainer
        : status == CollaborationStatus.accepted
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final statusFg = status == CollaborationStatus.pending
        ? colorScheme.onTertiaryContainer
        : status == CollaborationStatus.accepted
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: onViewMore,
        borderRadius: AppBorders.borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(
                  photoUrl: requesterPhotoUrl,
                  displayName: requesterName,
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              requesterName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(
                                AppBorders.chipRadius,
                              ),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: statusFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              descriptionSnippet,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (topChips.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: topChips),
            ],
            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onViewMore,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('View details'),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                if (status == CollaborationStatus.pending)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 40),
                          foregroundColor: colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onAccept,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingEventTile extends StatelessWidget {
  const _BookingEventTile({
    required this.booking,
    required this.event,
    required this.status,
    required this.onTap,
    this.canLeaveReview = false,
    this.onLeaveReview,
    this.canConfirmCompletion = false,
    this.hasConfirmedCompletion = false,
    this.onConfirmCompletion,
    this.isConfirmingCompletion = false,
    this.onAccept,
    this.onDecline,
  });

  final BookingEntity booking;
  final EventEntity? event;
  final BookingStatus status;
  final VoidCallback onTap;
  final bool canLeaveReview;
  final VoidCallback? onLeaveReview;
  final bool canConfirmCompletion;
  final bool hasConfirmedCompletion;
  final VoidCallback? onConfirmCompletion;
  final bool isConfirmingCompletion;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  static const double _imageSize = 88;

  static String _dateText(DateTime? d) {
    if (d == null) return '—';
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = event?.title ?? 'Event';
    final eventType = event?.eventType ?? '';
    final dateStr = _dateText(event?.date);
    final imageUrl = event?.imageUrls.isNotEmpty == true
        ? event!.imageUrls.first
        : null;

    final isInvited = status == BookingStatus.invited;
    final isAccepted = status == BookingStatus.accepted;
    final isCompleted = status == BookingStatus.completed;
    final statusLabel = isCompleted
        ? 'Completed'
        : isInvited
        ? 'Invitation'
        : isAccepted
        ? 'Accepted'
        : 'Applied';
    final statusColor = isCompleted
        ? colorScheme.secondary
        : isInvited
        ? colorScheme.tertiary
        : isAccepted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    // Status as subtle text (information, not action)
    final statusText = Text(
      statusLabel,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: statusColor,
      ),
    );

    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    const pillSpacing = SizedBox(width: 8);
    final buttonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minimumSize: const Size(0, 28),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: pillShape,
    );
    final tonalStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minimumSize: const Size(0, 28),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: pillShape,
    );

    late final Widget actionWidget;
    if (isInvited && onAccept != null && onDecline != null) {
      actionWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: onDecline,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: pillShape,
            ),
            child: const Text('Decline'),
          ),
          pillSpacing,
          FilledButton(
            onPressed: onAccept,
            style: buttonStyle,
            child: const Text('Accept'),
          ),
        ],
      );
    } else if (isCompleted &&
        (canConfirmCompletion || hasConfirmedCompletion || canLeaveReview)) {
      actionWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canConfirmCompletion || hasConfirmedCompletion) ...[
            FilledButton.tonal(
              onPressed: hasConfirmedCompletion
                  ? null
                  : (isConfirmingCompletion ? null : onConfirmCompletion),
              style: hasConfirmedCompletion
                  ? tonalStyle.copyWith(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    )
                  : tonalStyle,
              child: hasConfirmedCompletion
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 18),
                        const SizedBox(width: 6),
                        const Text('Confirmed'),
                      ],
                    )
                  : isConfirmingCompletion
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: LoadingAnimationWidget.stretchedDots(
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    )
                  : const Text('Confirm'),
            ),
            if (canLeaveReview && onLeaveReview != null) pillSpacing,
          ],
          if (canLeaveReview && onLeaveReview != null)
            FilledButton(
              onPressed: onLeaveReview,
              style: buttonStyle,
              child: const Text('Leave review'),
            ),
        ],
      );
    } else {
      actionWidget = FilledButton.tonal(
        onPressed: onTap,
        style: tonalStyle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('View details'),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, size: 12, color: colorScheme.primary),
          ],
        ),
      );
    }

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorders.borderRadius,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: _imageSize,
                height: _imageSize,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_outlined, size: 32),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.event_outlined, size: 32),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      statusText,
                    ],
                  ),
                  if (eventType.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      eventType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  actionWidget,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
