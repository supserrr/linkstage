import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Link Stage logo, theme-aware (light/dark). Uses SVG for transparency.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 48});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/images/logo_dark.svg'
        : 'assets/images/logo_light.svg';
    return SvgPicture.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
