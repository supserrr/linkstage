import '../entities/user_entity.dart';

/// Abstract contract for authentication operations.
abstract class AuthRepository {
  /// Stream of current user; emits null when logged out.
  Stream<UserEntity?> get authStateChanges;

  /// Current user or null.
  UserEntity? get currentUser;

  /// Send a sign-in link to the given email (passwordless).
  /// Works for both sign-up and sign-in.
  /// Stores the email locally for completion when user taps the link.
  Future<void> sendSignInLinkToEmail(String email);

  /// Complete sign-in using the email link (after user taps link).
  Future<UserEntity> signInWithEmailLink(String email, String emailLink);

  /// Check if the given link is a valid sign-in-with-email-link.
  bool isSignInWithEmailLink(String link);

  /// Email stored when link was sent (for completing sign-in from deep link).
  String? get pendingEmailForLinkSignIn;

  /// Clear the stored pending email (call after successful sign-in).
  Future<void> clearPendingEmailForLinkSignIn();

  /// Sign in with Google.
  Future<UserEntity> signInWithGoogle();

  /// Update email. For Google users: re-authenticates with Google.
  /// For email-link users: not supported (throw).
  Future<void> updateEmail(String newEmail);

  /// Sign out.
  Future<void> signOut();
}
