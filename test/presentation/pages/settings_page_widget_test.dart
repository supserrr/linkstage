import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/l10n/app_localizations.dart';
import 'package:linkstage/presentation/bloc/auth/auth_bloc.dart';
import 'package:linkstage/presentation/bloc/auth/auth_event.dart';
import 'package:linkstage/presentation/bloc/auth/auth_state.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/presentation/bloc/settings/settings_cubit.dart';
import 'package:linkstage/presentation/pages/settings_page.dart';
import 'package:linkstage/presentation/widgets/molecules/privacy_settings_form.dart';
import 'package:linkstage/presentation/widgets/molecules/profile_avatar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);

    final authRepo = MockAuthRepository();
    final userRepo = MockUserRepository();
    final profileRepo = MockProfileRepository();
    final plannerRepo = MockPlannerProfileRepository();
    final auth = MockAuthRedirectNotifier();

    const user = UserEntity(
      id: 'u1',
      email: 'user@test.com',
      role: UserRole.creativeProfessional,
      displayName: 'Test User',
    );

    when(() => authRepo.currentUser).thenReturn(user);
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<UserEntity?>.empty());
    when(() => auth.user).thenReturn(user);
    when(() => userRepo.getUser('u1')).thenAnswer((_) async => user);

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<PlannerProfileRepository>(plannerRepo)
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<SettingsCubit>(
        SettingsCubit(
          prefs,
          userRepository: userRepo,
          authRepository: authRepo,
          profileRepository: profileRepo,
          plannerProfileRepository: plannerRepo,
        ),
      );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('SettingsPage shows My Profile and user email', (tester) async {
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    whenListen<AuthState>(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Test User'), findsWidgets);
    expect(find.text('user@test.com'), findsWidgets);
  });

  testWidgets('Edit icon navigates to creative profile route', (tester) async {
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    whenListen<AuthState>(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const SettingsPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.creativeProfile,
          builder: (context, state) =>
              const Scaffold(body: Text('CreativeProfileEdit')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('CreativeProfileEdit'), findsOneWidget);
  });

  testWidgets('Profile avatar tap navigates to view profile route', (
    tester,
  ) async {
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    whenListen<AuthState>(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const SettingsPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.viewProfile,
          builder: (context, state) =>
              const Scaffold(body: Text('ViewProfileRoute')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();

    expect(find.text('ViewProfileRoute'), findsOneWidget);
  });

  testWidgets('Privacy row opens sheet with PrivacySettingsForm', (
    tester,
  ) async {
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    whenListen<AuthState>(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(find.text('Privacy'), 200);
    await tester.tap(find.text('Privacy').first);
    await tester.pumpAndSettle();

    expect(find.byType(PrivacySettingsForm), findsOneWidget);
  });

  testWidgets('Language picker shows options and selects Francais', (
    tester,
  ) async {
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    whenListen<AuthState>(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(find.text('Language'), 200);
    await tester.tap(find.text('Language').first);
    await tester.pumpAndSettle();

    expect(find.text('Francais'), findsOneWidget);
    await tester.tap(find.text('Francais'));
    await tester.pumpAndSettle();
  });

}
