import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/presentation/bloc/auth/auth_bloc.dart';
import 'package:linkstage/presentation/bloc/auth/auth_event.dart';
import 'package:linkstage/presentation/bloc/auth/auth_state.dart';
import 'package:linkstage/presentation/pages/auth/login_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  group('LoginPage', () {
    late MockAuthBloc authBloc;

    setUp(() {
      authBloc = MockAuthBloc();
      when(() => authBloc.state).thenReturn(const AuthInitial());
      whenListen<AuthState>(
        authBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthInitial(),
      );
    });

    testWidgets('email flow dispatches AuthSendSignInLinkRequested', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      expect(find.text('Continue with Email'), findsOneWidget);
      await tester.tap(find.text('Continue with Email'));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Send sign-in link'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'a@b.com');
      await tester.tap(find.text('Send sign-in link'));
      await tester.pump();

      verify(
        () => authBloc.add(const AuthSendSignInLinkRequested(email: 'a@b.com')),
      ).called(1);
    });
  });
}
