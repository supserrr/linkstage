import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/presentation/bloc/login_form/login_form_cubit.dart';
import 'package:linkstage/presentation/bloc/login_form/login_form_state.dart';

void main() {
  group('LoginFormCubit', () {
    blocTest<LoginFormCubit, LoginFormState>(
      'setShowEmailForm toggles visibility',
      build: LoginFormCubit.new,
      act: (c) => c
        ..setShowEmailForm(true)
        ..setShowEmailForm(false),
      expect: () => [
        const LoginFormState(showEmailForm: true),
        const LoginFormState(showEmailForm: false),
      ],
    );
  });
}
