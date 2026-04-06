import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';

/// Vertical scrollables inside need a bounded height; avoid nesting scroll views.
Widget _bounded(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 420, height: 900, child: child)),
  );
}

void main() {
  final cases = <String, Widget>{
    'EventCardSkeleton': const EventCardSkeleton(),
    'FollowingPlannerCardSkeleton': const FollowingPlannerCardSkeleton(),
    'PlannerProfileCardSkeleton': const PlannerProfileCardSkeleton(),
    'VendorCardSkeleton': const VendorCardSkeleton(),
    'ExploreEventCardSkeleton': const ExploreEventCardSkeleton(),
    'BookingEventTileSkeleton': const BookingEventTileSkeleton(),
    'CollaborationProposalTileSkeleton':
        const CollaborationProposalTileSkeleton(),
    'NotificationItemSkeleton': const NotificationItemSkeleton(),
    'NotificationListSkeleton': const NotificationListSkeleton(),
    'ConversationItemSkeleton': const ConversationItemSkeleton(),
    'PlannerDashboardSkeleton': const PlannerDashboardSkeleton(),
    'CreativeDashboardSkeleton': const CreativeDashboardSkeleton(),
    'ChatAppBarSkeleton': const ChatAppBarSkeleton(),
    'ChatMessagesSkeleton': const ChatMessagesSkeleton(),
    'PastWorkCardSkeleton': const PastWorkCardSkeleton(),
    'EventDetailSkeleton': const EventDetailSkeleton(),
  };

  for (final e in cases.entries) {
    testWidgets('${e.key} builds', (tester) async {
      await tester.pumpWidget(_bounded(e.value));
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
