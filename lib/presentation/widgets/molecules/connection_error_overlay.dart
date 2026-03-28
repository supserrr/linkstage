import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../core/utils/firestore_error_utils.dart';
import '../../../core/utils/toast_utils.dart';

/// Wraps [child] with pull-to-refresh. When [hasError] is true, shows a toast
/// and optionally a back button. The skeleton stays visible; pull down to retry.
class ConnectionErrorOverlay extends StatefulWidget {
  const ConnectionErrorOverlay({
    super.key,
    required this.child,
    required this.hasError,
    required this.onRefresh,
    this.error,
    this.onBack,
  });

  final Widget child;
  final bool hasError;
  final Future<void> Function() onRefresh;
  final Object? error;
  final VoidCallback? onBack;

  @override
  State<ConnectionErrorOverlay> createState() => _ConnectionErrorOverlayState();
}

class _ConnectionErrorOverlayState extends State<ConnectionErrorOverlay> {
  Object? _lastToastError;

  @override
  void didUpdateWidget(ConnectionErrorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError &&
        widget.error != null &&
        widget.error != _lastToastError) {
      _lastToastError = widget.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showToast(context, firestoreErrorMessage(widget.error), isError: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return CustomMaterialIndicator(
      onRefresh: widget.onRefresh,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useMaterialContainer: false,
      indicatorBuilder: (context, controller) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: LoadingAnimationWidget.threeRotatingDots(
          color: color,
          size: 40,
        ),
      ),
      child: Stack(
        children: [
          widget.child,
          if (widget.hasError && widget.onBack != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                tooltip: 'Go back',
              ),
            ),
        ],
      ),
    );
  }
}
