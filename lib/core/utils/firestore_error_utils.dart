/// Returns a user-friendly message for Firestore/network errors.
///
/// Handles UNAVAILABLE, "Unable to resolve host", and similar connectivity
/// issues with a clear, actionable message.
String firestoreErrorMessage(Object? error) {
  if (error == null) return 'Something went wrong.';
  final s = error.toString().toLowerCase();
  if (s.contains('unavailable') ||
      s.contains('unable to resolve host') ||
      s.contains('connection') ||
      s.contains('network')) {
    return 'Connection issue. Check your internet and tap Retry.';
  }
  if (s.contains('permission-denied') || s.contains('permission')) {
    return 'Access denied. Deploy Firestore rules and sign in again.';
  }
  return 'Something went wrong. Tap Retry to try again.';
}
