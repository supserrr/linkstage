import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

import '../../../core/constants/app_borders.dart';

/// Reusable glass morphism card with theme-aware styling.
/// Replaces Material Card for a frosted glass aesthetic.
/// Falls back to a styled Card on Android where BackdropFilter causes blank screens.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  /// Android has known issues with BackdropFilter (blank/white screen).
  /// Use a regular Card fallback there.
  static bool get _useGlassEffect {
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.android;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_useGlassEffect) {
      return _FallbackCard(
        colorScheme: colorScheme,
        isDark: isDark,
        margin: margin,
        padding: padding,
        width: width,
        height: height,
        child: child,
      );
    }

    final gradient = LinearGradient(
      colors: isDark
          ? [
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.25),
                colorScheme.surface.withValues(alpha: 0.5),
              ),
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.15),
                colorScheme.surface.withValues(alpha: 0.2),
              ),
            ]
          : [
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.12),
                colorScheme.surface.withValues(alpha: 0.8),
              ),
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.08),
                colorScheme.surface.withValues(alpha: 0.4),
              ),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final borderGradient = LinearGradient(
      colors: [
        colorScheme.primary.withValues(alpha: 0.5),
        colorScheme.primary.withValues(alpha: 0.2),
        colorScheme.primary.withValues(alpha: 0.3),
        colorScheme.primary.withValues(alpha: 0.5),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.39, 0.4, 1.0],
    );

    return RepaintBoundary(
      child: GlassContainer(
        width: width,
        height: height,
        gradient: gradient,
        borderGradient: borderGradient,
        blur: 15.0,
        borderWidth: 1,
        borderRadius: AppBorders.borderRadius,
        isFrostedGlass: true,
        frostedOpacity: 0.12,
        margin: margin,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Wrapper for bottom sheet content to apply glass morphism styling.
/// Use as the root widget returned from showModalBottomSheet's builder.
/// Requires the bottom sheet theme to have transparent background.
class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({super.key, required this.child});

  final Widget child;

  static const _screenPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_screenPadding, 0, _screenPadding, _screenPadding),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

/// Card-style fallback when glass effect is disabled (e.g. on Android).
class _FallbackCard extends StatelessWidget {
  const _FallbackCard({
    required this.colorScheme,
    required this.isDark,
    required this.child,
    this.margin,
    this.padding,
    this.width,
    this.height,
  });

  final ColorScheme colorScheme;
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          isDark
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.primary.withValues(alpha: 0.08),
          colorScheme.surface,
        ),
        borderRadius: AppBorders.borderRadius,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppBorders.borderRadius,
        child: content,
      ),
    );
  }
}
