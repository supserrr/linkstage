// Regenerates coverage/lcov_filtered.info from coverage/lcov.info by removing
// excluded sources, then prints filtered line hit / found and optional CI gate.
// Run after: flutter test --coverage
//
// CI gate: use --min-percent=80 to fail if filtered line coverage is below threshold.
//
//   dart run tool/coverage_filtered.dart
//   dart run tool/coverage_filtered.dart --min-percent=80
//
// Exclusions are documented in [docs/setup.md](../docs/setup.md). Whole-repo
// `coverage/lcov.info` is for full-app review.

import 'dart:io';

/// Paths excluded in addition to [lib/l10n/] and [lib/presentation/pages/].
const _excludedExactPaths = <String>{
  'lib/core/router/app_router.dart',
  'lib/core/router/auth_redirect.dart',
  'lib/core/di/injection.dart',
  'lib/firebase_options.dart',
  'lib/data/datasources/auth_remote_datasource.dart',
  'lib/core/services/fcm_service.dart',
};

bool _excludedSourceFile(String path) {
  if (path.startsWith('lib/l10n/')) return true;
  if (path.startsWith('lib/presentation/pages/')) return true;
  return _excludedExactPaths.contains(path);
}

void main(List<String> args) {
  double? minPercent;
  for (final a in args) {
    if (a.startsWith('--min-percent=')) {
      minPercent = double.tryParse(a.substring('--min-percent='.length));
    }
  }

  const inputPath = 'coverage/lcov.info';
  const outputPath = 'coverage/lcov_filtered.info';

  final input = File(inputPath);
  if (!input.existsSync()) {
    stderr.writeln('Missing $inputPath — run: flutter test --coverage');
    exitCode = 1;
    return;
  }

  final raw = input.readAsStringSync();
  final chunks = raw.split('end_of_record');
  final out = StringBuffer();
  var lfTotal = 0;
  var lhTotal = 0;

  for (final chunk in chunks) {
    final trimmed = chunk.trim();
    if (trimmed.isEmpty) continue;

    final lines = trimmed.split('\n');
    String? sf;
    for (final line in lines) {
      if (line.startsWith('SF:')) {
        sf = line.substring(3).trim();
        break;
      }
    }
    if (sf == null) continue;

    if (_excludedSourceFile(sf)) continue;

    out.writeln(trimmed);
    out.writeln('end_of_record');

    for (final line in lines) {
      if (line.startsWith('LF:')) {
        lfTotal += int.tryParse(line.substring(3).trim()) ?? 0;
      } else if (line.startsWith('LH:')) {
        lhTotal += int.tryParse(line.substring(3).trim()) ?? 0;
      }
    }
  }

  File(outputPath).writeAsStringSync(out.toString());

  final pct = lfTotal > 0 ? 100.0 * lhTotal / lfTotal : 0.0;
  stdout.writeln(
    'Filtered (see _excludedExactPaths / l10n prefix in this file): '
    '$lhTotal / $lfTotal (${pct.toStringAsFixed(2)}%) → $outputPath',
  );

  if (minPercent != null && pct + 1e-9 < minPercent) {
    stderr.writeln(
      'FAILED: filtered coverage ${pct.toStringAsFixed(2)}% is below '
      '--min-percent=$minPercent',
    );
    exitCode = 1;
  }
}
