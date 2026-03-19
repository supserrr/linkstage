import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../widgets/atoms/glass_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_borders.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../bloc/profile_reviews/profile_reviews_cubit.dart';
import '../../bloc/profile_reviews/profile_reviews_state.dart';
import '../../widgets/molecules/empty_state_dotted.dart';
import '../../widgets/molecules/profile_avatar.dart';

/// Dedicated screen showing all reviews for the creative's profile.
/// Supports reply, flag, and like.
class ProfileReviewsPage extends StatelessWidget {
  const ProfileReviewsPage({super.key, this.revieweeUserId = ''});

  /// When empty, loads reviews for the signed-in user (own profile).
  final String revieweeUserId;

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
    final revieweeId = revieweeUserId.isNotEmpty ? revieweeUserId : user.id;
    return BlocProvider(
      create: (_) => ProfileReviewsCubit(
        sl<ReviewRepository>(),
        sl<UserRepository>(),
        revieweeId,
        user.id,
      ),
      child: _ProfileReviewsView(viewerUserId: user.id),
    );
  }
}

class _ProfileReviewsView extends StatelessWidget {
  const _ProfileReviewsView({required this.viewerUserId});

  final String viewerUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: BlocConsumer<ProfileReviewsCubit, ProfileReviewsState>(
        listenWhen: (a, b) => a.error != b.error,
        listener: (context, state) {
          if (state.error != null) {
            showToast(context, state.error!, isError: true);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.reviews.isEmpty) {
            return Center(
              child: LoadingAnimationWidget.stretchedDots(
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
            );
          }
          if (state.reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: EmptyStateDotted(
                  icon: Icons.star_outline_rounded,
                  headline: 'No reviews yet',
                  description: 'Reviews from clients will appear here.',
                ),
              ),
            );
          }
          return CustomMaterialIndicator(
            onRefresh: () => context.read<ProfileReviewsCubit>().load(),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.reviews.length,
              itemBuilder: (context, index) {
                final r = state.reviews[index];
                return _ReviewCard(
                  review: r,
                  reviewer: state.reviewAuthorsById[r.reviewerId],
                  showReplyActions: viewerUserId == state.revieweeUserId,
                  onReply: () => _showReplyDialog(context, r),
                  onLike: () =>
                      context.read<ProfileReviewsCubit>().likeReview(r.id),
                  onFlag: () =>
                      context.read<ProfileReviewsCubit>().flagReview(r.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static void _showReplyDialog(BuildContext context, ReviewEntity review) {
    final controller = TextEditingController(text: review.reply);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => GlassBottomSheet(
        child: Padding(
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
                    'Reply to review',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Write your reply...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          Navigator.pop(ctx);
                          context.read<ProfileReviewsCubit>().addReply(
                            review.id,
                            text,
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    this.reviewer,
    required this.showReplyActions,
    required this.onReply,
    required this.onLike,
    required this.onFlag,
  });

  final ReviewEntity review;
  final UserEntity? reviewer;
  final bool showReplyActions;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onFlag;

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

  @override
  Widget build(BuildContext context) {
    final hasLiked = review.likedBy.contains(
      sl<AuthRedirectNotifier>().user?.id,
    );
    final hasFlagged = review.flaggedBy.contains(
      sl<AuthRedirectNotifier>().user?.id,
    );
    final name = _reviewerName(reviewer);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${review.rating}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        if (review.createdAt != null)
                          Text(
                            _formatDate(review.createdAt!),
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
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment),
          ],
          if (review.reply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppBorders.chipRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showReplyActions ? 'Your reply' : 'Reply from creative',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(review.reply),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (showReplyActions)
                TextButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('Reply'),
                ),
              TextButton.icon(
                onPressed: onLike,
                icon: Icon(
                  hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                  color: hasLiked
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                label: Text(NumberFormatter.formatInteger(review.likeCount)),
              ),
              TextButton.icon(
                onPressed: onFlag,
                icon: Icon(
                  hasFlagged ? Icons.flag : Icons.outlined_flag,
                  size: 18,
                  color: hasFlagged
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                label: const Text('Flag'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
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
}
