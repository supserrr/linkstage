import 'package:flutter/material.dart';

import '../../../core/constants/app_borders.dart';

/// Shared detail/info chip (icon + label) used for metadata display.
/// Uses [AppBorders.radius] for consistent styling across the app.
class AppDetailChip extends StatelessWidget {
  const AppDetailChip({
    super.key,
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.iconSize = 14,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppBorders.borderRadius,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
