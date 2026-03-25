import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_form_state.dart';

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit({bool initialShowEmailForm = false})
    : super(LoginFormState(showEmailForm: initialShowEmailForm));

  void setShowEmailForm(bool value) {
    emit(state.copyWith(showEmailForm: value));
  }
}
