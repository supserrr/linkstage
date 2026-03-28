import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image_picker/image_picker.dart';

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
            _ProfilePhotoSection(
              onPhotoUpdated: onPhotoUpdated,
              compact: compact,
              inline: inline,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoSection extends StatefulWidget {
  const _ProfilePhotoSection({
    this.onPhotoUpdated,
    this.compact = false,
    this.inline = false,
  });

  final VoidCallback? onPhotoUpdated;
  final bool compact;
  final bool inline;

  @override
  State<_ProfilePhotoSection> createState() => _ProfilePhotoSectionState();
}

class _ProfilePhotoSectionState extends State<_ProfilePhotoSection> {
  bool _isUploading = false;

  Future<void> _changePhoto() async {
    if (_isUploading) return;
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;
    setState(() => _isUploading = true);
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
      widget.onPhotoUpdated?.call();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e.toString().replaceAll('Exception:', '').trim(),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = sl<AuthRedirectNotifier>();
    final radius = widget.compact ? 28.0 : 48.0;
    final iconSize = widget.compact ? 28.0 : 48.0;
    return ListenableBuilder(
      listenable: authNotifier,
      builder: (context, _) {
        final photoUrl = authNotifier.user?.photoUrl;
        final stack = Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  padding: widget.compact ? const EdgeInsets.all(4) : null,
                  minimumSize: widget.compact ? const Size(28, 28) : null,
                ),
                icon: _isUploading
                    ? SizedBox(
                        width: widget.compact ? 16 : 24,
                        height: widget.compact ? 16 : 24,
                        child: LoadingAnimationWidget.stretchedDots(
                        color: Theme.of(context).colorScheme.primary,
                        size: widget.compact ? 16 : 24,
                      ),
                      )
                    : Icon(Icons.camera_alt, size: widget.compact ? 18 : 24),
                onPressed: _isUploading ? null : _changePhoto,
              ),
            ),
          ],
        );
        if (widget.compact) return stack;
        if (widget.inline) return stack;
        return Center(child: stack);
      },
    );
  }
}
