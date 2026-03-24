import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of [AuthRepository] using Firebase Auth.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._prefs);

  final AuthRemoteDataSource _remote;
  final SharedPreferences _prefs;

  @override
  Stream<UserEntity?> get authStateChanges => _remote.authStateChanges;

  @override
  UserEntity? get currentUser => _remote.currentUser;

  @override
  Future<void> sendSignInLinkToEmail(String email) async {
    _enforceSignInLinkCooldown(email);
    await _remote.sendSignInLinkToEmail(email);
    final now = DateTime.now().millisecondsSinceEpoch;
    final normalized = email.trim().toLowerCase();
    await _prefs.setString(AppConstants.pendingEmailLinkSignInKey, email);
    await _prefs.setInt(AppConstants.lastSignInLinkSentAtMsKey, now);
    await _prefs.setString(AppConstants.lastSignInLinkEmailForCooldownKey, normalized);
  }

  @override
  Future<UserEntity> signInWithEmailLink(String email, String emailLink) async {
    final user = await _remote.signInWithEmailLink(email, emailLink);
    await clearPendingEmailForLinkSignIn();
    return user;
  }

  @override
  String? get pendingEmailForLinkSignIn =>
      _prefs.getString(AppConstants.pendingEmailLinkSignInKey);

  @override
  Future<void> clearPendingEmailForLinkSignIn() =>
      _prefs.remove(AppConstants.pendingEmailLinkSignInKey);

  @override
  bool isSignInWithEmailLink(String link) {
    return _remote.isSignInWithEmailLink(link);
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    _enforceGoogleSignInCooldown();
    try {
      final user = await _remote.signInWithGoogle();
      await _recordGoogleSignInCooldown();
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'cancelled') {
        await _recordGoogleSignInCooldown();
      }
      rethrow;
    } catch (e) {
      await _recordGoogleSignInCooldown();
      rethrow;
    }
  }

  @override
  Future<void> updateEmail(String newEmail) {
    return _remote.updateEmail(newEmail);
  }

  @override
  Future<void> signOut() {
    return _remote.signOut();
  }

  void _enforceSignInLinkCooldown(String email) {
    if (const bool.fromEnvironment('USE_AUTH_EMULATOR', defaultValue: false)) {
      return;
    }
    final normalized = email.trim().toLowerCase();
    final lastEmail = _prefs.getString(AppConstants.lastSignInLinkEmailForCooldownKey);
    final lastMs = _prefs.getInt(AppConstants.lastSignInLinkSentAtMsKey);
    if (lastMs == null || lastEmail != normalized) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
    final cap = AppConstants.signInLinkCooldown.inMilliseconds;
    if (elapsed >= cap) return;
    final waitSec = ((cap - elapsed) / 1000).ceil().clamp(1, 86400);
    throw FirebaseAuthException(
      code: 'client-cooldown',
      message:
          'Please wait $waitSec seconds before requesting another sign-in link.',
    );
  }

  void _enforceGoogleSignInCooldown() {
    final lastMs = _prefs.getInt(AppConstants.lastGoogleSignInAttemptAtMsKey);
    if (lastMs == null) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
    final cap = AppConstants.googleSignInCooldown.inMilliseconds;
    if (elapsed >= cap) return;
    final waitSec = ((cap - elapsed) / 1000).ceil().clamp(1, 86400);
    throw FirebaseAuthException(
      code: 'client-cooldown',
      message:
          'Please wait $waitSec seconds before trying Google sign-in again.',
    );
  }

  Future<void> _recordGoogleSignInCooldown() async {
    await _prefs.setInt(
      AppConstants.lastGoogleSignInAttemptAtMsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
