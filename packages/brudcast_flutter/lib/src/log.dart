import 'dart:developer' as developer;

import 'options.dart';

/// Logs from the Dart side of the SDK at the level given to `initialize`. The native SDKs log to
/// Logcat and the unified log themselves.
abstract final class BrudcastLog {
  static BrudcastLogLevel _level = BrudcastLogLevel.warning;

  /// Sets the lowest level that is logged.
  static set level(BrudcastLogLevel level) => _level = level;

  /// Logs a warning.
  static void warning(String message) => _log(BrudcastLogLevel.warning, message);

  /// Logs an error.
  static void error(String message) => _log(BrudcastLogLevel.error, message);

  /// Logs a debug message.
  static void debug(String message) => _log(BrudcastLogLevel.debug, message);

  static void _log(BrudcastLogLevel level, String message) {
    if (level.index < _level.index || _level == BrudcastLogLevel.none) return;
    developer.log(
      message,
      name: 'Brudcast',
      level: switch (level) {
        BrudcastLogLevel.verbose => 300,
        BrudcastLogLevel.debug => 500,
        BrudcastLogLevel.info => 800,
        BrudcastLogLevel.warning => 900,
        BrudcastLogLevel.error || BrudcastLogLevel.none => 1000,
      },
    );
  }
}
