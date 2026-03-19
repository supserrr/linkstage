import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/presentation/widgets/atoms/app_button.dart';

void main() {
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
