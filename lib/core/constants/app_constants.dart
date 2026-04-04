/// Application-wide constants for LinkStage.
class AppConstants {
  AppConstants._();

  static const String appName = 'LinkStage';

  /// SharedPreferences key for creative's list of followed planner (user) IDs.
  static const String creativeFollowedPlannerIdsKey =
      'creative_followed_planner_ids';

  /// Minimum password length for validation.
  static const int minPasswordLength = 8;

  /// SharedPreferences key for email when waiting for sign-in link completion.
  static const String pendingEmailLinkSignInKey = 'pending_email_link_sign_in';

  /// Last time a sign-in link was sent (ms epoch), for client cooldown.
  static const String lastSignInLinkSentAtMsKey = 'last_sign_in_link_sent_at_ms';

  /// Email (lowercase) associated with [lastSignInLinkSentAtMsKey].
  static const String lastSignInLinkEmailForCooldownKey =
      'last_sign_in_link_email_cooldown';

  /// Last Google sign-in attempt that reached Firebase (ms epoch).
  static const String lastGoogleSignInAttemptAtMsKey =
      'last_google_sign_in_attempt_at_ms';

  /// Minimum time between "send sign-in link" requests for the same email.
  static const Duration signInLinkCooldown = Duration(seconds: 90);

  /// Minimum time between Google sign-in attempts (after picker / Firebase).
  static const Duration googleSignInCooldown = Duration(seconds: 60);

  /// SharedPreferences key (suffix planner user id): invitation outcome booking
  /// IDs dismissed from planner home recent activity after viewing that event's
  /// applicants list. Creative applications are not ack-stopped.
  static String plannerHomeActivityAckBookingsKey(String plannerId) =>
      'planner_home_activity_ack_bookings_$plannerId';

  /// Regex for basic email validation.
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
}
