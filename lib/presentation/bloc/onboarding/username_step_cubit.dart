import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_setup_cubit.dart';
import 'username_step_state.dart';

class UsernameStepCubit extends Cubit<UsernameStepState> {
  UsernameStepCubit(this._profileSetup) : super(const UsernameStepState());

  final ProfileSetupCubit _profileSetup;

  void onUsernameChanged() {
    emit(UsernameStepState(checking: state.checking, isAvailable: null));
  }

  Future<void> checkAvailability(String rawValue) async {
    final value = rawValue.trim();
    if (value.length < 3) return;
    emit(const UsernameStepState(checking: true, isAvailable: null));
    final available = await _profileSetup.checkUsernameAvailable(value);
    emit(UsernameStepState(checking: false, isAvailable: available));
  }
}
