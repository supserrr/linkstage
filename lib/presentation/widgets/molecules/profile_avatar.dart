import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/image_url_utils.dart';

/// Avatar that displays profile photo with loading placeholder and error fallback.
/// Shows [displayName] initial or person icon when no photo or while loading.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    this.radius = 24,
    this.backgroundColor,
  });

  final String? photoUrl;
  final String? displayName;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = backgroundColor ?? colorScheme.tertiaryContainer;
    final size = radius * 2;
    final initial = displayName != null && displayName!.isNotEmpty
        ? displayName!.substring(0, 1).toUpperCase()
        : '?';

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: ImageUrlUtils.thumbnailUrl(
                  photoUrl!,
                  width: (radius * 2).round(),
                  height: (radius * 2).round(),
                ),
                fit: BoxFit.cover,
                placeholder: (context, url) => _Placeholder(
                  initial: initial,
                  colorScheme: colorScheme,
                  backgroundColor: bg,
                  fontSize: radius * 0.65,
                ),
                errorWidget: (context, url, error) => _Placeholder(
                  initial: initial,
                  colorScheme: colorScheme,
                  backgroundColor: bg,
                  fontSize: radius * 0.65,
                ),
              )
            : _Placeholder(
                initial: initial,
                colorScheme: colorScheme,
                backgroundColor: bg,
                fontSize: radius * 0.65,
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.initial,
    required this.colorScheme,
    required this.backgroundColor,
    this.fontSize = 24,
  });

  final String initial;
  final ColorScheme colorScheme;
  final Color backgroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: fontSize.clamp(14, 36),
        ),
      ),
    );
  }
}
