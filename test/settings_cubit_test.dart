import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/services/fcm_service.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/settings/settings_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFcmService extends Mock implements FcmService {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(ProfileVisibility.everyone);
    registerFallbackValue(WhoCanMessage.everyone);
    registerFallbackValue(const ProfileEntity(id: 'fb', userId: 'fb'));
  });

  group('SettingsCubit', () {
    test('setThemeMode persists and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = SettingsCubit(prefs);
      await cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state.themeMode, ThemeMode.dark);
      await cubit.close();
    });

    test('setThemeMode supports light and system', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = SettingsCubit(prefs);
      await cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state.themeMode, ThemeMode.light);
      await cubit.setThemeMode(ThemeMode.system);
      expect(cubit.state.themeMode, ThemeMode.system);
      await cubit.close();
    });

    test('setLanguage updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = SettingsCubit(prefs);
      await cubit.setLanguage('rw');
      expect(cubit.state.language, 'rw');
      await cubit.close();
    });

    test('setNotificationsEnabled calls FCM register and unregister', () async {
      await sl.reset();
      final mockFcm = MockFcmService();
      when(() => mockFcm.registerTokenIfNeeded()).thenAnswer((_) async {});
      when(() => mockFcm.unregisterToken()).thenAnswer((_) async {});
      sl.registerLazySingleton<FcmService>(() => mockFcm);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = SettingsCubit(prefs);

      await cubit.setNotificationsEnabled(true);
      verify(() => mockFcm.registerTokenIfNeeded()).called(1);

      await cubit.setNotificationsEnabled(false);
      verify(() => mockFcm.unregisterToken()).called(1);

      await cubit.close();
      await sl.reset();
    });

    test('loadFromBackend writes prefs from user document', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userRepo = MockUserRepository();
      when(() => userRepo.getUser('u1')).thenAnswer(
        (_) async => const UserEntity(
          id: 'u1',
          email: 'a@test.com',
          profileVisibility: ProfileVisibility.connectionsOnly,
          whoCanMessage: WhoCanMessage.workedWith,
          showOnlineStatus: false,
        ),
      );

      final cubit = SettingsCubit(prefs, userRepository: userRepo);
      await cubit.loadFromBackend('u1');

      expect(cubit.state.profileVisibility, ProfileVisibility.connectionsOnly);
      expect(cubit.state.whoCanMessage, WhoCanMessage.workedWith);
      expect(cubit.state.showOnlineStatus, false);
      await cubit.close();
    });

    test('setProfileVisibility syncs to Firestore for creative user', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userRepo = MockUserRepository();
      final authRepo = MockAuthRepository();
      final profileRepo = MockProfileRepository();

      when(() => authRepo.currentUser).thenReturn(
        const UserEntity(
          id: 'u1',
          email: 'a@test.com',
          role: UserRole.creativeProfessional,
        ),
      );
      when(
        () => userRepo.updatePrivacySettings(
          any(),
          profileVisibility: any(named: 'profileVisibility'),
          whoCanMessage: any(named: 'whoCanMessage'),
          showOnlineStatus: any(named: 'showOnlineStatus'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => profileRepo.getProfileByUserId('u1'),
      ).thenAnswer((_) async => const ProfileEntity(id: 'u1', userId: 'u1'));
      when(() => profileRepo.upsertProfile(any())).thenAnswer((_) async {});

      final cubit = SettingsCubit(
        prefs,
        userRepository: userRepo,
        authRepository: authRepo,
        profileRepository: profileRepo,
      );

      await cubit.setProfileVisibility(ProfileVisibility.onlyMe);

      verify(
        () => userRepo.updatePrivacySettings(
          'u1',
          profileVisibility: ProfileVisibility.onlyMe,
          whoCanMessage: null,
          showOnlineStatus: null,
        ),
      ).called(1);
      verify(() => profileRepo.upsertProfile(any())).called(1);
      await cubit.close();
    });
  });
}
