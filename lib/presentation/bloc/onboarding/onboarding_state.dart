import 'package:equatable/equatable.dart';

/// State for onboarding flow (intro + profile completion).
class OnboardingState extends Equatable {
  const OnboardingState({
    this.introComplete = false,
    this.profileComplete = false,
  });

  final bool introComplete;
  final bool profileComplete;

  OnboardingState copyWith({
    bool? introComplete,
    bool? profileComplete,
  }) {
    return OnboardingState(
      introComplete: introComplete ?? this.introComplete,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }

  @override
  List<Object?> get props => [introComplete, profileComplete];
}
