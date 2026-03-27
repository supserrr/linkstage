// Summarizes line coverage for lib/domain and lib/core/utils from coverage/lcov.info.
// Run from project root after: flutter test --coverage
// Usage: dart run tool/coverage_domain_utils.dart [path/to/lcov.info]

import 'dart:io';

bool _included(String path) =>
    path.startsWith('lib/domain/') || path.startsWith('lib/core/utils/');

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'coverage/lcov.info';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path — run: flutter test --coverage');
    exitCode = 1;
    return;
  }

  final raw = file.readAsStringSync();
  var lf = 0, lh = 0;

  for (final chunk in raw.split('end_of_record')) {
    final t = chunk.trim();
    if (t.isEmpty) continue;
    String? sf;
    for (final line in t.split('\n')) {
      if (line.startsWith('SF:')) sf = line.substring(3).trim();
    }
    if (sf == null || !_included(sf)) continue;
    for (final line in t.split('\n')) {
      if (line.startsWith('LF:')) lf += int.tryParse(line.substring(3).trim()) ?? 0;
      if (line.startsWith('LH:')) lh += int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }

  final pct = lf > 0 ? 100.0 * lh / lf : 0.0;
  stdout.writeln(
    'lib/domain + lib/core/utils: $lh / $lf (${pct.toStringAsFixed(2)}%) from $path',
  );
}
