import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/presentation/bloc/role_selection/role_selection_cubit.dart';
import 'package:linkstage/presentation/bloc/role_selection/role_selection_state.dart';
import 'package:linkstage/presentation/pages/role_selection_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:linkstage/core/router/app_router.dart';

class MockRoleSelectionCubit extends MockCubit<RoleSelectionState>
    implements RoleSelectionCubit {}

class _TestAssetBundle extends CachingAssetBundle {
  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>';

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(_svg.codeUnits);
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _svg;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const RoleSelectionState.initial());
    registerFallbackValue(UserRole.eventPlanner);
  });

  testWidgets('selecting a role enables Get started', (tester) async {
    const user = UserEntity(id: 'u1', email: 'u1@test.com');

    final cubit = MockRoleSelectionCubit();
    const seeded = RoleSelectionState.initial();
    when(() => cubit.state).thenReturn(seeded);
    whenListen<RoleSelectionState>(
      cubit,
      const Stream<RoleSelectionState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.setHighlightedRole(any())).thenReturn(null);

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: MaterialApp(
          home: RoleSelectionPage(user: user, roleSelectionCubit: cubit),
        ),
      ),
    );
    await tester.pump();

    // Initially disabled.
    final btn = find.widgetWithText(FilledButton, 'Get started');
    expect(btn, findsOneWidget);
    expect(tester.widget<FilledButton>(btn).onPressed, isNull);

    await tester.tap(find.text('Event Planner'));
    await tester.pump();
    verify(() => cubit.setHighlightedRole(UserRole.eventPlanner)).called(1);
  });

  testWidgets('success state navigates to /setup', (tester) async {
    const user = UserEntity(id: 'u1', email: 'u1@test.com');
    const userWithRole = UserEntity(
      id: 'u1',
      email: 'u1@test.com',
      role: UserRole.eventPlanner,
    );

    final cubit = MockRoleSelectionCubit();
    const initial = RoleSelectionState.initial();
    final seeded = RoleSelectionState.success(
      UserRole.eventPlanner,
      userWithRole,
    );
    when(() => cubit.state).thenReturn(initial);
    whenListen<RoleSelectionState>(
      cubit,
      Stream.value(seeded),
      initialState: initial,
    );

    final router = GoRouter(
      initialLocation: AppRoutes.roleSelection,
      routes: [
        GoRoute(
          path: AppRoutes.roleSelection,
          builder: (context, state) =>
              RoleSelectionPage(user: user, roleSelectionCubit: cubit),
        ),
        GoRoute(
          path: AppRoutes.profileSetup,
          builder: (context, state) => const Scaffold(body: Text('Setup')),
        ),
      ],
    );

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Setup'), findsOneWidget);
  });
}
