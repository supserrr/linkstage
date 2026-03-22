import 'package:flutter_bloc/flutter_bloc.dart';

/// Page index for [ProfileSetupFlowPage] (username, photo, display name).
class ProfileSetupFlowCubit extends Cubit<int> {
  ProfileSetupFlowCubit(super.initialStep);

  void setStep(int index) {
    if (index == state) return;
    if (index < 0) return;
    emit(index);
  }
}
