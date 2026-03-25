/// Formats numbers and money with comma-separated thousands (e.g. 1,000).
class NumberFormatter {
  // Intentionally uncovered: library-private constructor prevents instantiation
  // of this static-only utility class, and is not reachable from tests.
  NumberFormatter._();

  /// Formats a whole number with comma separators (e.g. 1000 -> "1,000").
  static String formatInteger(num value) {
    if (value.isNaN || value.isInfinite) return value.toString();
    final s = value.toInt().abs().toString();
    final neg = value.toInt().isNegative;
    final buffer = StringBuffer();
    var i = 0;
    final len = s.length;
    final firstGroupLen = len % 3;
    if (firstGroupLen > 0) {
      buffer.write(s.substring(0, firstGroupLen));
      i = firstGroupLen;
    }
    while (i < len) {
      if (i > 0) buffer.write(',');
      buffer.write(s.substring(i, i + 3));
      i += 3;
    }
    return neg ? '-$buffer' : buffer.toString();
  }

  /// Formats a double as a whole number with commas (e.g. 1500.99 -> "1,501").
  static String formatMoney(num value) {
    if (value.isNaN || value.isInfinite) return value.toString();
    return formatInteger(value.round());
  }

  /// Formats numbers (4+ digits) within a string, e.g. "50000-100000" -> "50,000-100,000".
  static String formatNumbersInString(String text) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(
      RegExp(r'\d{4,}'),
      (m) => formatInteger(int.tryParse(m.group(0)!) ?? 0),
    );
  }
}
