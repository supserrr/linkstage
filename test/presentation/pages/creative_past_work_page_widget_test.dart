import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/presentation/bloc/creative_past_work/creative_past_work_cubit.dart';
import 'package:linkstage/presentation/bloc/creative_past_work/creative_past_work_state.dart';
import 'package:linkstage/presentation/pages/profile/creative_past_work_page.dart';
import 'package:linkstage/presentation/widgets/molecules/connection_error_overlay.dart';
import 'package:linkstage/presentation/widgets/molecules/empty_state_dotted.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockCreativePastWorkCubit extends MockCubit<CreativePastWorkState>
    implements CreativePastWorkCubit {}

void main() {
  const creativeUserId = 'creative-1';

  setUpAll(() {
    registerFallbackValue(const CreativePastWorkState());
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows skeleton cards while loading', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: creativeUserId,
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockCreativePastWorkCubit();
    const seeded = CreativePastWorkState(
      isLoading: true,
      pastEvents: [],
      pastCollaborations: [],
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativePastWorkState>(
      cubit,
      const Stream<CreativePastWorkState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreativePastWorkPage(
          userId: creativeUserId,
          creativePastWorkCubit: cubit,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PastWorkCardSkeleton), findsWidgets);
  });

  testWidgets('shows empty sections when no past work', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: creativeUserId,
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockCreativePastWorkCubit();
    const seeded = CreativePastWorkState(isLoading: false);
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativePastWorkState>(
      cubit,
      const Stream<CreativePastWorkState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.load()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: CreativePastWorkPage(
          userId: creativeUserId,
          creativePastWorkCubit: cubit,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(EmptyStateDotted), findsWidgets);
    expect(find.text('No past events yet'), findsOneWidget);
    expect(find.text('No past collaborations yet'), findsOneWidget);
  });

  testWidgets('shows error overlay when state has error', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: creativeUserId,
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockCreativePastWorkCubit();
    const seeded = CreativePastWorkState(isLoading: false, error: 'oops');
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativePastWorkState>(
      cubit,
      const Stream<CreativePastWorkState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.load()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: CreativePastWorkPage(
          userId: creativeUserId,
          creativePastWorkCubit: cubit,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ConnectionErrorOverlay), findsOneWidget);
  });

  testWidgets('tapping edit toggles config mode (own profile)', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: creativeUserId,
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockCreativePastWorkCubit();
    final seeded = CreativePastWorkState(
      isLoading: false,
      pastEvents: [
        PastEventItem(
          bookingId: 'b-1',
          event: EventEntity(
            id: 'ev-1',
            plannerId: 'planner-1',
            title: 'Past gig',
            status: EventStatus.completed,
          ),
          plannerName: 'Planner',
        ),
      ],
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativePastWorkState>(
      cubit,
      const Stream<CreativePastWorkState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.toggleConfigMode()).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(
        home: CreativePastWorkPage(
          userId: creativeUserId,
          creativePastWorkCubit: cubit,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    verify(() => cubit.toggleConfigMode()).called(1);
  });
}
