/// Dart VM exception break behavior for the active Flutter isolate.
enum LensExceptionPauseMode {
  none('None', 'Ignore exceptions'),
  unhandled('Unhandled', 'Pause on unhandled'),
  all('All', 'Pause on all');

  const LensExceptionPauseMode(this.vmValue, this.label);

  final String vmValue;
  final String label;

  static LensExceptionPauseMode? fromVmValue(String? value) {
    for (final mode in values) {
      if (mode.vmValue == value) return mode;
    }
    return null;
  }
}
