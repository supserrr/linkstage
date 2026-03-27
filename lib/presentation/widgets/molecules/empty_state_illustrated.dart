import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Empty state with hero illustration, headline, description, and CTAs.
/// Follows UX best practices: clear purpose, actionable next steps, positive tone.
class EmptyStateIllustrated extends StatelessWidget {
  const EmptyStateIllustrated({
    super.key,
    required this.assetPathDark,
    required this.assetPathLight,
    required this.headline,
    required this.description,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.illustrationHeight = 220,
  });

  final String assetPathDark;
  final String assetPathLight;
  final String headline;
  final String description;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final double illustrationHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asset = isDark ? assetPathDark : assetPathLight;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: illustrationHeight,
              child: SvgPicture.asset(
                asset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              headline,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (onPrimaryPressed != null)
              FilledButton(
                onPressed: onPrimaryPressed,
                child: Text(primaryLabel),
              ),
            if (secondaryLabel != null && onSecondaryPressed != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onSecondaryPressed,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
