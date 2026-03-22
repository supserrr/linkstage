import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/profile_photo_upload/profile_photo_upload_cubit.dart';
import '../atoms/glass_card.dart';
import '../../../core/constants/app_borders.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/datasources/portfolio_storage_datasource.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../core/router/auth_redirect.dart';

/// Profile photo card with upload support.
class ProfilePhotoCard extends StatelessWidget {
  const ProfilePhotoCard({
    super.key,
    this.onPhotoUpdated,
    this.compact = false,
    this.inline = false,
  });

  /// Called after photo is updated (e.g. to refresh planner profile state).
  final VoidCallback? onPhotoUpdated;

  /// Use compact avatar size (28) instead of default (48).
  final bool compact;

  /// Inline layout (no center wrap).
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: AppBorders.borderRadius,
              ),
              child: Icon(
                Icons.person_outline,
                size: 22,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Profile photo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shown on your profile',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            BlocProvider(
              create: (_) => ProfilePhotoUploadCubit(),
              child: _ProfilePhotoSection(
                onPhotoUpdated: onPhotoUpdated,
                compact: compact,
                inline: inline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoSection extends StatelessWidget {
  const _ProfilePhotoSection({
    this.onPhotoUpdated,
    this.compact = false,
    this.inline = false,
  });

  final VoidCallback? onPhotoUpdated;
  final bool compact;
  final bool inline;

  Future<void> _changePhoto(BuildContext context) async {
    final uploadCubit = context.read<ProfilePhotoUploadCubit>();
    if (uploadCubit.state) return;
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (x == null || !context.mounted) return;
    uploadCubit.setUploading(true);
    try {
      final url = await sl<PortfolioStorageDataSource>().uploadProfilePhoto(
        x,
        user.id,
      );
      await sl<UserRepository>().upsertUser(
        UserEntity(
          id: user.id,
          email: user.email,
          emailVerified: user.emailVerified,
          username: user.username,
          displayName: user.displayName,
          photoUrl: url,
          role: user.role,
          lastUsernameChangeAt: user.lastUsernameChangeAt,
        ),
      );
      await sl<AuthRedirectNotifier>().refresh();
      onPhotoUpdated?.call();
    } catch (e) {
      if (context.mounted) {
        showToast(
          context,
          e.toString().replaceAll('Exception:', '').trim(),
          isError: true,
        );
      }
    } finally {
      if (context.mounted) {
        uploadCubit.setUploading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = sl<AuthRedirectNotifier>();
    final radius = compact ? 28.0 : 48.0;
    final iconSize = compact ? 28.0 : 48.0;
    return ListenableBuilder(
      listenable: authNotifier,
      builder: (context, _) {
        final photoUrl = authNotifier.user?.photoUrl;
        return BlocBuilder<ProfilePhotoUploadCubit, bool>(
          builder: (context, isUploading) {
            final stack = Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: radius,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(Icons.person, size: iconSize)
                      : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      padding: compact ? const EdgeInsets.all(4) : null,
                      minimumSize: compact ? const Size(28, 28) : null,
                    ),
                    icon: isUploading
                        ? SizedBox(
                            width: compact ? 16 : 24,
                            height: compact ? 16 : 24,
                            child: LoadingAnimationWidget.stretchedDots(
                              color: Theme.of(context).colorScheme.primary,
                              size: compact ? 16 : 24,
                            ),
                          )
                        : Icon(Icons.camera_alt, size: compact ? 18 : 24),
                    onPressed: isUploading ? null : () => _changePhoto(context),
                  ),
                ),
              ],
            );
            if (compact) return stack;
            if (inline) return stack;
            return Center(child: stack);
          },
        );
      },
    );
  }
}
