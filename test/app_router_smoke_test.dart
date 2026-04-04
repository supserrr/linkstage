import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/l10n/app_localizations.dart';
import 'package:linkstage/presentation/bloc/auth/auth_bloc.dart';
import 'package:linkstage/presentation/bloc/auth/auth_event.dart';
import 'package:linkstage/presentation/bloc/auth/auth_state.dart';
import 'package:linkstage/presentation/bloc/settings/settings_cubit.dart';
import 'package:linkstage/presentation/pages/auth/login_page.dart';
import 'package:linkstage/presentation/pages/auth/verify_email_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const AuthSignInWithGoogleRequested());
  });

  late MockAuthBloc authBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await sl.reset();
    AppRouter.resetRouterForTest();

    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    whenListen<AuthState>(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );

    final authRepo = MockAuthRepository();
    final userRepo = MockUserRepository();
    final profileRepo = MockProfileRepository();
    when(() => authRepo.currentUser).thenReturn(null);
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<UserEntity?>.empty());

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<AuthRedirectNotifier>(
        AuthRedirectNotifier(authRepo, userRepo, profileRepo),
      )
      ..registerSingleton<SplashNotifier>(
        SplashNotifier(sl<AuthRedirectNotifier>()),
      )
      ..registerSingleton<SettingsCubit>(SettingsCubit(prefs));
  });

  tearDown(() async {
    await sl.reset();
    AppRouter.resetRouterForTest();
  });

  testWidgets(
    'AppRouter: login, verify-email, register, password-reset',
    (tester) async {
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: BlocProvider<SettingsCubit>.value(
            value: sl<SettingsCubit>(),
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: AppRouter.router,
            ),
          ),
        ),
      );

      await tester.pump();
      AppRouter.router.go('/login');
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Sign In or Create Account'), findsOneWidget);

      AppRouter.router.go('/register');
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      AppRouter.router.go('/verify-email?email=a%40b.com');
      await tester.pumpAndSettle();
      expect(find.byType(VerifyEmailPage), findsOneWidget);

      AppRouter.router.go('/password-reset');
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    },
  );
}
