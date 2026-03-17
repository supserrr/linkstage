import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Custom splash screen with Lottie animation.
/// Chooses light or dark mode asset based on current theme brightness.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const String _lottieLight =
      'assets/lottie/Link-Stage-Animation-Light-Mode.json';
  static const String _lottieDark =
      'assets/lottie/Link-Stage-Animation-Dark-Mode.json';

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final lottieAsset = isDark ? _lottieDark : _lottieLight;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Lottie.asset(
          lottieAsset,
          fit: BoxFit.contain,
          repeat: false,
          errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
