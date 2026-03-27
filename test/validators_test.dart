import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns error when null', () {
        expect(Validators.email(null), 'Email is required');
      });

      test('returns error when empty', () {
        expect(Validators.email(''), 'Email is required');
      });

      test('returns error for invalid email', () {
        expect(Validators.email('invalid'), 'Enter a valid email address');
      });

      test('returns null for valid email', () {
        expect(Validators.email('user@example.com'), null);
      });
    });

    group('password', () {
      test('returns error when null', () {
        expect(Validators.password(null), 'Password is required');
      });

      test('returns error when too short', () {
        expect(
          Validators.password('short'),
          'Password must be at least 8 characters',
        );
      });

      test('returns null for valid password', () {
        expect(Validators.password('password123'), null);
      });
    });

    group('required', () {
      test('returns error when null', () {
        expect(Validators.required(null), 'This field is required');
      });

      test('returns error when empty', () {
        expect(Validators.required(''), 'This field is required');
      });

      test('returns error when whitespace only', () {
        expect(Validators.required('   '), 'This field is required');
      });

      test('returns null for valid value', () {
        expect(Validators.required('ok'), null);
      });

      test('returns custom field name when provided', () {
        expect(Validators.required(null, 'Name'), 'Name is required');
      });
    });
  });
}
