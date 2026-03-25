import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class _FakeOnboardingCubit {
  final StreamController<dynamic> _controller = StreamController.broadcast();
  Stream<dynamic> get stream => _controller.stream;
  bool introComplete = true;
  bool profileComplete = true;

  void emit() => _controller.add(null);

  Future<void> close() => _controller.close();
}

void main() {
  setUpAll(() {
    registerFallbackValue(UserEntity(id: 'fb', email: 'fb@test.com'));
  });

  test('AuthRedirectNotifier clears user when not authenticated', () async {
    final auth = MockAuthRepository();
    final users = MockUserRepository();
    final profiles = MockProfileRepository();
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());

    final n = AuthRedirectNotifier(auth, users, profiles);
    await Future<void>.delayed(Duration.zero);

    expect(n.isAuthenticated, false);
    expect(n.isReady, true);
    expect(n.user, isNull);
    n.dispose();
  });

  test(
    'AuthRedirectNotifier needsEmailVerification when email unverified',
    () async {
      final auth = MockAuthRepository();
      final users = MockUserRepository();
      final profiles = MockProfileRepository();
      when(() => auth.currentUser).thenReturn(
        const UserEntity(id: 'u1', email: 'a@b.com', emailVerified: false),
      );
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(() => users.getUser('u1')).thenAnswer(
        (_) async => const UserEntity(
          id: 'u1',
          email: 'a@b.com',
          emailVerified: false,
          role: UserRole.creativeProfessional,
        ),
      );
      when(() => profiles.getProfileByUserId('u1')).thenAnswer(
        (_) async => const ProfileEntity(id: 'p', userId: 'u1', username: 'u'),
      );

      final n = AuthRedirectNotifier(auth, users, profiles);
      await Future<void>.delayed(Duration.zero);

      expect(n.needsEmailVerification, true);
      n.dispose();
    },
  );

  test('AuthRedirectNotifier needsRoleSelection when role missing', () async {
    final auth = MockAuthRepository();
    final users = MockUserRepository();
    final profiles = MockProfileRepository();
    when(() => auth.currentUser).thenReturn(
      const UserEntity(id: 'u1', email: 'a@b.com', emailVerified: true),
    );
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => users.getUser('u1')).thenAnswer(
      (_) async => const UserEntity(
        id: 'u1',
        email: 'a@b.com',
        emailVerified: true,
        role: null,
      ),
    );

    final n = AuthRedirectNotifier(auth, users, profiles);
    await Future<void>.delayed(Duration.zero);

    expect(n.needsRoleSelection, true);
    n.dispose();
  });

  test('AuthRedirectNotifier needsProfileSetup when profile missing', () async {
    final auth = MockAuthRepository();
    final users = MockUserRepository();
    final profiles = MockProfileRepository();
    when(() => auth.currentUser).thenReturn(
      const UserEntity(id: 'u1', email: 'a@b.com', emailVerified: true),
    );
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => users.getUser('u1')).thenAnswer(
      (_) async => const UserEntity(
        id: 'u1',
        email: 'a@b.com',
        emailVerified: true,
        role: UserRole.creativeProfessional,
      ),
    );
    when(() => profiles.getProfileByUserId('u1')).thenAnswer((_) async => null);

    final n = AuthRedirectNotifier(auth, users, profiles);
    await Future<void>.delayed(Duration.zero);

    expect(n.needsProfileSetup, true);
    n.dispose();
  });

  test(
    'AuthRedirectNotifier syncs photo from auth user when Firestore empty',
    () async {
      final auth = MockAuthRepository();
      final users = MockUserRepository();
      final profiles = MockProfileRepository();
      when(() => auth.currentUser).thenReturn(
        const UserEntity(
          id: 'u1',
          email: 'a@b.com',
          emailVerified: true,
          photoUrl: 'https://ph',
        ),
      );
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(() => users.getUser('u1')).thenAnswer(
        (_) async => const UserEntity(
          id: 'u1',
          email: 'a@b.com',
          emailVerified: true,
          role: UserRole.creativeProfessional,
          photoUrl: null,
        ),
      );
      when(() => users.upsertUser(any())).thenAnswer((_) async {});
      when(() => profiles.getProfileByUserId('u1')).thenAnswer(
        (_) async => const ProfileEntity(id: 'p', userId: 'u1', username: 'u'),
      );

      final n = AuthRedirectNotifier(auth, users, profiles);
      await Future<void>.delayed(Duration.zero);

      verify(() => users.upsertUser(any())).called(1);
      n.dispose();
    },
  );

  test('AuthRedirectNotifier handles getUser failure', () async {
    final auth = MockAuthRepository();
    final users = MockUserRepository();
    final profiles = MockProfileRepository();
    when(() => auth.currentUser).thenReturn(
      const UserEntity(id: 'u1', email: 'a@b.com', emailVerified: true),
    );
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => users.getUser('u1')).thenThrow(Exception('network'));

    final n = AuthRedirectNotifier(auth, users, profiles);
    await Future<void>.delayed(Duration.zero);

    expect(n.user, isNull);
    n.dispose();
  });

  test('AuthRedirectNotifier refresh re-fetches', () async {
    final auth = MockAuthRepository();
    final users = MockUserRepository();
    final profiles = MockProfileRepository();
    when(() => auth.currentUser).thenReturn(
      const UserEntity(id: 'u1', email: 'a@b.com', emailVerified: true),
    );
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => users.getUser('u1')).thenAnswer(
      (_) async => const UserEntity(
        id: 'u1',
        email: 'a@b.com',
        emailVerified: true,
        role: UserRole.eventPlanner,
      ),
    );
    when(() => profiles.getProfileByUserId('u1')).thenAnswer(
      (_) async => const ProfileEntity(id: 'p', userId: 'u1', username: 'pl'),
    );

    final n = AuthRedirectNotifier(auth, users, profiles);
    await Future<void>.delayed(Duration.zero);
    await n.refresh();

    verify(() => users.getUser('u1')).called(2);
    n.dispose();
  });

  test('OnboardingListenable forwards cubit stream', () async {
    final cubit = _FakeOnboardingCubit();
    final listenable = OnboardingListenable(cubit);
    var count = 0;
    listenable.addListener(() => count++);
    cubit.emit();
    await Future<void>.delayed(Duration.zero);
    expect(count, greaterThan(0));
    expect(listenable.introComplete, true);
    listenable.dispose();
    await cubit.close();
  });

  test('SplashNotifier completes after min duration when auth ready', () async {
    final auth = MockAuthRepository();
    final users = MockUserRepository();
    final profiles = MockProfileRepository();
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());

    final redirect = AuthRedirectNotifier(auth, users, profiles);
    await Future<void>.delayed(Duration.zero);

    final splash = SplashNotifier(redirect);
    expect(splash.isComplete, false);

    await Future<void>.delayed(const Duration(milliseconds: 2850));

    expect(splash.isComplete, true);
    splash.dispose();
    redirect.dispose();
  });
}
