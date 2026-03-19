import 'package:flutter/material.dart';

import '../../../core/constants/app_borders.dart';

/// Empty state with dashed border card, icon, headline, and optional description.
/// Use for section-level empty states (e.g. Recent Activity, Saved events).
class EmptyStateDotted extends StatelessWidget {
  const EmptyStateDotted({
    super.key,
    required this.icon,
    required this.headline,
    this.description,
    this.compact = false,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final IconData icon;
  final String headline;
  final String? description;

  /// When true, reduces padding for use in constrained spaces (e.g. inside cards).
  final bool compact;
  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final verticalPadding = compact ? 20.0 : 28.0;
    final horizontalPadding = compact ? 16.0 : 20.0;
    final iconSize = compact ? 32.0 : 40.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorders.radius),
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: colorScheme.primary,
            strokeWidth: 1.5,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppBorders.radius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: colorScheme.primary),
                SizedBox(height: compact ? 8 : 12),
                Text(
                  headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (description != null) ...[
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (primaryLabel != null && onPrimaryPressed != null) ...[
                  SizedBox(height: compact ? 12 : 20),
                  FilledButton(
                    onPressed: onPrimaryPressed,
                    child: Text(primaryLabel!),
                  ),
                ],
                if (secondaryLabel != null && onSecondaryPressed != null) ...[
                  SizedBox(height: compact ? 8 : 12),
                  OutlinedButton(
                    onPressed: onSecondaryPressed,
                    child: Text(secondaryLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, this.strokeWidth = 1.5});

  final Color color;
  final double strokeWidth;

  static const double _dashLength = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const radius = Radius.circular(AppBorders.radius);
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance = end + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}
