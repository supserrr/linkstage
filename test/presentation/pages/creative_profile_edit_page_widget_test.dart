import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/presentation/bloc/creative_profile/creative_profile_cubit.dart';
import 'package:linkstage/presentation/bloc/creative_profile/creative_profile_state.dart';
import 'package:linkstage/presentation/pages/profile/creative_profile_edit_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockCreativeProfileCubit extends MockCubit<CreativeProfileState>
    implements CreativeProfileCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const CreativeProfileState());
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

    await tester.pumpWidget(const MaterialApp(home: CreativeProfileEditPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CreativeProfileEditPage), findsOneWidget);
  });

  testWidgets('shows loading state when profile is loading', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockCreativeProfileCubit();
    const seeded = CreativeProfileState(isLoading: true, profile: null);
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativeProfileState>(
      cubit,
      const Stream<CreativeProfileState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(home: CreativeProfileEditPage(creativeProfileCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Profile not found'), findsNothing);
  });

  testWidgets('renders form fields when profile is present', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    final cubit = MockCreativeProfileCubit();
    final seeded = CreativeProfileState(
      isLoading: false,
      profile: const ProfileEntity(
        id: 'p1',
        userId: 'creative-1',
        displayName: 'Name',
      ),
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<CreativeProfileState>(
      cubit,
      const Stream<CreativeProfileState>.empty(),
      initialState: seeded,
    );
    when(() => cubit.setDisplayName(any())).thenReturn(null);
    when(() => cubit.setBio(any())).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(home: CreativeProfileEditPage(creativeProfileCubit: cubit)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'New Name');
    await tester.pump();

    verify(() => cubit.setDisplayName(any())).called(1);
  });
}
