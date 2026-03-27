import 'package:flutter/material.dart';

import '../../../core/constants/app_borders.dart';

/// Shared filter/category chip used across the app.
/// Uses [AppBorders.radius] for consistent pill-style design.
class AppFilterChip<T> extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.value,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final T? value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: AppBorders.borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorders.borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
