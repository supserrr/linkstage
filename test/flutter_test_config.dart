import 'dart:async';

import 'package:logger/logger.dart';

/// Quieter `flutter test` output: flutter_map uses [Logger] at info/warning for
/// OSM notices; the app uses [debugPrint] behind [kDebugMode] + `FLUTTER_TEST`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Logger.level = Level.error;
  await testMain();
}
