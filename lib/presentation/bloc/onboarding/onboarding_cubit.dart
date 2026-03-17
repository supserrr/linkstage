import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_state.dart';

const _keyIntroComplete = 'onboarding_intro_complete';
const _keyProfileComplete = 'onboarding_profile_complete';

/// Manages onboarding state (intro seen, profile setup complete).
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._prefs)
      : super(
          OnboardingState(
            introComplete: _prefs.getBool(_keyIntroComplete) ?? false,
            profileComplete: _prefs.getBool(_keyProfileComplete) ?? false,
          ),
        );

  final SharedPreferences _prefs;

  Future<void> setIntroComplete() async {
    await _prefs.setBool(_keyIntroComplete, true);
    emit(state.copyWith(introComplete: true));
  }

  Future<void> setProfileComplete() async {
    await _prefs.setBool(_keyProfileComplete, true);
    emit(state.copyWith(profileComplete: true));
  }

  bool get introComplete => state.introComplete;
  bool get profileComplete => state.profileComplete;
}
