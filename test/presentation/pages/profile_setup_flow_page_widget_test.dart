import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/domain/usecases/user/upsert_user_usecase.dart';
import 'package:linkstage/presentation/bloc/onboarding/onboarding_cubit.dart';
import 'package:linkstage/presentation/bloc/onboarding/profile_setup_draft_storage.dart';
import 'package:linkstage/presentation/pages/onboarding/profile_setup_flow_page.dart';
import 'package:linkstage/data/datasources/portfolio_storage_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MockOnboardingCubit extends Mock implements OnboardingCubit {}

class MockProfileSetupDraftStorage extends Mock
    implements ProfileSetupDraftStorage {}

class MockUpsertUserUseCase extends Mock implements UpsertUserUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockPortfolioStorageDataSource extends Mock
    implements PortfolioStorageDataSource {}

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
    registerFallbackValue(const UserEntity(id: 'fb', email: 'fb@test.com'));
    registerFallbackValue(
      const ProfileEntity(id: 'pfb', userId: 'fb', username: 'fb'),
    );
    registerFallbackValue(XFile('dummy'));
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('ProfileSetupFlowPage renders step counter and first step', (
    tester,
  ) async {
    final onboarding = MockOnboardingCubit();
    final draftStorage = MockProfileSetupDraftStorage();
    final upsertUser = MockUpsertUserUseCase();
    final profileRepo = MockProfileRepository();
    final userRepo = MockUserRepository();
    final authRepo = MockAuthRepository();
    final authRedirect = MockAuthRedirectNotifier();
    final storage = MockPortfolioStorageDataSource();

    when(() => draftStorage.loadDraft(any())).thenReturn(null);
    when(() => authRedirect.refresh()).thenAnswer((_) async {});
    when(() => onboarding.setProfileComplete()).thenAnswer((_) async {});
    when(
      () => authRepo.currentUser,
    ).thenReturn(const UserEntity(id: 'u1', email: 'u1@test.com'));
    when(() => upsertUser.call(any())).thenAnswer((_) async {});
    when(() => profileRepo.upsertProfile(any())).thenAnswer((_) async {});
    when(
      () => userRepo.checkUsernameAvailable(any()),
    ).thenAnswer((_) async => true);
    when(
      () => storage.uploadProfilePhoto(any(), any()),
    ).thenAnswer((_) async => 'https://x');

    sl
      ..registerSingleton<OnboardingCubit>(onboarding)
      ..registerSingleton<ProfileSetupDraftStorage>(draftStorage)
      ..registerSingleton<UpsertUserUseCase>(upsertUser)
      ..registerSingleton<ProfileRepository>(profileRepo)
      ..registerSingleton<UserRepository>(userRepo)
      ..registerSingleton<PortfolioStorageDataSource>(storage)
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<AuthRedirectNotifier>(authRedirect);

    final user = const UserEntity(
      id: 'u1',
      email: 'u1@test.com',
      role: UserRole.creativeProfessional,
    );

    final router = GoRouter(
      initialLocation: '/setup',
      routes: [
        GoRoute(
          path: '/setup',
          builder: (context, state) => ProfileSetupFlowPage(user: user),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
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
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Choose your username'), findsOneWidget);
  });
}
