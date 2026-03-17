import 'package:flutter/material.dart';

/// Shows a Material 3 SnackBar message.
///
/// Use [isError] for error states (uses error color).
void showToast(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? colorScheme.error : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
