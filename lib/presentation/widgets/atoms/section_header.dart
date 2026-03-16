import 'package:flutter/material.dart';

/// Shared section header for consistent styling across profile, messages,
/// notifications, and similar pages.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.padding,
    this.textStyle,
  });

  final String title;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final effectiveStyle = textStyle ?? defaultStyle;

    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 8),
      child: icon != null
          ? Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(title, style: effectiveStyle),
              ],
            )
          : Text(title, style: effectiveStyle),
    );
  }
}
