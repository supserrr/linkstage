import 'dart:async';

import 'package:flutter/foundation.dart'
    show kDebugMode, ChangeNotifier, debugPrint;

import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/user_repository.dart';

/// Wraps OnboardingCubit to expose Listenable for router refresh.
class OnboardingListenable extends ChangeNotifier {
  OnboardingListenable(this._cubit) {
    _subscription = _cubit.stream.listen((_) => notifyListeners());
  }

  final dynamic _cubit;
  late final StreamSubscription<dynamic> _subscription;

  bool get introComplete => _cubit.introComplete;
  bool get profileComplete => _cubit.profileComplete;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Notifier that completes when auth is ready and minimum display duration has
/// passed (event-driven splash).
class SplashNotifier extends ChangeNotifier {
  SplashNotifier(this._authNotifier) {
    _authNotifier.addListener(_onAuthUpdate);
    Future.delayed(const Duration(milliseconds: 2800), _onMinDurationPassed);
    _onAuthUpdate();
  }

  final AuthRedirectNotifier _authNotifier;

  bool _isComplete = false;
  bool _minDurationPassed = false;
  bool _authReady = false;

  bool get isComplete => _isComplete;

  void _onMinDurationPassed() {
    _minDurationPassed = true;
    _tryComplete();
  }

  void _onAuthUpdate() {
    _authReady = _authNotifier.isReady;
    _tryComplete();
  }

  void _tryComplete() {
    if (!_isComplete && _minDurationPassed && _authReady) {
      _isComplete = true;
      _authNotifier.removeListener(_onAuthUpdate);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authNotifier.removeListener(_onAuthUpdate);
    super.dispose();
  }
}

/// Notifier for router refresh when auth state changes.
class AuthRedirectNotifier extends ChangeNotifier {
  AuthRedirectNotifier(
    this._authRepository,
    this._userRepository,
    this._profileRepository,
  ) {
    _subscription = _authRepository.authStateChanges.listen((_) {
      _refreshUserAndProfile();
    });
    _refreshUserAndProfile();
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final ProfileRepository _profileRepository;
  late final StreamSubscription<dynamic> _subscription;

  UserEntity? _user;
  ProfileEntity? _profile;
  bool _loading = true;

  bool get isAuthenticated => _authRepository.currentUser != null;

  /// User is authenticated but has not verified their email.
  bool get needsEmailVerification =>
      isAuthenticated &&
      _authRepository.currentUser != null &&
      !_authRepository.currentUser!.emailVerified;

  UserEntity? get user => _user;

  bool get isReady => !_loading;

  bool get needsRoleSelection =>
      isAuthenticated &&
      !needsEmailVerification &&
      _user != null &&
      _user!.role == null;

  bool get needsProfileSetup {
    if (!isAuthenticated ||
        needsEmailVerification ||
        _user == null ||
        _user!.role == null) {
      return false;
    }
    return _profile == null;
  }

  Future<void> refresh() => _refreshUserAndProfile();

  Future<void> _refreshUserAndProfile() async {
    final authUser = _authRepository.currentUser;
    if (authUser == null) {
      _user = null;
      _profile = null;
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      var user = await _userRepository.getUser(authUser.id);
      if (user != null) {
        final needsPhotoSync =
            (user.photoUrl == null || user.photoUrl!.isEmpty) &&
            authUser.photoUrl != null &&
            authUser.photoUrl!.isNotEmpty;
        if (needsPhotoSync) {
          user = UserEntity(
            id: user.id,
            email: user.email,
            emailVerified: user.emailVerified,
            username: user.username,
            displayName: user.displayName,
            photoUrl: authUser.photoUrl,
            role: user.role,
            lastUsernameChangeAt: user.lastUsernameChangeAt,
            profileVisibility: user.profileVisibility,
            whoCanMessage: user.whoCanMessage,
            showOnlineStatus: user.showOnlineStatus,
            lastSeen: user.lastSeen,
          );
          unawaited(_userRepository.upsertUser(user));
        }
        _user = user;
        if (user.role != null) {
          _profile = await _profileRepository.getProfileByUserId(user.id);
        } else {
          _profile = null;
        }
      } else {
        _user = null;
        _profile = null;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[AuthRedirect] Firestore load failed: $e\n'
          'Stack: $st',
        );
      }
      _user = null;
      _profile = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
