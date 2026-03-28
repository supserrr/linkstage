import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../core/constants/app_borders.dart';

/// Primary action button; matches input field height for consistency.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final loaderColor = Theme.of(context).colorScheme.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: AppBorders.inputButtonHeight,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loader'),
                  height: 24,
                  width: 24,
                  child: LoadingAnimationWidget.stretchedDots(
                    color: loaderColor,
                    size: 24,
                  ),
                )
              : Text(label, key: const ValueKey('label')),
        ),
      ),
    );
  }
}
