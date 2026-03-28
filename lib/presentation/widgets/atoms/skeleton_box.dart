import 'package:flutter/material.dart';

import '../../../core/constants/app_borders.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A skeleton placeholder box with optional shimmer animation.
/// Use to indicate loading content.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shimmer = true,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final skeletonColor = isLight
        ? colorScheme.onSurface.withValues(alpha: 0.15)
        : colorScheme.surfaceContainerHighest;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: skeletonColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppBorders.chipRadius),
      ),
    );
    if (shimmer) {
      return box
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1500.ms,
            color: colorScheme.surface.withValues(alpha: 0.6),
          );
    }
    return box;
  }
}
