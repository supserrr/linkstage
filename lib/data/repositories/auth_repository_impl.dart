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
    await _remote.sendSignInLinkToEmail(email);
    await _prefs.setString(AppConstants.pendingEmailLinkSignInKey, email);
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
  Future<UserEntity> signInWithGoogle() {
    return _remote.signInWithGoogle();
  }

  @override
  Future<void> updateEmail(String newEmail) {
    return _remote.updateEmail(newEmail);
  }

  @override
  Future<void> signOut() {
    return _remote.signOut();
  }
}
