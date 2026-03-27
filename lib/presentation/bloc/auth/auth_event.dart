import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSendSignInLinkRequested extends AuthEvent {
  const AuthSendSignInLinkRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthSignInWithEmailLinkRequested extends AuthEvent {
  const AuthSignInWithEmailLinkRequested({
    required this.email,
    required this.emailLink,
  });

  final String email;
  final String emailLink;

  @override
  List<Object?> get props => [email, emailLink];
}

class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
