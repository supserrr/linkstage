import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/fcm_service.dart';
import '../settings/settings_cubit.dart';
import '../../../domain/usecases/auth/send_sign_in_link_usecase.dart';
import '../../../domain/usecases/auth/sign_in_with_email_link_usecase.dart';
import '../../../domain/usecases/auth/sign_in_with_google_usecase.dart';
import '../../../domain/usecases/auth/sign_out_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SendSignInLinkUseCase sendSignInLink,
    required SignInWithEmailLinkUseCase signInWithEmailLink,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignOutUseCase signOut,
  }) : _sendSignInLink = sendSignInLink,
       _signInWithEmailLink = signInWithEmailLink,
       _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       super(const AuthInitial()) {
    on<AuthSendSignInLinkRequested>(_onSendSignInLink);
    on<AuthSignInWithEmailLinkRequested>(_onSignInWithEmailLink);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogle);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final SendSignInLinkUseCase _sendSignInLink;
  final SignInWithEmailLinkUseCase _signInWithEmailLink;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;

  Future<void> _onSendSignInLink(
    AuthSendSignInLinkRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _sendSignInLink(event.email);
      emit(AuthLinkSent(event.email));
    } catch (e) {
      emit(AuthError(_authErrorMessage(e)));
    }
  }

  Future<void> _onSignInWithEmailLink(
    AuthSignInWithEmailLinkRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _signInWithEmailLink(event.email, event.emailLink);
      emit(AuthAuthenticated(user));
      _registerFcmIfEnabled();
    } catch (e) {
      emit(AuthError(_authErrorMessage(e)));
    }
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _signInWithGoogle();
      emit(AuthAuthenticated(user));
      _registerFcmIfEnabled();
    } catch (e) {
      emit(AuthError(_authErrorMessage(e)));
    }
  }

  void _registerFcmIfEnabled() {
    try {
      final settings = sl<SettingsCubit>();
      if (settings.state.notificationsEnabled) {
        sl<FcmService>().registerTokenIfNeeded();
      }
    } catch (_) {
      // FCM registration is best-effort; do not override successful auth
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await sl<FcmService>().unregisterToken();
      await _signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(_authErrorMessage(e)));
    }
  }

  String _authErrorMessage(Object e) {
    if (e is FirebaseAuthException && e.code == 'client-cooldown') {
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!;
      }
      return 'Please wait before trying again.';
    }
    final s = e.toString();
    if (s.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    if (s.contains('cancelled')) {
      return 'Sign in was cancelled.';
    }
    if (s.contains('No credential') || s.contains('No credentials')) {
      return 'Add a Google account in device Settings (Settings > Accounts) and try again, or use a physical device.';
    }
    if (s.contains('too-many-requests')) {
      return 'Too many requests. Please try again later.';
    }
    // Surface FirebaseAuthException message (e.g. config errors from Google Sign-In).
    if (e is FirebaseAuthException &&
        e.message != null &&
        e.message!.isNotEmpty) {
      return e.message!;
    }
    return 'An error occurred. Please try again.';
  }
}
