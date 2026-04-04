import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatter', () {
    group('formatInteger', () {
      test('formats 0', () {
        expect(NumberFormatter.formatInteger(0), '0');
      });

      test('formats 1000 with comma', () {
        expect(NumberFormatter.formatInteger(1000), '1,000');
      });

      test('formats 1000000 with commas', () {
        expect(NumberFormatter.formatInteger(1000000), '1,000,000');
      });

      test('formats negative number', () {
        expect(NumberFormatter.formatInteger(-5000), '-5,000');
      });

      test('formats NaN as string', () {
        expect(NumberFormatter.formatInteger(double.nan), 'NaN');
      });

      test('formats infinite as string', () {
        expect(NumberFormatter.formatInteger(double.infinity), 'Infinity');
      });

      test('formats single digit', () {
        expect(NumberFormatter.formatInteger(5), '5');
      });

      test('formats two digits', () {
        expect(NumberFormatter.formatInteger(42), '42');
      });

      test('formats three digits without comma', () {
        expect(NumberFormatter.formatInteger(999), '999');
      });
    });

    group('formatMoney', () {
      test('rounds and formats 1500.99 to 1,501', () {
        expect(NumberFormatter.formatMoney(1500.99), '1,501');
      });

      test('formats 0', () {
        expect(NumberFormatter.formatMoney(0), '0');
      });

      test('rounds and formats with commas', () {
        expect(NumberFormatter.formatMoney(1234.56), '1,235');
      });
    });

    group('formatNumbersInString', () {
      test('formats 4+ digit numbers in string', () {
        expect(
          NumberFormatter.formatNumbersInString('50000-100000'),
          '50,000-100,000',
        );
      });

      test('returns empty string unchanged', () {
        expect(NumberFormatter.formatNumbersInString(''), '');
      });

      test('leaves string without 4+ digit numbers unchanged', () {
        expect(NumberFormatter.formatNumbersInString('abc 123'), 'abc 123');
      });

      test('formats multiple numbers in string', () {
        expect(
          NumberFormatter.formatNumbersInString('10000 and 20000'),
          '10,000 and 20,000',
        );
      });
    });
  });
}
