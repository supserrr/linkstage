import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/usecases/auth/update_email_usecase.dart';
import 'change_email_state.dart';

/// Cubit for change email flow.
/// For Google users: re-authenticates with Google, then sends verification to new email.
/// For email-link users: not supported (throws).
class ChangeEmailCubit extends Cubit<ChangeEmailState> {
  ChangeEmailCubit(this._updateEmail) : super(const ChangeEmailState());

  final UpdateEmailUseCase _updateEmail;

  Future<void> submit(String newEmail) async {
    final emailError = Validators.email(newEmail);
    if (emailError != null) {
      emit(state.copyWith(error: emailError));
      return;
    }
    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      await _updateEmail(newEmail);
      emit(state.copyWith(isSubmitting: false, success: true, error: null));
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      emit(state.copyWith(isSubmitting: false, error: msg));
    }
  }
}
