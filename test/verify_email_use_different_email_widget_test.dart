import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/presentation/bloc/auth/auth_bloc.dart';
import 'package:linkstage/presentation/bloc/auth/auth_event.dart';
import 'package:linkstage/presentation/bloc/auth/auth_state.dart';
import 'package:linkstage/presentation/pages/auth/login_page.dart';
import 'package:linkstage/presentation/pages/auth/verify_email_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  group('VerifyEmailPage', () {
    late MockAuthRepository authRepository;
    late MockAuthBloc authBloc;

    setUp(() async {
      authRepository = MockAuthRepository();
      authBloc = MockAuthBloc();

      await sl.reset();
      sl.registerLazySingleton<AuthRepository>(() => authRepository);

      when(() => authBloc.state).thenReturn(const AuthInitial());
      whenListen<AuthState>(
        authBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthInitial(),
      );
    });

    testWidgets(
      '"Use a different email" clears pending email, shows toast, and returns to email entry',
      (tester) async {
        when(
          () => authRepository.clearPendingEmailForLinkSignIn(),
        ).thenAnswer((_) async {});

        final router = GoRouter(
          initialLocation: Uri(
            path: AppRoutes.verifyEmail,
            queryParameters: const {'email': 'a@b.com'},
          ).toString(),
          routes: [
            GoRoute(
              path: AppRoutes.verifyEmail,
              builder: (context, state) {
                final email = state.uri.queryParameters['email'] ?? '';
                return VerifyEmailPage(email: email);
              },
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (context, state) {
                final mode = state.uri.queryParameters['mode'];
                return LoginPage(initialShowEmailForm: mode == 'email');
              },
            ),
          ],
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        expect(find.text('Use a different email'), findsOneWidget);
        await tester.tap(find.text('Use a different email'));
        await tester.pumpAndSettle();

        verify(() => authRepository.clearPendingEmailForLinkSignIn()).called(1);
        expect(find.text('Saved email cleared.'), findsOneWidget);

        // Login should open directly to email entry step.
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Send sign-in link'), findsOneWidget);
      },
    );
  });
}
