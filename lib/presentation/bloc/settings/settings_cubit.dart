import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/fcm_service.dart';
import '../../../domain/entities/user_entity.dart';
    show ProfileVisibility, UserRole, WhoCanMessage;
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/planner_profile_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'settings_state.dart';

const _keyThemeMode = 'theme_mode';
const _keyNotifications = 'notifications_enabled';
const _keyLanguage = 'language';
const _keyProfileVisibility = 'profile_visibility';
const _keyWhoCanMessage = 'who_can_message';
const _keyShowOnlineStatus = 'show_online_status';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._prefs, {
    UserRepository? userRepository,
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    PlannerProfileRepository? plannerProfileRepository,
  })  : _userRepository = userRepository,
        _authRepository = authRepository,
        _profileRepository = profileRepository,
        _plannerProfileRepository = plannerProfileRepository,
        super(
          SettingsState(
            themeMode: _themeModeFromIndex(_prefs.getInt(_keyThemeMode) ?? 0),
            notificationsEnabled: _prefs.getBool(_keyNotifications) ?? true,
            language: _prefs.getString(_keyLanguage) ?? 'en',
            profileVisibility: _profileVisibilityFromIndex(
              _prefs.getInt(_keyProfileVisibility) ?? 0,
            ),
            whoCanMessage: _whoCanMessageFromIndex(
              _prefs.getInt(_keyWhoCanMessage) ?? 0,
            ),
            showOnlineStatus: _prefs.getBool(_keyShowOnlineStatus) ?? true,
          ),
        );

  final SharedPreferences _prefs;
  final UserRepository? _userRepository;
  final AuthRepository? _authRepository;
  final ProfileRepository? _profileRepository;
  final PlannerProfileRepository? _plannerProfileRepository;

  static ThemeMode _themeModeFromIndex(int i) {
    switch (i) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static int _themeModeToIndex(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      case ThemeMode.system:
        return 0;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_keyThemeMode, _themeModeToIndex(mode));
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotifications, enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
    final fcm = sl<FcmService>();
    if (enabled) {
      await fcm.registerTokenIfNeeded();
    } else {
      await fcm.unregisterToken();
    }
  }

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_keyLanguage, code);
    emit(state.copyWith(language: code));
  }

  static ProfileVisibility _profileVisibilityFromIndex(int i) {
    switch (i) {
      case 1:
        return ProfileVisibility.connectionsOnly;
      case 2:
        return ProfileVisibility.onlyMe;
      default:
        return ProfileVisibility.everyone;
    }
  }

  static int _profileVisibilityToIndex(ProfileVisibility v) {
    switch (v) {
      case ProfileVisibility.connectionsOnly:
        return 1;
      case ProfileVisibility.onlyMe:
        return 2;
      default:
        return 0;
    }
  }

  static WhoCanMessage _whoCanMessageFromIndex(int i) {
    switch (i) {
      case 1:
        return WhoCanMessage.workedWith;
      case 2:
        return WhoCanMessage.noOne;
      default:
        return WhoCanMessage.everyone;
    }
  }

  static int _whoCanMessageToIndex(WhoCanMessage v) {
    switch (v) {
      case WhoCanMessage.workedWith:
        return 1;
      case WhoCanMessage.noOne:
        return 2;
      default:
        return 0;
    }
  }

  Future<void> setProfileVisibility(ProfileVisibility v) async {
    await _prefs.setInt(_keyProfileVisibility, _profileVisibilityToIndex(v));
    emit(state.copyWith(profileVisibility: v));
    await _syncPrivacyToFirestore(
      profileVisibility: v,
      whoCanMessage: null,
      showOnlineStatus: null,
    );
  }

  Future<void> setWhoCanMessage(WhoCanMessage v) async {
    await _prefs.setInt(_keyWhoCanMessage, _whoCanMessageToIndex(v));
    emit(state.copyWith(whoCanMessage: v));
    await _syncPrivacyToFirestore(
      profileVisibility: null,
      whoCanMessage: v,
      showOnlineStatus: null,
    );
  }

  Future<void> setShowOnlineStatus(bool v) async {
    await _prefs.setBool(_keyShowOnlineStatus, v);
    emit(state.copyWith(showOnlineStatus: v));
    await _syncPrivacyToFirestore(
      profileVisibility: null,
      whoCanMessage: null,
      showOnlineStatus: v,
    );
  }

  /// Load privacy settings from Firestore for the current user.
  /// Call when user is logged in to sync from backend.
  Future<void> loadFromBackend(String userId) async {
    final userRepo = _userRepository;
    if (userRepo == null) return;
    final user = await userRepo.getUser(userId);
    if (user == null) return;
    final pv = user.profileVisibility ?? ProfileVisibility.everyone;
    final wcm = user.whoCanMessage ?? WhoCanMessage.everyone;
    final sos = user.showOnlineStatus;
    await _prefs.setInt(_keyProfileVisibility, _profileVisibilityToIndex(pv));
    await _prefs.setInt(_keyWhoCanMessage, _whoCanMessageToIndex(wcm));
    await _prefs.setBool(_keyShowOnlineStatus, sos);
    emit(state.copyWith(
      profileVisibility: pv,
      whoCanMessage: wcm,
      showOnlineStatus: sos,
    ));
  }

  Future<void> _syncPrivacyToFirestore({
    ProfileVisibility? profileVisibility,
    WhoCanMessage? whoCanMessage,
    bool? showOnlineStatus,
  }) async {
    final userRepo = _userRepository;
    final authRepo = _authRepository;
    if (userRepo == null || authRepo == null) return;
    final user = authRepo.currentUser;
    if (user == null) return;

    await userRepo.updatePrivacySettings(
      user.id,
      profileVisibility: profileVisibility,
      whoCanMessage: whoCanMessage,
      showOnlineStatus: showOnlineStatus,
    );

    if (profileVisibility != null) {
      if (user.role == UserRole.creativeProfessional) {
        final profile = await _profileRepository?.getProfileByUserId(user.id);
        if (profile != null) {
          await _profileRepository?.upsertProfile(
            profile.copyWith(profileVisibility: profileVisibility),
          );
        }
      } else if (user.role == UserRole.eventPlanner) {
        final plannerProfile =
            await _plannerProfileRepository?.getPlannerProfile(user.id);
        if (plannerProfile != null) {
          await _plannerProfileRepository?.upsertPlannerProfile(
            plannerProfile.copyWith(profileVisibility: profileVisibility),
          );
        }
      }
    }
  }
}
