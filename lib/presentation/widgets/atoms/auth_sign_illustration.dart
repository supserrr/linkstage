import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Sign in / Sign up illustration, theme-aware (light/dark).
/// Fits the available space in Expanded (same behavior as onboarding illustrations).
class AuthSignIllustration extends StatelessWidget {
  const AuthSignIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/images/auth_sign_illustration_dark.svg'
        : 'assets/images/auth_sign_illustration_light.svg';
    return LayoutBuilder(
      builder: (context, constraints) {
        return SvgPicture.asset(
          asset,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          fit: BoxFit.contain,
        );
      },
    );
  }
}
