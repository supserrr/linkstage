import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../widgets/atoms/glass_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_borders.dart';
import '../../../core/utils/event_location_utils.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/followed_planners_repository.dart';
import '../../../domain/repositories/planner_profile_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/repositories/saved_creatives_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../bloc/creative_profile/creative_profile_cubit.dart';
import '../../bloc/creative_profile/creative_profile_state.dart';
import '../../bloc/planner_profile/planner_profile_cubit.dart';
import '../../bloc/planner_profile/planner_profile_state.dart';
import '../../widgets/atoms/section_header.dart';
import '../../widgets/molecules/empty_state_dotted.dart';
import '../../widgets/molecules/profile_avatar.dart';

void _shareProfile(BuildContext context, String userId) {
  final url = 'https://linkstage.app/profile/creative/$userId';
  final text = 'Check out this creative profile\n$url';
  Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    showToast(context, 'Profile link copied to clipboard');
  }
}

/// Public profile view - how your profile looks to others. Edit button opens edit page.
/// When [profileUserId] is set, shows that user's profile in read-only mode.
/// Use [profileRole] to show planner profile (e.g. when opening from event host); otherwise creative.
class ViewProfilePage extends StatelessWidget {
  const ViewProfilePage({super.key, this.profileUserId, this.profileRole});

  /// When non-empty, view this user's profile (read-only). Otherwise view own profile.
  final String? profileUserId;

  /// When viewing another user, use this to show planner profile. Omit for creative profile.
  final UserRole? profileRole;

  @override
  Widget build(BuildContext context) {
    final isViewingOther = profileUserId != null && profileUserId!.isNotEmpty;
    if (isViewingOther) {
      final isPlanner = profileRole == UserRole.eventPlanner;
      if (isPlanner) {
        return BlocProvider(
          create: (_) => PlannerProfileCubit(
            sl<UserRepository>(),
            sl<EventRepository>(),
            sl<BookingRepository>(),
            sl<CollaborationRepository>(),
            sl<ProfileRepository>(),
            sl<PlannerProfileRepository>(),
            profileUserId!,
            viewingUserId: sl<AuthRedirectNotifier>().user?.id,
          ),
          child: const _ViewProfileScaffold(
            showEditButton: false,
            child: _PlannerProfileView(),
          ),
        );
      }
      return BlocProvider(
        create: (_) => CreativeProfileCubit(
          sl<ProfileRepository>(),
          sl<ReviewRepository>(),
          sl<BookingRepository>(),
          sl<UserRepository>(),
          profileUserId!,
        ),
        child: const _ViewProfileScaffold(
          showEditButton: false,
          showShareFavorite: true,
          child: _CreativeProfileView(),
        ),
      );
    }

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
    final role = user.role;
    if (role == UserRole.creativeProfessional) {
      return BlocProvider(
        create: (_) => CreativeProfileCubit(
          sl<ProfileRepository>(),
          sl<ReviewRepository>(),
          sl<BookingRepository>(),
          sl<UserRepository>(),
          user.id,
        ),
        child: Builder(
          builder: (ctx) => _ViewProfileScaffold(
            editRoute: AppRoutes.creativeProfile,
            showEditButton: true,
            onReturnFromEdit: () => ctx.read<CreativeProfileCubit>().refresh(),
            child: const _CreativeProfileView(),
          ),
        ),
      );
    }
    if (role == UserRole.eventPlanner) {
      return BlocProvider(
        create: (_) => PlannerProfileCubit(
          sl<UserRepository>(),
          sl<EventRepository>(),
          sl<BookingRepository>(),
          sl<CollaborationRepository>(),
          sl<ProfileRepository>(),
          sl<PlannerProfileRepository>(),
          user.id,
          viewingUserId: user.id,
        ),
        child: Builder(
          builder: (ctx) => _ViewProfileScaffold(
            editRoute: AppRoutes.plannerProfile,
            showEditButton: true,
            onReturnFromEdit: () => ctx.read<PlannerProfileCubit>().refresh(),
            child: const _PlannerProfileView(),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Set up your profile first')),
    );
  }
}

class _ViewProfileScaffold extends StatelessWidget {
  const _ViewProfileScaffold({
    required this.child,
    this.editRoute,
    this.showEditButton = true,
    this.showShareFavorite = false,
    this.onReturnFromEdit,
  });

  final String? editRoute;
  final bool showEditButton;
  final bool showShareFavorite;
  final Widget child;
  final VoidCallback? onReturnFromEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: showShareFavorite ? null : const Text('Profile'),
        actions: [
          if (showEditButton && editRoute != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push(editRoute!);
                if (context.mounted) {
                  onReturnFromEdit?.call();
                }
              },
            )
          else if (showShareFavorite)
            Builder(
              builder: (context) {
                final cubit = context.read<CreativeProfileCubit>();
                final creativeUserId = cubit.state.profile?.userId;
                final currentUser = sl<AuthRedirectNotifier>().user;
                if (creativeUserId == null || currentUser == null) {
                  return IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      if (creativeUserId != null) {
                        _shareProfile(context, creativeUserId);
                      }
                    },
                  );
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => _shareProfile(context, creativeUserId),
                    ),
                    StreamBuilder<Set<String>>(
                      stream: sl<SavedCreativesRepository>()
                          .watchSavedCreativeIds(currentUser.id),
                      builder: (context, snapshot) {
                        final isSaved =
                            snapshot.hasData &&
                            snapshot.data!.contains(creativeUserId);
                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.red : null,
                          ),
                          onPressed: () async {
                            try {
                              await sl<SavedCreativesRepository>().toggleSaved(
                                currentUser.id,
                                creativeUserId,
                              );
                              if (context.mounted) {
                                showToast(
                                  context,
                                  isSaved
                                      ? 'Removed from saved'
                                      : 'Saved creative',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showToast(
                                  context,
                                  'Failed to update: $e',
                                  isError: true,
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
      body: child,
    );
  }
}

class _CreativeProfileView extends StatelessWidget {
  const _CreativeProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreativeProfileCubit, CreativeProfileState>(
      builder: (context, state) {
        if (state.isLoading && state.profile == null) {
          return Center(
            child: LoadingAnimationWidget.stretchedDots(
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
          );
        }
        final profile = state.profile;
        if (profile == null) {
          return const Center(child: Text('Profile not found'));
        }
        final authNotifier = sl<AuthRedirectNotifier>();
        final isViewingOther = authNotifier.user?.id != profile.userId;
        final photoUrl = isViewingOther
            ? profile.photoUrl
            : (authNotifier.user?.photoUrl ??
                  sl<AuthRepository>().currentUser?.photoUrl);
        final reviewCount = profile.reviewCount > 0
            ? profile.reviewCount
            : state.reviews.length;
        final rating = profile.rating > 0 ? profile.rating : null;
        final tags = profile.services.isNotEmpty
            ? profile.services
            : profile.professions;
        final titleText = _creativeTitle(profile);

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                isViewingOther ? 100 : 60,
              ),
              children: [
                ListenableBuilder(
                  listenable: authNotifier,
                  builder: (context, _) => _ProfilePhoto(
                    photoUrl: isViewingOther
                        ? photoUrl
                        : (authNotifier.user?.photoUrl ??
                              sl<AuthRepository>().currentUser?.photoUrl),
                    displayName: profile.displayName,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName ?? 'Creative Professional',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (titleText != null && titleText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    titleText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating != null
                          ? '${rating.toStringAsFixed(1)} (${NumberFormatter.formatInteger(reviewCount)} reviews)'
                          : '${NumberFormatter.formatInteger(reviewCount)} reviews',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (profile.location.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          profile.location,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: AppBorders.borderRadius,
                            ),
                            child: Text(
                              t,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const _SectionSeparator(),
                SectionHeader(title: 'About'),
                Text(
                  profile.bio.isNotEmpty ? profile.bio : 'No description yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const _SectionSeparator(),
                _PortfolioSection(
                  portfolioUrls: profile.portfolioUrls,
                  portfolioVideoUrls: profile.portfolioVideoUrls,
                  onSeeAll: () => context.push(
                    '${AppRoutes.profilePortfolio}?userId=${Uri.encodeComponent(profile.userId)}',
                  ),
                ),
                const _SectionSeparator(),
                SectionHeader(title: 'Recent Reviews'),
                if (state.reviews.isEmpty)
                  EmptyStateDotted(
                    icon: Icons.star_outline_rounded,
                    headline: 'No reviews yet',
                    description: 'Reviews will appear here.',
                    compact: true,
                  )
                else
                  ...state.reviews
                      .take(2)
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProfileReviewCard(
                            review: r,
                            reviewer: state.reviewAuthorsById[r.reviewerId],
                          ),
                        ),
                      ),
                if (state.reviews.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: () => context.push(
                        '${AppRoutes.profileReviews}?userId=${Uri.encodeComponent(profile.userId)}',
                      ),
                      child: const Text('See more reviews'),
                    ),
                  ),
                const _SectionSeparator(),
                SectionHeader(title: 'Past Work'),
                InkWell(
                  onTap: () {
                    final route = isViewingOther
                        ? AppRoutes.creativePastWork(profile.userId)
                        : '${AppRoutes.profilePastWork}?userId=${Uri.encodeComponent(profile.userId)}';
                    context.push(route);
                  },
                  borderRadius: AppBorders.borderRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'View past events and collaborations',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isViewingOther &&
                profile.userId != sl<AuthRedirectNotifier>().user?.id)
              _CollaborateBar(
                priceRange: profile.priceRange,
                creativeUserId: profile.userId,
              ),
          ],
        );
      },
    );
  }

  String? _creativeTitle(ProfileEntity profile) {
    if (profile.professions.isNotEmpty) {
      return profile.professions.join(' & ');
    }
    if (profile.category != null) {
      switch (profile.category!) {
        case ProfileCategory.dj:
          return 'DJ';
        case ProfileCategory.photographer:
          return 'Photographer';
        case ProfileCategory.decorator:
          return 'Decorator';
        case ProfileCategory.contentCreator:
          return 'Content Creator';
      }
    }
    return null;
  }
}

class _PortfolioSection extends StatelessWidget {
  const _PortfolioSection({
    required this.portfolioUrls,
    required this.portfolioVideoUrls,
    required this.onSeeAll,
  });

  final List<String> portfolioUrls;
  final List<String> portfolioVideoUrls;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      ...portfolioUrls.map(
        (url) => ClipRRect(
          borderRadius: AppBorders.borderRadius,
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
        ),
      ),
      ...portfolioVideoUrls.map(
        (_) => Container(
          decoration: BoxDecoration(
            borderRadius: AppBorders.borderRadius,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    ];
    final gridItems = items.take(4).toList();
    if (gridItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Portfolio',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (items.isNotEmpty)
              TextButton(onPressed: onSeeAll, child: const Text('See All')),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = (constraints.maxWidth - 8) / 2;
            final rowCount = (gridItems.length + 1) ~/ 2;
            final totalHeight = rowCount * cellSize + (rowCount - 1) * 8;
            return SizedBox(
              height: totalHeight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  gridItems.length,
                  (i) => SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: gridItems[i],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileReviewCard extends StatelessWidget {
  const _ProfileReviewCard({required this.review, this.reviewer});

  final ReviewEntity review;
  final UserEntity? reviewer;

  static String _reviewerName(UserEntity? u) {
    if (u == null) return 'Reviewer';
    final dn = u.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final un = u.username?.trim();
    if (un != null && un.isNotEmpty) {
      return un.startsWith('@') ? un : '@$un';
    }
    return 'Reviewer';
  }

  static String _formatReviewDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) {
      if (diff.inHours <= 0) {
        final m = diff.inMinutes.clamp(0, 9999);
        return '${m}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final name = _reviewerName(reviewer);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: AppBorders.borderRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileAvatar(
            photoUrl: reviewer?.photoUrl,
            displayName: name,
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (review.createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatReviewDate(review.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollaborateBar extends StatelessWidget {
  const _CollaborateBar({
    required this.priceRange,
    required this.creativeUserId,
  });

  final String priceRange;
  final String creativeUserId;

  static String _formatPriceWithRwf(String priceRange) {
    final formatted = NumberFormatter.formatNumbersInString(priceRange);
    return formatted.trimLeft().toUpperCase().startsWith('RWF')
        ? formatted
        : 'RWF $formatted';
  }

  Future<void> _onCollaborateTap(BuildContext context) async {
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) return;

    try {
      final repo = sl<CollaborationRepository>();
      final exists = await repo.hasActiveCollaborationBetween(
        user.id,
        creativeUserId,
      );
      if (!context.mounted) return;
      if (exists) {
        showToast(
          context,
          'An ongoing collaboration already exists with this creative',
        );
        return;
      }
      if (!context.mounted) return;
      context.go(AppRoutes.sendCollaboration(creativeUserId));
    } catch (e) {
      if (!context.mounted) return;
      showToast(
        context,
        'Something went wrong: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starting rate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          priceRange.isNotEmpty
                              ? _formatPriceWithRwf(priceRange)
                              : '—',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (priceRange.isNotEmpty)
                          Text(
                            priceRange.contains('/') ? '' : ' /hr',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _onCollaborateTap(context),
                  child: const Text('Collaborate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlannerProfileView extends StatelessWidget {
  const _PlannerProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlannerProfileCubit, PlannerProfileState>(
      builder: (context, state) {
        if (state.error != null &&
            state.user == null &&
            state.plannerProfile == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        context.read<PlannerProfileCubit>().refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.isLoading &&
            state.user == null &&
            state.plannerProfile == null) {
          return Center(
            child: LoadingAnimationWidget.stretchedDots(
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
          );
        }
        final authNotifier = sl<AuthRedirectNotifier>();
        // When Firestore user doc is missing (e.g. planner never had one created),
        // fall back to auth user for display when viewing own profile.
        final user =
            state.user ??
            (state.plannerProfile?.userId == authNotifier.user?.id
                ? authNotifier.user
                : null);
        if (user == null) {
          return const Center(child: Text('User not found'));
        }
        final isViewingOther =
            authNotifier.user?.id != null && authNotifier.user?.id != user.id;
        final plannerProfile = state.plannerProfile;
        final bio = plannerProfile?.bio ?? '';
        final eventTypes = plannerProfile?.eventTypes ?? [];
        final location = plannerProfile?.location ?? '';
        final bottomPadding = isViewingOther ? 180.0 : 60.0;
        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
              children: [
                ListenableBuilder(
                  listenable: authNotifier,
                  builder: (context, _) => _ProfilePhoto(
                    photoUrl: isViewingOther
                        ? user.photoUrl
                        : authNotifier.user?.photoUrl,
                    displayName: user.displayName,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName ?? 'Event Planner',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (user.username != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
                if (eventTypes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: eventTypes
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: AppBorders.borderRadius,
                            ),
                            child: Text(
                              t,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const _SectionSeparator(),
                SectionHeader(title: 'About'),
                Text(
                  bio.isNotEmpty ? bio : 'No description yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const _SectionSeparator(),
                SectionHeader(title: 'Current Events'),
                if (state.currentEvents.isEmpty)
                  EmptyStateDotted(
                    icon: Icons.event_outlined,
                    headline: 'No current events',
                    description: 'Active events will appear here.',
                    compact: true,
                  )
                else
                  ...state.currentEvents
                      .take(10)
                      .map(
                        (e) => _EventTile(
                          event: e,
                          viewerUserId: authNotifier.user?.id ?? '',
                          acceptedEventIdsForViewer:
                              state.acceptedEventIdsForViewer,
                        ),
                      ),
                const _SectionSeparator(),
                SectionHeader(title: 'Past Events'),
                _PastEventsContent(
                  pastEvents: state.pastEvents,
                  viewerUserId: authNotifier.user?.id ?? '',
                  acceptedEventIdsForViewer: state.acceptedEventIdsForViewer,
                ),
                const _SectionSeparator(),
                SectionHeader(title: 'Creatives I\'ve worked with'),
                if (state.recentCreatives.isEmpty)
                  EmptyStateDotted(
                    icon: Icons.people_outline,
                    headline: 'No creatives hired yet',
                    description: 'Creatives you work with will appear here.',
                    compact: true,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLowest
                          .withValues(alpha: 0.5),
                      borderRadius: AppBorders.borderRadius,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.start,
                      children: state.recentCreatives.map((p) {
                        final name = p.displayName ?? 'Creative Professional';
                        return Tooltip(
                          message: name,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.push(
                                AppRoutes.creativeProfileView(p.userId),
                              ),
                              customBorder: const CircleBorder(),
                              splashColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                              highlightColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                              child: ProfileAvatar(
                                photoUrl: p.photoUrl,
                                displayName: name,
                                radius: 24,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
            if (isViewingOther) const _PlannerViewCTABar(),
          ],
        );
      },
    );
  }
}

class _PlannerViewCTABar extends StatelessWidget {
  const _PlannerViewCTABar();

  @override
  Widget build(BuildContext context) {
    final state = context.read<PlannerProfileCubit>().state;
    final plannerUserId = state.user?.id ?? state.plannerProfile?.userId ?? '';
    final currentUser = sl<AuthRedirectNotifier>().user;
    final isCreative = currentUser?.role == UserRole.creativeProfessional;
    final currentUserId = currentUser?.id;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCreative &&
                    currentUserId != null &&
                    currentUserId.isNotEmpty &&
                    plannerUserId.isNotEmpty)
                  StreamBuilder<Set<String>>(
                    stream: sl<FollowedPlannersRepository>()
                        .watchFollowedPlannerIds(currentUserId),
                    builder: (context, snapshot) {
                      final followedIds = snapshot.data ?? {};
                      final isFollowing = followedIds.contains(plannerUserId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: isFollowing
                              ? OutlinedButton.icon(
                                  onPressed: () async {
                                    await sl<FollowedPlannersRepository>()
                                        .toggleFollow(
                                          currentUserId,
                                          plannerUserId,
                                        );
                                    if (context.mounted) {
                                      showToast(context, 'Unfollowed');
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    size: 20,
                                  ),
                                  label: const Text('Unfollow'),
                                )
                              : FilledButton.icon(
                                  onPressed: () async {
                                    await sl<FollowedPlannersRepository>()
                                        .toggleFollow(
                                          currentUserId,
                                          plannerUserId,
                                        );
                                    if (context.mounted) {
                                      showToast(
                                        context,
                                        'You are now following this planner',
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.person_add_outlined,
                                    size: 20,
                                  ),
                                  label: const Text('Follow'),
                                ),
                        ),
                      );
                    },
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (plannerUserId.isNotEmpty) {
                        context.push(AppRoutes.chatWithUser(plannerUserId));
                      } else {
                        context.push(AppRoutes.messages);
                      }
                    },
                    icon: const Icon(Icons.message_outlined, size: 20),
                    label: const Text('Contact planner'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({this.photoUrl, this.displayName});

  final String? photoUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ProfileAvatar(
        photoUrl: photoUrl,
        displayName: displayName,
        radius: 56,
      ),
    );
  }
}

class _SectionSeparator extends StatelessWidget {
  const _SectionSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.6),
        height: 1,
        thickness: 1,
      ),
    );
  }
}

class _PastEventsContent extends StatelessWidget {
  const _PastEventsContent({
    required this.pastEvents,
    required this.viewerUserId,
    required this.acceptedEventIdsForViewer,
  });

  final List<EventEntity> pastEvents;
  final String viewerUserId;
  final Set<String> acceptedEventIdsForViewer;

  @override
  Widget build(BuildContext context) {
    final visible = pastEvents.where((e) => e.showOnProfile).toList();
    if (visible.isEmpty) {
      return EmptyStateDotted(
        icon: Icons.event_outlined,
        headline: pastEvents.isEmpty
            ? 'No past events yet'
            : 'No past events shown on profile',
        description: pastEvents.isEmpty
            ? 'Completed events will appear here.'
            : 'Enable events in profile edit to show them.',
        compact: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visible
          .take(10)
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EventTile(
                event: e,
                viewerUserId: viewerUserId,
                acceptedEventIdsForViewer: acceptedEventIdsForViewer,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.viewerUserId,
    required this.acceptedEventIdsForViewer,
  });

  final EventEntity event;
  final String viewerUserId;
  final Set<String> acceptedEventIdsForViewer;

  @override
  Widget build(BuildContext context) {
    final dateStr = event.date != null
        ? '${event.date!.day}/${event.date!.month}/${event.date!.year}'
        : '—';
    final isPlanner =
        viewerUserId.isNotEmpty && viewerUserId == event.plannerId;
    final hasAccepted = acceptedEventIdsForViewer.contains(event.id);
    final locationLine = getEventLocationDisplayLine(
      event,
      isPlanner: isPlanner,
      hasAcceptedBooking: hasAccepted,
    );
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push(AppRoutes.eventDetail(event.id)),
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
            : Icon(
                Icons.event,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        title: Text(event.title),
        subtitle: Text('$locationLine · $dateStr'),
        trailing: Text(
          _statusLabel(event.status),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  String _statusLabel(EventStatus s) {
    switch (s) {
      case EventStatus.draft:
        return 'Draft';
      case EventStatus.open:
        return 'Open';
      case EventStatus.booked:
        return 'Booked';
      case EventStatus.completed:
        return 'Completed';
    }
  }
}
