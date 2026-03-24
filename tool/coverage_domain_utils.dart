// Summarizes line coverage for lib/domain and lib/core/utils from coverage/lcov.info.
// Run from project root after: flutter test --coverage
// Usage: dart run tool/coverage_domain_utils.dart [path/to/lcov.info]

import 'dart:io';

bool _scopedPath(String sfPath) {
  return sfPath.contains('lib/domain/') || sfPath.contains('lib/core/utils/');
}

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'coverage/lcov.info';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path — run: flutter test --coverage');
    exitCode = 1;
    return;
  }
  final content = file.readAsStringSync();
  final records = content.split('end_of_record');
  var lf = 0;
  var lh = 0;
  for (final r in records) {
    final lines = r.split('\n');
    String? sfPath;
    for (final line in lines) {
      if (line.startsWith('SF:')) {
        sfPath = line.substring(3).trim();
        break;
      }
    }
    if (sfPath == null || !_scopedPath(sfPath)) continue;

    for (final line in lines) {
      if (line.startsWith('LF:')) {
        lf += int.tryParse(line.substring(3).trim()) ?? 0;
      } else if (line.startsWith('LH:')) {
        lh += int.tryParse(line.substring(3).trim()) ?? 0;
      }
    }
  }

  if (lf <= 0) {
    stdout.writeln('No LF entries for lib/domain or lib/core/utils in $path');
    exitCode = 1;
    return;
  }
  final pct = 100.0 * lh / lf;
  stdout.writeln(
    'Scoped (lib/domain + lib/core/utils): Lines hit: $lh / $lf (${pct.toStringAsFixed(2)}%)',
  );
}
