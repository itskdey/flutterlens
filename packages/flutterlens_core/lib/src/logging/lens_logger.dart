enum LensLogLevel { debug, info, warning, error }

typedef LensLogSink = void Function(
  LensLogLevel level,
  String message,
  Object? error,
  StackTrace? stackTrace,
);

class LensLogger {
  LensLogger._();

  static LensLogSink? sink;
  static bool enabled = true;

  static void debug(String message) => _write(LensLogLevel.debug, message);

  static void info(String message) => _write(LensLogLevel.info, message);

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _write(LensLogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _write(LensLogLevel.error, message, error, stackTrace);
  }

  static void _write(
    LensLogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!enabled) return;
    sink?.call(level, message, error, stackTrace);
  }
}
