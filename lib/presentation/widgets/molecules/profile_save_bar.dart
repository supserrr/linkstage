import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Bottom save bar for profile edit pages.
class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSaving ? null : onSave,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: isSaving
                    ? SizedBox(
                        key: const ValueKey('loader'),
                        height: 20,
                        width: 20,
                        child: LoadingAnimationWidget.stretchedDots(
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                      )
                    : const Text(
                        'Save and view profile',
                        key: ValueKey('label'),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
