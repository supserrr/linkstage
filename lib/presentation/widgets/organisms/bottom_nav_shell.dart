import 'dart:ui';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_bubble_navigation_bar/animated_bubble_navigation_bar.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../domain/entities/user_entity.dart';

/// Shell with bottom navigation for main app tabs.
/// Tab labels differ by role: creatives see "Gigs", planners see "Events".
/// Matches [animated_bubble_navigation_bar] package design: bar with bubble items,
/// selected expands to show label, unselected shows icon only.
class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: sl<AuthRedirectNotifier>(),
      builder: (context, _) {
        final role = sl<AuthRedirectNotifier>().user?.role;
        final l10n = AppLocalizations.of(context)!;
        final activityLabel =
            role == UserRole.eventPlanner ? l10n.events : l10n.gigs;

        // Match package design: distinct bar background, blue highlight for selected tab.
        // Blue-tinted glass for floating pill look.
        final bubbleDecoration = BubbleDecoration(
          backgroundColor: isDark
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.primary.withValues(alpha: 0.12),
          selectedBubbleBackgroundColor:
              colorScheme.primaryContainer,
          unSelectedBubbleBackgroundColor: Colors.transparent,
          selectedBubbleLabelColor: colorScheme.onPrimaryContainer,
          unSelectedBubbleLabelColor: colorScheme.onSurfaceVariant,
          selectedBubbleIconColor: colorScheme.onPrimaryContainer,
          unSelectedBubbleIconColor: colorScheme.primary,
          selectedBubbleLabelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimaryContainer,
          ),
          unSelectedBubbleLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
          iconSize: 26,
          innerIconLabelSpacing: 6,
          bubbleItemSize: 12,
          bubbleDuration: const Duration(milliseconds: 350),
          curveIn: Curves.easeOutCubic,
          curveOut: Curves.easeInCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          axis: Axis.horizontal,
          alignment: Alignment.bottomCenter,
          shapes: BubbleShape.circular,
          squareBordersRadius: null,
        );

        final menuItems = [
          BubbleItem(label: l10n.home, icon: AppIcons.home),
          BubbleItem(label: l10n.explore, icon: AppIcons.search),
          BubbleItem(label: l10n.chat, icon: AppIcons.messages),
          BubbleItem(label: activityLabel, icon: AppIcons.eventsNav),
          BubbleItem(label: l10n.settings, icon: AppIcons.settings),
        ];

        return Stack(
          children: [
            Positioned.fill(child: navigationShell),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _BubbleNavBar(
                    items: menuItems,
                    bubbleDecoration: bubbleDecoration,
                    containerBorder: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                    selectedIndex: navigationShell.currentIndex,
                    onTabChange: (index) {
                      if (index >= 0 && index < 5) {
                        navigationShell.goBranch(
                          index,
                          initialLocation: index == navigationShell.currentIndex,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bubble navigation bar matching [animated_bubble_navigation_bar] package design.
/// Bar container with margin/padding, bubble items, AnimatedSize for label reveal.
class _BubbleNavBar extends StatelessWidget {
  const _BubbleNavBar({
    required this.items,
    required this.bubbleDecoration,
    this.containerBorder,
    required this.selectedIndex,
    required this.onTabChange,
  });

  final List<BubbleItem> items;
  final BubbleDecoration bubbleDecoration;
  final Border? containerBorder;
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  static bool get _useGlassEffect {
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.android;
  }

  @override
  Widget build(BuildContext context) {
    final bubble = bubbleDecoration;
    final isHorizontal = bubble.axis == Axis.horizontal;
    final borderRadius = bubble.squareBordersRadius ?? bubble.shapes.shape;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final barContent = SingleChildScrollView(
      scrollDirection: bubble.axis,
      physics: bubble.physics,
      child: isHorizontal
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildItems(bubble, isHorizontal),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildItems(bubble, isHorizontal),
            ),
    );

    // Frosty overlay: more opaque white/surface for visible frost on all platforms.
    // Android skips BackdropFilter (known issues) but still uses this frostier solid color.
    final frostOverlay = isDark
        ? Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.surface.withValues(alpha: 0.7),
          )
        : Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.85),
          );

    final containerChild = _useGlassEffect
        ? ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(color: Colors.transparent),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: frostOverlay,
                    ),
                  ),
                ),
                Padding(
                  padding: bubble.padding,
                  child: barContent,
                ),
              ],
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: frostOverlay,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: bubble.padding,
            child: barContent,
          );

    return Align(
      alignment: bubble.alignment,
      child: Container(
        margin: bubble.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: containerBorder,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: containerChild,
      ),
    );
  }

  List<Widget> _buildItems(BubbleDecoration bubble, bool isHorizontal) {
    final radius = bubble.squareBordersRadius ?? bubble.shapes.shape;

    return List.generate(items.length, (index) {
      final isSelected = index == selectedIndex;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabChange(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
          duration: bubble.bubbleDuration,
          curve: bubble.curveIn,
          padding: EdgeInsets.all(bubble.bubbleItemSize),
          decoration: BoxDecoration(
            color: isSelected
                ? bubble.selectedBubbleBackgroundColor
                : bubble.unSelectedBubbleBackgroundColor,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: isHorizontal
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildLabelIcons(index, isSelected, isHorizontal),
                )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildLabelIcons(index, isSelected, isHorizontal),
                ),
        ),
      ),
      );
    });
  }

  List<Widget> _buildLabelIcons(int index, bool isSelected, bool isHorizontal) {
    final bubble = bubbleDecoration;
    final item = items[index];
    return [
      _buildIcon(bubble, item, isSelected),
      if (isSelected)
        SizedBox(
          width: isHorizontal ? bubble.innerIconLabelSpacing : 0,
          height: isHorizontal ? 0 : bubble.innerIconLabelSpacing,
        ),
      AnimatedSize(
        duration: bubble.bubbleDuration,
        curve: bubble.curveIn,
        child: isSelected
            ? _buildLabel(bubble, item.label, isHorizontal)
            : const SizedBox.shrink(),
      ),
    ];
  }

  Widget _buildIcon(BubbleDecoration bubble, BubbleItem item, bool isSelected) {
    if (item.icon != null) {
      return Icon(
        item.icon,
        color: isSelected
            ? bubble.selectedBubbleIconColor
            : bubble.unSelectedBubbleIconColor,
        size: bubble.iconSize,
      );
    }
    if (item.iconWidget != null) return item.iconWidget!;
    return const SizedBox.shrink();
  }

  Widget _buildLabel(BubbleDecoration bubble, String label, bool isHorizontal) {
    final displayLabel =
        isHorizontal ? label : label.split('').join('\n');
    return Text(
      displayLabel,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: bubble.selectedBubbleLabelStyle,
    );
  }
}
