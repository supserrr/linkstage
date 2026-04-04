import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/presentation/bloc/planner_profile/planner_profile_cubit.dart';
import 'package:linkstage/presentation/bloc/planner_profile/planner_profile_state.dart';
import 'package:linkstage/presentation/pages/profile/planner_profile_edit_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockPlannerProfileCubit extends MockCubit<PlannerProfileState>
    implements PlannerProfileCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const PlannerProfileState());
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows loader when signed out', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(null);
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    await tester.pumpWidget(const MaterialApp(home: PlannerProfileEditPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PlannerProfileEditPage), findsOneWidget);
  });

  testWidgets('shows error retry when state has error and no user', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockPlannerProfileCubit();
    const seeded = PlannerProfileState(error: 'net', user: null);
    when(() => cubit.state).thenReturn(seeded);
    whenListen<PlannerProfileState>(
      cubit,
      const Stream<PlannerProfileState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.refresh()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(home: PlannerProfileEditPage(plannerProfileCubit: cubit)),
    );
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => cubit.refresh()).called(1);
  });

  testWidgets('renders form when user is present', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockPlannerProfileCubit();
    final seeded = PlannerProfileState(
      user: const UserEntity(id: 'planner-1', email: 'p@test.com'),
      plannerProfile: const PlannerProfileEntity(
        userId: 'planner-1',
        displayName: 'Pat',
      ),
      isLoading: false,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<PlannerProfileState>(
      cubit,
      const Stream<PlannerProfileState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.setDisplayName(any())).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(home: PlannerProfileEditPage(plannerProfileCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'New Name');
    await tester.pump();
    verify(() => cubit.setDisplayName(any())).called(1);
  });
}
