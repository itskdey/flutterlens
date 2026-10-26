import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

class LensDiagnosticsController extends ChangeNotifier {
  LensDiagnosticsController(
    this._source, {
    LensDebugControlSource? debugControls,
  }) : _debugControls = debugControls;

  static const maxEvents = 200;

  final LensDiagnosticsSource _source;
  final LensDebugControlSource? _debugControls;
  final Queue<LensDiagnostic> _events = Queue<LensDiagnostic>();

  StreamSubscription<LensDiagnostic>? _subscription;
  LensError? _error;
  LensDiagnostic? _selected;
  String _query = '';
  bool _started = false;
  bool _starting = false;
  bool _disposed = false;
  LensExceptionPauseMode? _exceptionPauseMode;
  LensError? _pauseModeError;
  bool _changingPauseMode = false;
  int _pauseModeRequest = 0;

  bool get isStarted => _started;
  bool get isStarting => _starting;
  LensError? get error => _error;
  int get totalEvents => _events.length;
  LensDiagnostic? get selected => _selected;
  String get query => _query;
  LensExceptionPauseMode? get exceptionPauseMode => _exceptionPauseMode;
  LensError? get pauseModeError => _pauseModeError;
  bool get changingPauseMode => _changingPauseMode;
  List<LensDiagnostic> get events =>
      List.unmodifiable(_events.toList().reversed);

  LensDiagnosticKind? _kindFilter;

  LensDiagnosticKind? get kindFilter => _kindFilter;

  /// Each row represents the most recent occurrence of one matching issue.
  List<LensDiagnostic> get visibleEvents {
    final q = _query.trim().toLowerCase();
    final seen = <String>{};
    final result = <LensDiagnostic>[];
    for (final event in events) {
      if (_kindFilter != null && event.kind != _kindFilter) continue;
      if (q.isNotEmpty &&
          !event.title.toLowerCase().contains(q) &&
          !event.details.toLowerCase().contains(q) &&
          !event.kindLabel.toLowerCase().contains(q) &&
          !(event.sourceLocation?.display.toLowerCase().contains(q) ?? false)) {
        continue;
      }
      if (seen.add(event.fingerprint)) result.add(event);
    }
    return result;
  }

  /// Counts apply to the retained session window, not lifetime totals.
  Map<int, int> get repeatCounts {
    final counts = <String, int>{};
    for (final event in _events) {
      counts.update(event.fingerprint, (value) => value + 1, ifAbsent: () => 1);
    }
    return {
      for (final event in visibleEvents)
        event.id: counts[event.fingerprint] ?? 1,
    };
  }

  void setKindFilter(LensDiagnosticKind? kind) {
    if (_disposed || kind == _kindFilter) return;
    _kindFilter = kind;
    notifyListeners();
  }

  Future<void> refreshExceptionPauseMode() async {
    final controls = _debugControls;
    if (_disposed || controls == null || _changingPauseMode) return;
    final request = ++_pauseModeRequest;
    _pauseModeError = null;
    try {
      final mode = await controls.readExceptionPauseMode();
      if (_disposed || request != _pauseModeRequest) return;
      _exceptionPauseMode = mode;
    } catch (error, stackTrace) {
      if (_disposed || request != _pauseModeRequest) return;
      _exceptionPauseMode = null;
      _pauseModeError = LensError(
        code: 'exception_pause_mode_unavailable',
        message: 'Could not read the debugger exception pause setting.',
        cause: error,
      );
      LensLogger.warning(
        'Could not read exception pause mode.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_disposed && request == _pauseModeRequest) notifyListeners();
    }
  }

  Future<void> setExceptionPauseMode(LensExceptionPauseMode mode) async {
    final controls = _debugControls;
    if (_disposed || !_started || _changingPauseMode || controls == null) {
      return;
    }
    final request = ++_pauseModeRequest;
    _changingPauseMode = true;
    _pauseModeError = null;
    notifyListeners();
    try {
      await controls.setExceptionPauseMode(mode);
      if (!_disposed && request == _pauseModeRequest) {
        _exceptionPauseMode = mode;
      }
    } catch (error, stackTrace) {
      if (_disposed || request != _pauseModeRequest) return;
      _pauseModeError = LensError(
        code: 'exception_pause_mode_failed',
        message: 'Could not update the debugger exception pause setting.',
        cause: error,
      );
      LensLogger.warning(
        'Could not set exception pause mode.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_disposed && request == _pauseModeRequest) {
        _changingPauseMode = false;
        notifyListeners();
      }
    }
  }

  Future<void> openSelectedSource() async {
    final event = _selected;
    final source = event?.sourceLocation;
    if (_disposed ||
        event == null ||
        !event.canNavigateToSource ||
        source == null) {
      return;
    }
    try {
      await _source.navigateToSource(source);
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not navigate to diagnostic source ${source.display}.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> start() async {
    if (_disposed || _starting) return;
    _starting = true;
    _error = null;
    notifyListeners();
    _subscription ??= _source.events.listen(
      _onEvent,
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        _started = false;
        _error = LensError(
          code: 'diagnostics_stream_failed',
          message: 'The Flutter diagnostics stream stopped unexpectedly.',
          cause: error,
        );
        LensLogger.error(
          'Diagnostics stream failed.',
          error: error,
          stackTrace: stackTrace,
        );
        notifyListeners();
      },
    );
    try {
      await _source.start();
      if (!_disposed) {
        _started = true;
        // Inspector capture must keep working even if debugger RPCs fail.
        unawaited(refreshExceptionPauseMode());
      }
    } catch (error, stackTrace) {
      if (_disposed) return;
      _started = false;
      _error = LensError(
        code: 'diagnostics_start_failed',
        message: 'Could not subscribe to Flutter runtime diagnostics.',
        cause: error,
      );
      LensLogger.error(
        'Could not start diagnostics.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_disposed) {
        _starting = false;
        notifyListeners();
      }
    }
  }

  void _onEvent(LensDiagnostic event) {
    if (_disposed) return;
    _events.add(event);
    while (_events.length > maxEvents) {
      final removed = _events.removeFirst();
      if (_selected?.id == removed.id) _selected = null;
    }
    _selected ??= event;
    notifyListeners();
  }

  void select(LensDiagnostic event) {
    if (_disposed) return;
    _selected = event;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_disposed || _query == value) return;
    _query = value;
    notifyListeners();
  }

  void clear() {
    if (_disposed) return;
    _events.clear();
    _selected = null;
    _error = null;
    notifyListeners();
  }

  void markDisconnected() {
    if (_disposed) return;
    ++_pauseModeRequest;
    _exceptionPauseMode = null;
    _pauseModeError = null;
    _changingPauseMode = false;
    _started = false;
    clear();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_pauseModeRequest;
    unawaited(_subscription?.cancel());
    unawaited(_source.dispose());
    super.dispose();
  }
}
