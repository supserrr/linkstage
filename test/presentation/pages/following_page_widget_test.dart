import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/followed_planners_repository.dart';
import 'package:linkstage/presentation/pages/following_page.dart';
import 'package:linkstage/presentation/widgets/molecules/connection_error_overlay.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockFollowedPlannersRepository extends Mock
    implements FollowedPlannersRepository {}

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('non-creative user sees access message', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    await tester.pumpWidget(const MaterialApp(home: FollowingPage()));
    await tester.pump();

    expect(
      find.text('Only creatives can follow event planners'),
      findsOneWidget,
    );
  });

  testWidgets('loading shows skeletons then empty state appears', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    final repo = MockFollowedPlannersRepository();
    final completer = Completer<List<PlannerProfileEntity>>();
    when(
      () => repo.getFollowedPlannerProfiles('creative-1'),
    ).thenAnswer((_) => completer.future);

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<FollowedPlannersRepository>(repo);

    await tester.pumpWidget(const MaterialApp(home: FollowingPage()));
    await tester.pump(); // build
    await tester.pump(); // post-frame callback schedules _load

    expect(find.byType(FollowingPlannerCardSkeleton), findsWidgets);

    completer.complete(const []);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No planners followed yet'), findsOneWidget);
  });

  testWidgets('empty state Browse events navigates to Explore', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    final repo = MockFollowedPlannersRepository();
    when(
      () => repo.getFollowedPlannerProfiles('creative-1'),
    ).thenAnswer((_) async => const []);

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<FollowedPlannersRepository>(repo);

    final router = GoRouter(
      initialLocation: '/following',
      routes: [
        GoRoute(
          path: '/following',
          builder: (context, state) => const FollowingPage(),
        ),
        GoRoute(
          path: AppRoutes.explore,
          builder: (context, state) => const Scaffold(body: Text('Explore')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Browse events'));
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsOneWidget);
  });

  testWidgets('error state shows overlay', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    final repo = MockFollowedPlannersRepository();
    when(
      () => repo.getFollowedPlannerProfiles('creative-1'),
    ).thenThrow(Exception('net'));

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<FollowedPlannersRepository>(repo);

    await tester.pumpWidget(const MaterialApp(home: FollowingPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ConnectionErrorOverlay), findsOneWidget);
  });

  testWidgets('unfollow calls toggleFollow', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );

    final repo = MockFollowedPlannersRepository();
    when(() => repo.getFollowedPlannerProfiles('creative-1')).thenAnswer(
      (_) async => const [
        PlannerProfileEntity(
          userId: 'planner-1',
          displayName: 'Pat',
          location: 'Kigali',
        ),
      ],
    );
    when(
      () => repo.toggleFollow('creative-1', 'planner-1'),
    ).thenAnswer((_) async {});

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<FollowedPlannersRepository>(repo);

    await tester.pumpWidget(const MaterialApp(home: FollowingPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pat'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Unfollow'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => repo.toggleFollow('creative-1', 'planner-1')).called(1);
  });
}
