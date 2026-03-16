import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/atoms/glass_card.dart';
import '../../core/constants/app_borders.dart';
import '../../core/constants/app_icons.dart';
import '../widgets/molecules/connection_error_overlay.dart';
import '../widgets/molecules/empty_state_dotted.dart';
import '../widgets/molecules/app_filter_chip.dart';
import '../widgets/molecules/skeleton_loaders.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/router/auth_redirect.dart';
import '../../core/utils/event_date_utils.dart';
import '../../core/utils/event_location_utils.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/planner_profile_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/services/event_recommendation.dart';
import '../../domain/repositories/planner_profile_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../bloc/profiles/profiles_bloc.dart';
import '../bloc/profiles/profiles_state.dart';
import '../widgets/molecules/vendor_card.dart';

/// Explore mode: Creatives or Events.
enum ExploreTab { creatives, events }

/// Event type filter for search (client-side). Most common categories first.
const List<String> _eventTypeFilters = [
  'All',
  'Wedding',
  'Music',
  'Corporate',
  'Party',
  'Conference',
  'Concert',
  'Workshop',
];

/// Top-level tab: Creatives or Event Planners.
enum _AccountTypeTab { creatives, eventPlanners }

/// Explore and discovery page. Role-based:
/// - Creatives: Events | Creatives (find gigs, discover creatives).
/// - Event Planners: Creatives | Event Planners (find creatives to hire, discover planners).
/// Event planners never see other planners' events or "Apply to collaborate".
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<AuthRedirectNotifier>(),
      builder: (context, _) {
        final currentUser = sl<AuthRedirectNotifier>().user;
        final currentUserId = currentUser?.id;
        final isEventPlanner = currentUser?.role == UserRole.eventPlanner;

        return BlocProvider(
          create: (_) => ProfilesBloc(
            sl<ProfileRepository>(),
            excludeUserId: currentUserId,
            onlyCreativeAccounts: true,
          )..add(ProfilesLoadRequested()),
          child: isEventPlanner
              ? _UnifiedExploreView(currentUserId: currentUserId)
              : const _ExploreView(),
        );
      },
    );
  }
}

/// Single explore view with Creatives | Event Planners tabs; both roles see the same.
class _UnifiedExploreView extends StatefulWidget {
  const _UnifiedExploreView({this.currentUserId});

  final String? currentUserId;

  @override
  State<_UnifiedExploreView> createState() => _UnifiedExploreViewState();
}

class _UnifiedExploreViewState extends State<_UnifiedExploreView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  _AccountTypeTab _accountTab = _AccountTypeTab.creatives;
  ProfileCategory? _selectedCategory;
  String? _selectedLocation;
  List<PlannerProfileEntity> _planners = [];
  bool _plannersLoading = false;
  String? _plannersError;

  static const List<(ProfileCategory?, String)> _categoryOptions = [
    (null, 'All'),
    (ProfileCategory.dj, 'Music'),
    (ProfileCategory.photographer, 'Photography'),
    (ProfileCategory.decorator, 'Decorator'),
    (ProfileCategory.contentCreator, 'Content Creator'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ProfilesBloc>().add(
              ProfilesSearchQueryChanged(_searchController.text),
            );
      }
    });
  }

  Future<void> _loadPlanners() async {
    if (!mounted) return;
    setState(() {
      _plannersLoading = true;
      _plannersError = null;
    });
    try {
      final repo = sl<PlannerProfileRepository>();
      final list = await repo.getPlannerProfiles(
        limit: 50,
        excludeUserId: widget.currentUserId,
      );
      if (mounted) {
        setState(() {
          _planners = list;
          _plannersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plannersLoading = false;
          _plannersError = e.toString();
        });
      }
    }
  }

  void _showFilterSheet(BuildContext context) {
    var tempCategory = _selectedCategory;
    final locationController = TextEditingController(text: _selectedLocation ?? '');
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) {
        return GlassBottomSheet(
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Category',
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categoryOptions.map((opt) {
                          final isSelected = tempCategory == opt.$1;
                          return ChoiceChip(
                            label: Text(opt.$2),
                            selected: isSelected,
                            onSelected: (_) {
                              setModalState(() => tempCategory = opt.$1);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Location',
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Kigali, Rwanda',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                tempCategory = null;
                                locationController.clear();
                                setModalState(() {});
                              },
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = tempCategory;
                                  _selectedLocation = locationController.text.trim();
                                  if (_selectedLocation?.isEmpty == true) {
                                    _selectedLocation = null;
                                  }
                                });
                                context.read<ProfilesBloc>().add(
                                      ProfilesLoadRequested(
                                        category: _selectedCategory,
                                        location: _selectedLocation,
                                      ),
                                    );
                                Navigator.pop(ctx);
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        );
      },
    ).whenComplete(() => locationController.dispose());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.explore),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
            child: TextField(
              controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'DJs, bands, photographers...',
                        prefixIcon: Icon(
                          AppIcons.search,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppBorders.borderRadius,
                        ),
                        filled: true,
                isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppBorders.radius),
                    child: InkWell(
                      onTap: () => _showFilterSheet(context),
                      borderRadius: BorderRadius.circular(AppBorders.radius),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.tune,
                          size: 24,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SegmentedButton<_AccountTypeTab>(
                segments: const [
                  ButtonSegment<_AccountTypeTab>(
                    value: _AccountTypeTab.creatives,
                    label: Text('Creatives'),
                  ),
                  ButtonSegment<_AccountTypeTab>(
                    value: _AccountTypeTab.eventPlanners,
                    label: Text('Event Planners'),
                  ),
                ],
                selected: {_accountTab},
                onSelectionChanged: (Set<_AccountTypeTab> s) {
                  if (s.isNotEmpty) {
                    setState(() => _accountTab = s.first);
                    if (s.first == _AccountTypeTab.eventPlanners &&
                        _planners.isEmpty &&
                        !_plannersLoading) {
                      _loadPlanners();
                    }
                  }
                },
              ),
            ),
          ),
          if (_accountTab == _AccountTypeTab.creatives) ...[
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _categoryOptions.map((e) {
                    final isSelected = _selectedCategory == e.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppFilterChip(
                        label: e.$2,
                        selected: isSelected,
                        onTap: () {
                          setState(() => _selectedCategory = e.$1);
                          context.read<ProfilesBloc>().add(
                                ProfilesFilterChanged(category: e.$1),
                              );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Top Rated',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(
                          AppRoutes.exploreCreativesAll,
                          extra: {
                            'category': _selectedCategory,
                            'location': _selectedLocation,
                          },
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.seeAll),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            _PlannerCreativesList(),
          ] else ...[
            _EventPlannersList(
              planners: _planners,
              loading: _plannersLoading,
              error: _plannersError,
              onRefresh: _loadPlanners,
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
    );
  }
}

class _EventPlannersList extends StatelessWidget {
  const _EventPlannersList({
    required this.planners,
    required this.loading,
    this.error,
    required this.onRefresh,
  });

  final List<PlannerProfileEntity> planners;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading && planners.isEmpty) {
      return SliverFillRemaining(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlannerProfileCardSkeleton(),
          ),
        ),
      );
    }
    if (error != null && planners.isEmpty) {
      return SliverFillRemaining(
        child: ConnectionErrorOverlay(
          hasError: true,
          error: error,
          onRefresh: () async { onRefresh(); },
          onBack: () => context.go(AppRoutes.home),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PlannerProfileCardSkeleton(),
            ),
          ),
        ),
      );
    }
    if (planners.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: EmptyStateDotted(
              icon: AppIcons.person,
              headline: 'No event planners found',
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final planner = planners[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlannerProfileCard(
                planner: planner,
                onTap: () => context.push(
                  AppRoutes.plannerProfileView(planner.userId),
                ),
              ),
            );
          },
          childCount: planners.length,
        ),
      ),
    );
  }
}

class _PlannerProfileCard extends StatelessWidget {
  const _PlannerProfileCard({
    required this.planner,
    required this.onTap,
  });

  final PlannerProfileEntity planner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = planner.displayName ?? 'Event Planner';
    final role = planner.role ?? 'Event Planner';
    final location = planner.location.isNotEmpty ? planner.location : '—';
    final eventTypesStr = planner.eventTypes.isNotEmpty
        ? planner.eventTypes.take(3).join(', ')
        : null;

    const double imageSize = 96;
    const double imageRadius = AppBorders.radius;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorders.borderRadius,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(imageRadius),
                child: SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: planner.photoUrl != null &&
                          planner.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: planner.photoUrl!,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            AppIcons.person,
                            size: 44,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (eventTypesStr != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            AppIcons.event,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              eventTypesStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          AppIcons.location,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (eventTypesStr != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        eventTypesStr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
        ),
      ),
    );
  }
}

class _PlannerCreativesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesBloc, ProfilesState>(
        builder: (context, state) {
          if (state.status == ProfilesStatus.loading &&
              state.profiles.isEmpty) {
          return SliverFillRemaining(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: VendorCardSkeleton(),
              ),
            ),
          );
          }
          if (state.status == ProfilesStatus.error && state.profiles.isEmpty) {
          return SliverFillRemaining(
            child: ConnectionErrorOverlay(
              hasError: true,
              error: state.error,
              onRefresh: () async => context
                  .read<ProfilesBloc>()
                  .add(ProfilesLoadRequested()),
              onBack: () => context.go(AppRoutes.home),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: 6,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: VendorCardSkeleton(),
                ),
              ),
            ),
          );
          }

          final list = state.filteredProfiles;
          if (list.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: EmptyStateDotted(
                    icon: AppIcons.person,
                    headline: state.searchQuery.trim().isEmpty
                        ? 'No creatives found'
                        : 'No matches for "${state.searchQuery.trim()}"',
                  ),
                ),
              ),
            );
          }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
              final profile = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VendorCard(
                  profile: profile,
                  onTap: () => context.push(
                    AppRoutes.creativeProfileView(profile.userId),
                  ),
                ),
              );
            },
              childCount: list.length,
            ),
          ),
        );
      },
    );
  }
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  ExploreTab _tab = ExploreTab.events;
  ProfileCategory? _selectedCategory;
  String _selectedEventType = 'All';
  List<EventEntity> _events = [];
  bool _eventsLoading = false;
  String? _eventsError;
  Set<String> _acceptedEventIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadEvents();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ProfilesBloc>().add(
              ProfilesSearchQueryChanged(_searchController.text),
            );
      }
    });
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });
    try {
      final currentUserId = sl<AuthRedirectNotifier>().user?.id;
      final profileRepo = sl<ProfileRepository>();
      final eventRepo = sl<EventRepository>();
      final bookingRepo = sl<BookingRepository>();

      final profileFuture = currentUserId != null
          ? profileRepo.getProfileByUserId(currentUserId)
          : Future<ProfileEntity?>.value(null);
      final eventsFuture = eventRepo.fetchDiscoverableEvents(limit: 100);
      final acceptedFuture = currentUserId != null
          ? bookingRepo.getAcceptedBookingsByCreativeId(currentUserId)
          : Future<List<BookingEntity>>.value([]);

      final results =
          await Future.wait([profileFuture, eventsFuture, acceptedFuture]);
      final profile = results[0] as ProfileEntity?;
      var list = (results[1] as List<EventEntity>)
          .where(EventDateUtils.isUpcomingEvent)
          .toList();

      list.sort((a, b) {
        final scoreA = scoreEventForCreative(a, profile);
        final scoreB = scoreEventForCreative(b, profile);
        if (scoreB != scoreA) return scoreB.compareTo(scoreA);
        final dateA = a.date ?? DateTime(0);
        final dateB = b.date ?? DateTime(0);
        return dateA.compareTo(dateB);
      });

      final acceptedBookings = results[2] as List<BookingEntity>;
      final acceptedIds =
          acceptedBookings.map((b) => b.eventId).toSet();

      if (mounted) {
        setState(() {
          _events = list;
          _acceptedEventIds = acceptedIds;
          _eventsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _eventsLoading = false;
          _eventsError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<EventEntity> get _filteredEvents {
    if (_selectedEventType == 'All') return _events;
    return _events.where((e) {
      final t = (e.eventType).toLowerCase();
      final k = _selectedEventType.toLowerCase();
      return t.contains(k);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.explore),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CustomMaterialIndicator(
        onRefresh: () async {
          if (_tab == ExploreTab.events) await _loadEvents();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        useMaterialContainer: false,
        indicatorBuilder: (context, controller) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: LoadingAnimationWidget.threeRotatingDots(
            color: colorScheme.primary,
            size: 40,
          ),
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Find events, gigs, mixers...',
                  prefixIcon: Icon(AppIcons.search, color: colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: AppBorders.borderRadius,
                  ),
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:               SegmentedButton<ExploreTab>(
                segments: const [
                  ButtonSegment<ExploreTab>(
                    value: ExploreTab.events,
                    label: Text('Events'),
                  ),
                  ButtonSegment<ExploreTab>(
                    value: ExploreTab.creatives,
                    label: Text('Creatives'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (Set<ExploreTab> s) {
                  if (s.isNotEmpty) setState(() => _tab = s.first);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_tab == ExploreTab.creatives) ...[
            SliverToBoxAdapter(
              child: _CategoryChips(
                selected: _selectedCategory,
                onSelected: (c) {
                  setState(() => _selectedCategory = c);
                  context.read<ProfilesBloc>().add(
                        ProfilesFilterChanged(category: c),
                      );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            _CreativesList(),
          ] else ...[
            SliverToBoxAdapter(
              child: _EventTypeChips(
                selected: _selectedEventType,
                onSelected: (s) => setState(() => _selectedEventType = s),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Upcoming',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            _EventsList(
              events: _filteredEvents,
              acceptedEventIds: _acceptedEventIds,
              loading: _eventsLoading,
              error: _eventsError,
              onRefresh: _loadEvents,
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.onSelected,
  });

  final ProfileCategory? selected;
  final ValueChanged<ProfileCategory?> onSelected;

  /// Most common creative categories first.
  static const List<(ProfileCategory?, String)> _options = [
    (null, 'All'),
    (ProfileCategory.photographer, 'Photographer'),
    (ProfileCategory.dj, 'DJ'),
    (ProfileCategory.contentCreator, 'Content Creator'),
    (ProfileCategory.decorator, 'Decorator'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((e) {
          final isSelected = selected == e.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppFilterChip(
              label: e.$2,
              selected: isSelected,
              onTap: () => onSelected(e.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EventTypeChips extends StatelessWidget {
  const _EventTypeChips({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _eventTypeFilters.map((s) {
          final isSelected = selected == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppFilterChip(
              label: s,
              selected: isSelected,
              onTap: () => onSelected(s),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Creatives tab list: only creative accounts (from profiles collection);
/// current user is always excluded.
class _CreativesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = sl<AuthRepository>().currentUser?.id;
    return BlocBuilder<ProfilesBloc, ProfilesState>(
      builder: (context, state) {
        if (state.status == ProfilesStatus.loading &&
            state.profiles.isEmpty) {
          return SliverFillRemaining(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: VendorCardSkeleton(),
              ),
            ),
          );
        }
        if (state.status == ProfilesStatus.error && state.profiles.isEmpty) {
          return SliverFillRemaining(
            child: ConnectionErrorOverlay(
              hasError: true,
              error: state.error,
              onRefresh: () async => context
                  .read<ProfilesBloc>()
                  .add(ProfilesLoadRequested()),
              onBack: () => context.go(AppRoutes.home),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: 6,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: VendorCardSkeleton(),
                ),
              ),
            ),
          );
        }

        // Only creative accounts (profiles collection); never show current user.
        final list = state.filteredProfiles
            .where((p) => currentUserId == null || p.userId != currentUserId)
            .toList();
        if (list.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                state.searchQuery.trim().isEmpty
                    ? 'No creatives found'
                    : 'No matches for "${state.searchQuery.trim()}"',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final profile = list[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VendorCard(
                    profile: profile,
                    onTap: () => context.push(
                      AppRoutes.creativeProfileView(profile.userId),
                    ),
                  ),
                );
              },
              childCount: list.length,
            ),
          ),
        );
      },
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({
    required this.events,
    required this.acceptedEventIds,
    required this.loading,
    this.error,
    required this.onRefresh,
  });

  final List<EventEntity> events;
  final Set<String> acceptedEventIds;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading && events.isEmpty) {
      return SliverFillRemaining(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 6,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ExploreEventCardSkeleton(),
          ),
        ),
      );
    }
    if (error != null && events.isEmpty) {
      return SliverFillRemaining(
        child: ConnectionErrorOverlay(
          hasError: true,
          error: error,
          onRefresh: () async { onRefresh(); },
          onBack: () => context.go(AppRoutes.home),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            itemCount: 6,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: ExploreEventCardSkeleton(),
            ),
          ),
        ),
      );
    }
    if (events.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: EmptyStateDotted(
              icon: AppIcons.event,
              headline: 'No upcoming events',
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = events[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
                  child: _ExploreEventCard(
                event: event,
                hasAcceptedBooking: acceptedEventIds.contains(event.id),
                onTap: () => context.push(AppRoutes.eventDetail(event.id)),
              ),
            );
          },
          childCount: events.length,
        ),
      ),
    );
  }
}

class _ExploreEventCard extends StatelessWidget {
  const _ExploreEventCard({
    required this.event,
    required this.hasAcceptedBooking,
    required this.onTap,
  });

  final EventEntity event;
  final bool hasAcceptedBooking;
  final VoidCallback onTap;

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final weekday = d.weekday - 1;
    if (weekday < 0 || weekday >= days.length) return '—';
    return '${days[weekday]}, ${d.month.toString().padLeft(2, '0')}/${d.day}';
  }

  static String _formatTime(String stored) {
    if (stored.isEmpty) return '';
    final parts = stored.split(RegExp(r'[:\s]')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final period = h < 12 ? 'AM' : 'PM';
        return ' • ${hour.toString()}:${m.toString().padLeft(2, '0')} $period';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = _formatDate(event.date);
    final timeStr = _formatTime(event.startTime);
    final location = getEventLocationDisplayLine(
      event,
      isPlanner: false,
      hasAcceptedBooking: hasAcceptedBooking,
    );
    final typeRaw = event.eventType.trim();
    final hasType = typeRaw.isNotEmpty;
    final typeLabel = hasType
        ? (typeRaw.length == 1
            ? typeRaw.toUpperCase()
            : '${typeRaw[0].toUpperCase()}${typeRaw.substring(1)}')
        : '';

    return GlassCard(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHighest,
                  child: event.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: event.imageUrls.first,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            AppIcons.event,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                if (hasType)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppBorders.radius),
                      ),
                      child: Text(
                        typeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dateStr$timeStr',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        AppIcons.location,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onTap,
                      child: const Text('Apply to collaborate'),
                    ),
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

/// Full-page list of creatives, reached from "See All" on the explore page.
class ExploreCreativesAllPage extends StatelessWidget {
  const ExploreCreativesAllPage({
    super.key,
    this.category,
    this.location,
  });

  final ProfileCategory? category;
  final String? location;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<AuthRedirectNotifier>(),
      builder: (context, _) {
        final currentUserId = sl<AuthRedirectNotifier>().user?.id;
        return BlocProvider(
          create: (_) => ProfilesBloc(
            sl<ProfileRepository>(),
            excludeUserId: currentUserId,
            onlyCreativeAccounts: true,
          )..add(ProfilesLoadRequested(category: category, location: location)),
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.allCreatives),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: BlocBuilder<ProfilesBloc, ProfilesState>(
              builder: (context, state) {
                if (state.status == ProfilesStatus.loading &&
                    state.profiles.isEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: 10,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: VendorCardSkeleton(),
                    ),
                  );
                }
                if (state.status == ProfilesStatus.error &&
                    state.profiles.isEmpty) {
                  return ConnectionErrorOverlay(
                    hasError: true,
                    error: state.error,
                    onRefresh: () async {
                      context.read<ProfilesBloc>().add(
                        ProfilesLoadRequested(
                          category: category,
                          location: location,
                        ),
                      );
                    },
                    onBack: () => context.pop(),
                    child: const SizedBox.shrink(),
                  );
                }
                final list = state.filteredProfiles;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: EmptyStateDotted(
                        icon: AppIcons.person,
                        headline: AppLocalizations.of(context)!.noCreativesFound,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final profile = list[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VendorCard(
                        profile: profile,
                        onTap: () => context.push(
                          AppRoutes.creativeProfileView(profile.userId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
