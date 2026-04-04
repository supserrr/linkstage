import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/presentation/widgets/molecules/vendor_card.dart';

void main() {
  testWidgets('VendorCard renders fields and save interaction', (tester) async {
    var savedTapped = 0;
    var tapped = 0;

    final profile = ProfileEntity(
      id: 'p1',
      userId: 'u1',
      displayName: 'Vendor',
      location: 'Kigali',
      priceRange: '100000',
      rating: 4.5,
      reviewCount: 12,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VendorCard(
            profile: profile,
            onTap: () => tapped++,
            isSaved: false,
            onSaveTap: () => savedTapped++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Vendor'), findsOneWidget);
    expect(find.text('Kigali'), findsOneWidget);
    expect(find.textContaining('reviews', findRichText: true), findsOneWidget);

    await tester.tap(find.byTooltip('Save creative'));
    await tester.pump();
    expect(savedTapped, 1);

    await tester.tap(find.text('Vendor'));
    await tester.pump();
    expect(tapped, 1);
  });
}
