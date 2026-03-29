import 'package:equatable/equatable.dart';

class LoginFormState extends Equatable {
  const LoginFormState({this.showEmailForm = false});

  final bool showEmailForm;

  LoginFormState copyWith({bool? showEmailForm}) {
    return LoginFormState(showEmailForm: showEmailForm ?? this.showEmailForm);
  }

  @override
  List<Object?> get props => [showEmailForm];
}
