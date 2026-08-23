import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

class LensConnectionController extends ChangeNotifier {
  LensConnectionController(this._source, this._runtimeProbe)
      : _snapshot = _source.current {
    _source.addListener(_handleSourceChanged);
    if (_snapshot.isConnected) {
      unawaited(refreshRuntime());
    }
  }

  final LensConnectionSource _source;
  final LensRuntimeProbe _runtimeProbe;

  LensConnectionSnapshot _snapshot;
  LensRuntimeInfo? _runtimeInfo;
  LensError? _runtimeError;
  bool _isLoadingRuntime = false;
  bool _isDisposed = false;
  int _probeGeneration = 0;

  LensConnectionSnapshot get snapshot => _snapshot;
  LensRuntimeInfo? get runtimeInfo => _runtimeInfo;
  LensError? get runtimeError => _runtimeError;
  bool get isLoadingRuntime => _isLoadingRuntime;

  Future<void> refreshRuntime() async {
    if (!_snapshot.isConnected || _isDisposed) return;

    final generation = ++_probeGeneration;
    _isLoadingRuntime = true;
    _runtimeError = null;
    notifyListeners();

    try {
      final runtimeInfo = await _runtimeProbe.probe();
      if (_isDisposed || generation != _probeGeneration) return;
      _runtimeInfo = runtimeInfo;
    } catch (error, stackTrace) {
      if (_isDisposed || generation != _probeGeneration) return;
      _runtimeInfo = null;
      _runtimeError = LensError(
        code: 'runtime_probe_failed',
        message: 'Could not read runtime information from the connected app.',
        cause: error,
      );
      LensLogger.error(
        'Runtime probe failed.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_isDisposed && generation == _probeGeneration) {
        _isLoadingRuntime = false;
        notifyListeners();
      }
    }
  }

  void _handleSourceChanged() {
    final previous = _snapshot;
    final next = _source.current;
    if (next == previous) return;

    _snapshot = next;
    if (!next.isConnected) {
      _probeGeneration++;
      _runtimeInfo = null;
      _runtimeError = null;
      _isLoadingRuntime = false;
    }
    notifyListeners();

    if (!previous.isConnected && next.isConnected) {
      unawaited(refreshRuntime());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _probeGeneration++;
    _source.removeListener(_handleSourceChanged);
    super.dispose();
  }
}
