import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke golden: stable ThemeData + fixed surface. Regenerate with:
/// `flutter test test/presentation/goldens/golden_smoke_test.dart --update-goldens`
/// Use the same Flutter SDK version as CI to avoid image diffs.
void main() {
  testWidgets('smoke layout matches golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D8F)),
        ),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('golden_capture'),
              child: Container(
                width: 280,
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E7D8F)),
                ),
                child: const Text(
                  'LinkStage',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(const Key('golden_capture')),
      matchesGoldenFile('goldens/linkstage_smoke.png'),
    );
  });
}
