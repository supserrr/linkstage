import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/atoms/glass_card.dart';

import '../../core/constants/app_borders.dart';
import '../../core/constants/app_icons.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/router/auth_redirect.dart';
import '../../core/utils/toast_utils.dart';
import '../../domain/entities/planner_profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/followed_planners_repository.dart';
import '../bloc/following/following_page_cubit.dart';
import '../bloc/following/following_page_state.dart';
import '../widgets/molecules/connection_error_overlay.dart';
import '../widgets/molecules/empty_state_dotted.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/molecules/skeleton_loaders.dart';

/// Page for creatives to view and manage event planners they follow.
class FollowingPage extends StatelessWidget {
  const FollowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRedirectNotifier>().user;
    final isCreative = user?.role == UserRole.creativeProfessional;

    if (!isCreative) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Following'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Only creatives can follow event planners',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => FollowingPageCubit(),
      child: const _FollowingBody(),
    );
  }
}

class _FollowingBody extends StatefulWidget {
  const _FollowingBody();

  @override
  State<_FollowingBody> createState() => _FollowingBodyState();
}

class _FollowingBodyState extends State<_FollowingBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    final user = sl<AuthRedirectNotifier>().user;
    if (user?.role != UserRole.creativeProfessional || user?.id == null) {
      return;
    }
    if (!mounted) return;
    final cubit = context.read<FollowingPageCubit>();
    cubit.setLoading();
    try {
      final planners = await sl<FollowedPlannersRepository>()
          .getFollowedPlannerProfiles(user!.id);
      if (mounted) {
        cubit.setSuccess(planners);
      }
    } catch (e) {
      if (mounted) {
        cubit.setError(e.toString());
      }
    }
  }

  Future<void> _unfollow(String plannerId) async {
    final user = sl<AuthRedirectNotifier>().user;
    if (user?.id == null) return;
    await sl<FollowedPlannersRepository>().toggleFollow(user!.id, plannerId);
    if (mounted) {
      showToast(context, 'Unfollowed');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FollowingPageCubit, FollowingPageState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Following'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: state.loading && state.planners.isEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) =>
                      const FollowingPlannerCardSkeleton(),
                )
              : state.error != null && state.planners.isEmpty
              ? ConnectionErrorOverlay(
                  hasError: true,
                  error: state.error,
                  onRefresh: _load,
                  onBack: () => context.pop(),
                  child: const SizedBox.shrink(),
                )
              : state.planners.isEmpty
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
                          icon: Icons.person_add_outlined,
                          headline: 'No planners followed yet',
                          description:
                              'Follow event planners from their events or profiles to see them here',
                          primaryLabel: 'Browse events',
                          onPrimaryPressed: () => context.go(AppRoutes.explore),
                        ),
                      ),
                    ),
                  ),
                )
              : CustomMaterialIndicator(
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.planners.length,
                    itemBuilder: (context, index) {
                      final planner = state.planners[index];
                      return _FollowingPlannerCard(
                        planner: planner,
                        onTap: () => context.push(
                          AppRoutes.plannerProfileView(planner.userId),
                        ),
                        onUnfollow: () => _unfollow(planner.userId),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _FollowingPlannerCard extends StatelessWidget {
  const _FollowingPlannerCard({
    required this.planner,
    required this.onTap,
    required this.onUnfollow,
  });

  final PlannerProfileEntity planner;
  final VoidCallback onTap;
  final VoidCallback onUnfollow;

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

    const double imageSize = 72;
    const double imageRadius = AppBorders.radius;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
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
                child: planner.photoUrl != null && planner.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: planner.photoUrl!,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          AppIcons.person,
                          size: 36,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (eventTypesStr != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      eventTypesStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onUnfollow,
              child: const Text('Unfollow'),
            ),
          ],
        ),
      ),
    );
  }
}
