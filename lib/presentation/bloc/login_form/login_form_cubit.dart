import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_form_state.dart';

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(const LoginFormState());

  void setShowEmailForm(bool value) {
    emit(state.copyWith(showEmailForm: value));
  }
}
