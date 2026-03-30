import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/l10n/app_localizations.dart';
import 'package:linkstage/presentation/widgets/organisms/bottom_nav_shell.dart';
import 'package:linkstage/core/constants/app_icons.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> registerAuth(UserEntity user) async {
    final authRepo = MockAuthRepository();
    final userRepo = MockUserRepository();
    final profileRepo = MockProfileRepository();

    when(() => authRepo.currentUser).thenReturn(user);
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<UserEntity?>.empty());
    when(() => userRepo.getUser(user.id)).thenAnswer((_) async => user);
    when(
      () => profileRepo.getProfileByUserId(any()),
    ).thenAnswer((_) async => const ProfileEntity(id: 'p', userId: 'u'));

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<AuthRedirectNotifier>(
        AuthRedirectNotifier(authRepo, userRepo, profileRepo),
      );
  }

  testWidgets('shows bottom nav on tab roots and switches branches', (
    tester,
  ) async {
    await registerAuth(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              BottomNavShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Home')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/explore',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Explore')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/messages',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Messages')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/bookings',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Bookings')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Profile')),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) =>
                          const Scaffold(body: Text('Profile edit')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Bottom nav should be visible on /home.
    expect(find.byIcon(AppIcons.home), findsOneWidget);

    // Switch to Messages tab via icon tap.
    await tester.tap(find.byIcon(AppIcons.messages));
    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsWidgets);

    // Navigate to nested route under /profile which should hide the bar.
    router.go('/profile/edit');
    await tester.pumpAndSettle();
    expect(find.text('Profile edit'), findsOneWidget);
    expect(find.byIcon(AppIcons.home), findsNothing);
    expect(find.byIcon(AppIcons.messages), findsNothing);
  });
}
