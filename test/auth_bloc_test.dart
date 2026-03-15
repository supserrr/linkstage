import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/usecases/auth/send_sign_in_link_usecase.dart';
import 'package:linkstage/domain/usecases/auth/sign_in_with_email_link_usecase.dart';
import 'package:linkstage/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:linkstage/domain/usecases/auth/sign_out_usecase.dart';
import 'package:linkstage/presentation/bloc/auth/auth_bloc.dart';
import 'package:linkstage/presentation/bloc/auth/auth_event.dart';
import 'package:linkstage/presentation/bloc/auth/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeAuthRepository extends Fake implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthRepository());
  });

  group('AuthBloc', () {
    const testUser = UserEntity(id: '1', email: 'test@test.com');

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthLinkSent] when send sign-in link succeeds',
      build: () {
        final mock = MockAuthRepository();
        when(() => mock.sendSignInLinkToEmail(any()))
            .thenAnswer((_) async => {});
        return AuthBloc(
          sendSignInLink: SendSignInLinkUseCase(mock),
          signInWithEmailLink: SignInWithEmailLinkUseCase(mock),
          signInWithGoogle: SignInWithGoogleUseCase(mock),
          signOut: SignOutUseCase(mock),
        );
      },
      act: (bloc) => bloc.add(
        const AuthSendSignInLinkRequested(email: 'test@test.com'),
      ),
      expect: () => [const AuthLoading(), const AuthLinkSent('test@test.com')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when send sign-in link fails',
      build: () {
        final mock = MockAuthRepository();
        when(() => mock.sendSignInLinkToEmail(any()))
            .thenThrow(Exception('invalid-email'));
        return AuthBloc(
          sendSignInLink: SendSignInLinkUseCase(mock),
          signInWithEmailLink: SignInWithEmailLinkUseCase(mock),
          signInWithGoogle: SignInWithGoogleUseCase(mock),
          signOut: SignOutUseCase(mock),
        );
      },
      act: (bloc) => bloc.add(
        const AuthSendSignInLinkRequested(email: 'bad-email'),
      ),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when sign in with email link succeeds',
      build: () {
        final mock = MockAuthRepository();
        when(
          () => mock.signInWithEmailLink(any(), any()),
        ).thenAnswer((_) async => testUser);
        return AuthBloc(
          sendSignInLink: SendSignInLinkUseCase(mock),
          signInWithEmailLink: SignInWithEmailLinkUseCase(mock),
          signInWithGoogle: SignInWithGoogleUseCase(mock),
          signOut: SignOutUseCase(mock),
        );
      },
      act: (bloc) => bloc.add(
        const AuthSignInWithEmailLinkRequested(
          email: 'test@test.com',
          emailLink: 'https://example.com/__/auth/links?oobCode=abc',
        ),
      ),
      expect: () => [const AuthLoading(), AuthAuthenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when Google sign in succeeds',
      build: () {
        final mock = MockAuthRepository();
        when(() => mock.signInWithGoogle()).thenAnswer((_) async => testUser);
        return AuthBloc(
          sendSignInLink: SendSignInLinkUseCase(mock),
          signInWithEmailLink: SignInWithEmailLinkUseCase(mock),
          signInWithGoogle: SignInWithGoogleUseCase(mock),
          signOut: SignOutUseCase(mock),
        );
      },
      act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
      expect: () => [const AuthLoading(), AuthAuthenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when Google sign in fails',
      build: () {
        final mock = MockAuthRepository();
        when(() => mock.signInWithGoogle())
            .thenThrow(Exception('cancelled'));
        return AuthBloc(
          sendSignInLink: SendSignInLinkUseCase(mock),
          signInWithEmailLink: SignInWithEmailLinkUseCase(mock),
          signInWithGoogle: SignInWithGoogleUseCase(mock),
          signOut: SignOutUseCase(mock),
        );
      },
      act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );
  });
}
