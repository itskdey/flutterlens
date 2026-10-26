import '../models/lens_exception_pause_mode.dart';

/// Optional debugger controls, kept separate from diagnostics capture.
///
/// A null mode means the active isolate or its current VM setting is unknown.
abstract interface class LensDebugControlSource {
  Future<LensExceptionPauseMode?> readExceptionPauseMode();

  Future<void> setExceptionPauseMode(LensExceptionPauseMode mode);
}
