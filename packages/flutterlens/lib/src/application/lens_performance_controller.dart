import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

class LensPerformanceController extends ChangeNotifier {
  LensPerformanceController(this._source);

  static const maxRecentFrames = 120;

  final LensPerformanceSource _source;
  final Queue<LensFrameMetric> _frames = Queue<LensFrameMetric>();
  final Map<String, _HotspotAccumulator> _hotspots = {};

  StreamSubscription<LensPerformanceUpdate>? _subscription;
  LensError? _error;
  bool _isStarting = false;
  bool _started = false;
  bool _disposed = false;
  int _totalFrames = 0;
  int _jankyFrames = 0;

  bool get isStarting => _isStarting;
  bool get isStarted => _started;
  LensError? get error => _error;
  bool get rebuildTrackingEnabled => _source.rebuildTrackingEnabled;
  bool get repaintTrackingEnabled => _source.repaintTrackingEnabled;
  int get totalFrames => _totalFrames;
  int get jankyFrames => _jankyFrames;
  LensFrameMetric? get latestFrame => _frames.isEmpty ? null : _frames.last;
  List<LensFrameMetric> get recentFrames => List.unmodifiable(_frames);

  double get jankRate => _totalFrames == 0 ? 0 : _jankyFrames / _totalFrames;

  Duration get averageBuildTime => _averageDuration(
        _frames.map((frame) => frame.buildTime),
      );

  Duration get averageRasterTime => _averageDuration(
        _frames.map((frame) => frame.rasterTime),
      );

  List<LensPerformanceHotspot> get hotspots {
    final values = _hotspots.values
        .map((item) => item.toHotspot())
        .where((item) => item.totalActivity > 0)
        .toList(growable: false)
      ..sort((a, b) => b.totalActivity.compareTo(a.totalActivity));
    return values;
  }

  Future<void> start() async {
    if (_disposed || _started || _isStarting) return;
    _isStarting = true;
    _error = null;
    notifyListeners();
    _subscription ??= _source.updates.listen(
      _handleUpdate,
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        _error = LensError(
          code: 'performance_stream_failed',
          message: 'Flutter performance monitoring stopped unexpectedly.',
          cause: error,
        );
        LensLogger.error(
          'Performance event stream failed.',
          error: error,
          stackTrace: stackTrace,
        );
        notifyListeners();
      },
    );

    try {
      await _source.start();
      if (_disposed) return;
      _started = true;
    } catch (error, stackTrace) {
      if (_disposed) return;
      _error = LensError(
        code: 'performance_start_failed',
        message: 'Could not start Flutter performance monitoring.',
        cause: error,
      );
      LensLogger.error(
        'Could not start performance monitoring.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_disposed) {
        _isStarting = false;
        notifyListeners();
      }
    }
  }

  Future<void> setRebuildTracking(bool enabled) async {
    if (_disposed) return;
    try {
      await _source.setRebuildTracking(enabled);
      _error = null;
    } catch (error, stackTrace) {
      _recordToggleError('rebuild', error, stackTrace);
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setRepaintTracking(bool enabled) async {
    if (_disposed) return;
    try {
      await _source.setRepaintTracking(enabled);
      _error = null;
    } catch (error, stackTrace) {
      _recordToggleError('repaint', error, stackTrace);
    }
    if (!_disposed) notifyListeners();
  }

  void clear() {
    if (_disposed) return;
    _frames.clear();
    _hotspots.clear();
    _totalFrames = 0;
    _jankyFrames = 0;
    _error = null;
    notifyListeners();
  }

  void _handleUpdate(LensPerformanceUpdate update) {
    if (_disposed) return;
    final frame = update.frame;
    if (frame != null) {
      _frames.add(frame);
      _totalFrames++;
      if (frame.isJanky) _jankyFrames++;
      while (_frames.length > maxRecentFrames) {
        _frames.removeFirst();
      }
    }

    _accumulate(update.rebuilds, rebuild: true);
    _accumulate(update.repaints, rebuild: false);
    notifyListeners();
  }

  void _accumulate(List<LensPerformanceSample> samples, {required bool rebuild}) {
    for (final sample in samples) {
      final hotspot = _hotspots.putIfAbsent(
        sample.identity,
        () => _HotspotAccumulator(
          name: sample.name,
          sourceLocation: sample.sourceLocation,
        ),
      );
      if (rebuild) {
        hotspot.rebuildCount += sample.count;
      } else {
        hotspot.repaintCount += sample.count;
      }
    }
  }

  void _recordToggleError(
    String signal,
    Object error,
    StackTrace stackTrace,
  ) {
    _error = LensError(
      code: 'performance_${signal}_toggle_failed',
      message: 'Could not update $signal tracking.',
      cause: error,
    );
    LensLogger.error(
      'Could not update $signal tracking.',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Duration _averageDuration(Iterable<Duration> values) {
    var count = 0;
    var totalMicros = 0;
    for (final value in values) {
      count++;
      totalMicros += value.inMicroseconds;
    }
    if (count == 0) return Duration.zero;
    return Duration(microseconds: totalMicros ~/ count);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    unawaited(_source.dispose());
    super.dispose();
  }
}

class _HotspotAccumulator {
  _HotspotAccumulator({required this.name, required this.sourceLocation});

  final String name;
  final LensSourceLocation? sourceLocation;
  int rebuildCount = 0;
  int repaintCount = 0;

  LensPerformanceHotspot toHotspot() {
    return LensPerformanceHotspot(
      name: name,
      sourceLocation: sourceLocation,
      rebuildCount: rebuildCount,
      repaintCount: repaintCount,
    );
  }
}
