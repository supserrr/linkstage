import '../../../domain/entities/planner_profile_entity.dart';

class FollowingPageState {
  const FollowingPageState({
    this.planners = const [],
    this.loading = false,
    this.error,
  });

  final List<PlannerProfileEntity> planners;
  final bool loading;
  final String? error;

  FollowingPageState copyWith({
    List<PlannerProfileEntity>? planners,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return FollowingPageState(
      planners: planners ?? this.planners,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
