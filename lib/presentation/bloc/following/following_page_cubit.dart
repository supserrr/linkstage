import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/planner_profile_entity.dart';
import 'following_page_state.dart';

class FollowingPageCubit extends Cubit<FollowingPageState> {
  FollowingPageCubit() : super(const FollowingPageState());

  void setLoading() {
    emit(state.copyWith(loading: true, clearError: true));
  }

  void setSuccess(List<PlannerProfileEntity> planners) {
    emit(FollowingPageState(planners: planners, loading: false, error: null));
  }

  void setError(String message) {
    emit(state.copyWith(loading: false, error: message));
  }
}
