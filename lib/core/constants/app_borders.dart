import 'package:flutter/material.dart';

/// Shared border constants for cards and card-like widgets.
class AppBorders {
  AppBorders._();

  /// Height for buttons and single-line text inputs (48dp minimum tap target).
  static const double inputButtonHeight = 48;

  /// Primary corner radius (pill-style). Use for cards, buttons, inputs.
  static const double radius = 24;
  static const double cardRadius = radius;
  static const double chipRadius = 8;

  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  static BorderSide cardBorder(ColorScheme scheme) => BorderSide(
        color: scheme.primary.withValues(alpha: 0.5),
        width: 0.5,
      );

  static ShapeBorder cardShape(ColorScheme scheme) => RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: cardBorder(scheme),
      );
}
