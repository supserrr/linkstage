import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/utils/firestore_error_utils.dart';

void main() {
  group('firestoreErrorMessage', () {
    test('returns default message when null', () {
      expect(firestoreErrorMessage(null), 'Something went wrong.');
    });

    test('returns connection message for unavailable', () {
      expect(
        firestoreErrorMessage('UNAVAILABLE'),
        'Connection issue. Check your internet and tap Retry.',
      );
    });

    test('returns connection message for unable to resolve host', () {
      expect(
        firestoreErrorMessage('unable to resolve host'),
        'Connection issue. Check your internet and tap Retry.',
      );
    });

    test('returns connection message for connection error', () {
      expect(
        firestoreErrorMessage('connection failed'),
        'Connection issue. Check your internet and tap Retry.',
      );
    });

    test('returns connection message for network error', () {
      expect(
        firestoreErrorMessage('network error'),
        'Connection issue. Check your internet and tap Retry.',
      );
    });

    test('returns access denied for permission-denied', () {
      expect(
        firestoreErrorMessage('permission-denied'),
        'Access denied. Deploy Firestore rules and sign in again.',
      );
    });

    test('returns access denied for permission error', () {
      expect(
        firestoreErrorMessage('permission error'),
        'Access denied. Deploy Firestore rules and sign in again.',
      );
    });

    test('returns generic message for unknown error', () {
      expect(
        firestoreErrorMessage(Exception('Unknown')),
        'Something went wrong. Tap Retry to try again.',
      );
    });
  });
}
