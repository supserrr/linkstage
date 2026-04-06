import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/config/supabase_config.dart';
import 'package:linkstage/core/constants/app_borders.dart';
import 'package:linkstage/data/models/review_model.dart';
import 'package:linkstage/presentation/widgets/atoms/app_button.dart';

void main() {
  test('SupabaseConfig isConfigured is false with default empty anon key', () {
    expect(SupabaseConfig.url, isNotEmpty);
    expect(SupabaseConfig.anonKey, '');
    expect(SupabaseConfig.isConfigured, isFalse);
  });

  test('AppBorders exposes radii and shape helpers', () {
    expect(AppBorders.inputButtonHeight, 48);
    expect(AppBorders.chipRadius, 8);
    expect(AppBorders.borderRadius, BorderRadius.circular(24));
    const scheme = ColorScheme.light();
    expect(AppBorders.cardBorder(scheme).width, 0.5);
    expect(AppBorders.cardShape(scheme), isA<RoundedRectangleBorder>());
  });

  test('ReviewModel.fromFirestore maps all optional fields', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('reviews').doc('r1').set({
      'bookingId': 'bk1',
      'collaborationId': 'co1',
      'reviewerId': 'a',
      'revieweeId': 'b',
      'rating': 4,
      'comment': 'ok',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'reply': 'thanks',
      'replyAt': Timestamp.fromDate(DateTime.utc(2026, 6, 15)),
      'likeCount': 2,
      'likedBy': ['u1', 'u2'],
      'flagCount': 1,
      'flaggedBy': ['bad'],
    });
    final doc = await fs.collection('reviews').doc('r1').get();
    final m = ReviewModel.fromFirestore(doc);
    expect(m.createdAt?.toUtc(), DateTime.utc(2026, 1, 1));
    expect(m.replyAt?.toUtc(), DateTime.utc(2026, 6, 15));
    expect(m.reply, 'thanks');
    expect(m.likeCount, 2);
    expect(m.likedBy, ['u1', 'u2']);
    expect(m.flagCount, 1);
    expect(m.flaggedBy, ['bad']);
    expect(m.toEntity().rating, 4);
  });

  testWidgets('AppButton displays label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Sign in', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('AppButton shows loading indicator when isLoading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Submit', onPressed: () {}, isLoading: true),
        ),
      ),
    );

    // AppButton uses LoadingAnimationWidget + ValueKey('loader'), not CircularProgressIndicator.
    expect(find.byKey(const ValueKey('loader')), findsOneWidget);
    expect(find.byKey(const ValueKey('label')), findsNothing);
  });
}
