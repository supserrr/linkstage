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

  /// Regex for basic email validation.
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
}
