import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, debugPrint;
import 'package:flutter/services.dart' show PlatformException;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/user_entity.dart';
import '../../firebase_options.dart';

/// Remote data source for authentication (Firebase Auth).
class AuthRemoteDataSource {
  AuthRemoteDataSource({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? _defaultGoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  static const _linkDomain = 'linkstage-rw.firebaseapp.com';

  /// Play Services account picker (google_sign_in 6.x). Avoids Credential Manager
  /// "No credential available" issues common on emulators with google_sign_in 7.x.
  static GoogleSignIn _defaultGoogleSignIn() {
    return GoogleSignIn(
      scopes: const ['email', 'profile', 'openid'],
      serverClientId: DefaultFirebaseOptions.googleSignInServerClientId,
      clientId: switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS =>
          DefaultFirebaseOptions.googleSignInIosClientId,
        _ => null,
      },
    );
  }

  Stream<UserEntity?> get authStateChanges =>
      _auth.authStateChanges().map(_userFromFirebase);

  UserEntity? get currentUser => _userFromFirebase(_auth.currentUser);

  Future<void> sendSignInLinkToEmail(String email) async {
    final settings = ActionCodeSettings(
      url: 'https://$_linkDomain/finishSignIn',
      handleCodeInApp: true,
      iOSBundleId: 'com.example.flutterApplication1',
      androidPackageName: 'com.linkstage.app',
      androidInstallApp: true,
    );
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: settings,
    );
  }

  Future<UserEntity> signInWithEmailLink(String email, String emailLink) async {
    final cred = await _auth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
    await cred.user?.getIdToken(true);
    final user = _userFromFirebase(cred.user);
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Sign in failed');
    }
    return user;
  }

  bool isSignInWithEmailLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  Future<UserEntity> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'cancelled',
          message: 'Sign in cancelled',
        );
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'no-token',
          message:
              'Missing Google ID token. Confirm Web OAuth client and SHA-1 in Firebase.',
        );
      }
      final cred = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      final result = await _auth.signInWithCredential(cred);
      final firebaseUser = result.user;
      if (firebaseUser != null) {
        await firebaseUser.getIdToken(true);
      }
      final user = _userFromFirebase(firebaseUser);
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'Sign in failed');
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == GoogleSignIn.kSignInCanceledError) {
        throw FirebaseAuthException(
          code: 'cancelled',
          message: 'Sign in cancelled',
        );
      }
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] PlatformException: ${e.code} - ${e.message}');
      }
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'Google Sign-In failed',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Unexpected error: $e\n$st');
      }
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'You must be signed in to change email',
      );
    }
    final providerData = user.providerData;
    final isGoogleUser =
        providerData.any((p) => p.providerId == 'google.com');
    if (isGoogleUser) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'cancelled',
          message: 'Re-authentication was cancelled',
        );
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'no-token',
          message: 'Could not get Google credentials for re-authentication',
        );
      }
      final cred = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(newEmail);
    } else {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message:
            'To change email, sign out and sign in with your new email via the link.',
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  UserEntity? _userFromFirebase(User? user) {
    if (user == null) return null;
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      role: null,
    );
  }
}
