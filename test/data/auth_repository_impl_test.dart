import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/constants/app_constants.dart';
import 'package:linkstage/data/datasources/auth_remote_datasource.dart';
import 'package:linkstage/data/repositories/auth_repository_impl.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  group('AuthRepositoryImpl', () {
    late MockAuthRemoteDataSource remote;
    late SharedPreferences prefs;
    late AuthRepositoryImpl repo;

    setUp(() async {
      remote = MockAuthRemoteDataSource();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = AuthRepositoryImpl(remote, prefs);
    });

    test(
      'sendSignInLinkToEmail delegates and records cooldown + pending email',
      () async {
        when(
          () => remote.sendSignInLinkToEmail(any()),
        ).thenAnswer((_) async {});

        await repo.sendSignInLinkToEmail('  TeSt@Example.com  ');

        verify(
          () => remote.sendSignInLinkToEmail('  TeSt@Example.com  '),
        ).called(1);
        expect(
          prefs.getString(AppConstants.pendingEmailLinkSignInKey),
          '  TeSt@Example.com  ',
        );
        expect(prefs.getInt(AppConstants.lastSignInLinkSentAtMsKey), isNotNull);
        expect(
          prefs.getString(AppConstants.lastSignInLinkEmailForCooldownKey),
          'test@example.com',
        );
      },
    );

    test(
      'signInWithEmailLink clears pending email after successful sign-in',
      () async {
        when(
          () => remote.signInWithEmailLink(any(), any()),
        ).thenAnswer((_) async => const UserEntity(id: 'u1', email: 'a@b.com'));
        await prefs.setString(
          AppConstants.pendingEmailLinkSignInKey,
          'a@b.com',
        );

        final user = await repo.signInWithEmailLink(
          'a@b.com',
          'https://example.com/__/auth/finishSignIn',
        );

        expect(user.id, 'u1');
        expect(prefs.getString(AppConstants.pendingEmailLinkSignInKey), isNull);
      },
    );

    test(
      'sendSignInLinkToEmail enforces client cooldown for same email',
      () async {
        when(
          () => remote.sendSignInLinkToEmail(any()),
        ).thenAnswer((_) async {});

        final now = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(AppConstants.lastSignInLinkSentAtMsKey, now);
        await prefs.setString(
          AppConstants.lastSignInLinkEmailForCooldownKey,
          'a@b.com',
        );

        expect(
          () => repo.sendSignInLinkToEmail('A@B.com'),
          throwsA(
            isA<FirebaseAuthException>().having(
              (e) => e.code,
              'code',
              'client-cooldown',
            ),
          ),
        );
        verifyNever(() => remote.sendSignInLinkToEmail(any()));
      },
    );
  });
}
