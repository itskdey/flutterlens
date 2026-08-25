import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:vm_service/vm_service.dart';

class DevToolsPerformanceSource implements LensPerformanceSource {
  static const _trackRebuildsExtension =
      'ext.flutter.inspector.trackRebuildDirtyWidgets';
  static const _trackRepaintsExtension =
      'ext.flutter.inspector.trackRepaintWidgets';
  static const _locationMapExtension =
      'ext.flutter.inspector.widgetLocationIdMap';
  static const _frameEvent = 'Flutter.Frame';
  static const _rebuildEvent = 'Flutter.RebuiltWidgets';
  static const _repaintEvent = 'Flutter.RepaintWidgets';
  static const _serviceTimeout = Duration(seconds: 3);

  final StreamController<LensPerformanceUpdate> _updates =
      StreamController<LensPerformanceUpdate>.broadcast();
  final Map<int, _PerformanceLocation> _locations = {};

  StreamSubscription<Event>? _extensionSubscription;
  String? _activeIsolateId;
  bool _started = false;
  bool _disposed = false;
  bool _rebuildTrackingEnabled = false;
  bool _repaintTrackingEnabled = false;

  @override
  Stream<LensPerformanceUpdate> get updates => _updates.stream;

  @override
  bool get rebuildTrackingEnabled => _rebuildTrackingEnabled;

  @override
  bool get repaintTrackingEnabled => _repaintTrackingEnabled;

  @override
  Future<void> start() async {
    _checkNotDisposed();
    if (_started) return;
    final context = await _context();
    _extensionSubscription = context.service.onExtensionEvent.listen(
      _handleExtensionEvent,
      onError: (Object error, StackTrace stackTrace) {
        LensLogger.warning(
          'Flutter performance event stream failed.',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _started = true;

    // Rebuild counting is the primary Phase 6 signal. Repaint tracking is kept
    // opt-in because profiling paints adds more instrumentation overhead.
    await setRebuildTracking(true);
  }

  @override
  Future<void> setRebuildTracking(bool enabled) async {
    _checkNotDisposed();
    if (_rebuildTrackingEnabled == enabled) return;
    await _setTrackingExtension(_trackRebuildsExtension, enabled);
    _rebuildTrackingEnabled = enabled;
  }

  @override
  Future<void> setRepaintTracking(bool enabled) async {
    _checkNotDisposed();
    if (_repaintTrackingEnabled == enabled) return;
    await _setTrackingExtension(_trackRepaintsExtension, enabled);
    _repaintTrackingEnabled = enabled;
  }

  Future<void> _handleExtensionEvent(Event event) async {
    if (_disposed || event.extensionData == null) return;
    final kind = event.extensionKind;
    if (kind != _frameEvent && kind != _rebuildEvent && kind != _repaintEvent) {
      return;
    }

    final isolateId = event.isolate?.id;
    if (isolateId != null && isolateId != _activeIsolateId) {
      _activeIsolateId = isolateId;
      _locations.clear();
    }

    final data = event.extensionData!.data;
    try {
      if (kind == _frameEvent) {
        final frame = _parseFrame(data);
        if (frame != null) {
          _updates.add(
            LensPerformanceUpdate(frame: frame, frameNumber: frame.frameNumber),
          );
        }
        return;
      }

      _processLocations(data['locations']);
      final unresolvedIds = _unresolvedIds(data['events']);
      if (unresolvedIds.isNotEmpty) {
        await _resolveLocations();
      }
      final samples = _parseSamples(data['events']);
      final frameNumber = _asInt(data['frameNumber']);
      if (kind == _rebuildEvent) {
        _updates.add(
          LensPerformanceUpdate(
            frameNumber: frameNumber,
            rebuilds: samples,
          ),
        );
      } else {
        _updates.add(
          LensPerformanceUpdate(
            frameNumber: frameNumber,
            repaints: samples,
          ),
        );
      }
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not parse Flutter performance event $kind.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  LensFrameMetric? _parseFrame(Map<String, dynamic> data) {
    final frameNumber = _asInt(data['number']);
    final build = _asInt(data['build']);
    final raster = _asInt(data['raster']);
    final elapsed = _asInt(data['elapsed']);
    final vsync = _asInt(data['vsyncOverhead']);
    if (frameNumber == null ||
        build == null ||
        raster == null ||
        elapsed == null ||
        vsync == null) {
      return null;
    }
    return LensFrameMetric(
      frameNumber: frameNumber,
      buildTime: Duration(microseconds: build),
      rasterTime: Duration(microseconds: raster),
      elapsedTime: Duration(microseconds: elapsed),
      vsyncOverhead: Duration(microseconds: vsync),
    );
  }

  void _processLocations(Object? rawLocations) {
    if (rawLocations is! Map) return;
    for (final entry in rawLocations.entries) {
      final file = entry.key.toString();
      final raw = entry.value;
      if (raw is! Map) continue;
      final ids = _intList(raw['ids']);
      final lines = _intList(raw['lines']);
      final columns = _intList(raw['columns']);
      final names = _stringList(raw['names']);
      final length = [ids.length, lines.length, columns.length, names.length]
          .reduce((a, b) => a < b ? a : b);
      for (var index = 0; index < length; index++) {
        _locations[ids[index]] = _PerformanceLocation(
          name: names[index],
          source: LensSourceLocation(
            file: file,
            line: lines[index],
            column: columns[index],
          ),
        );
      }
    }
  }

  Set<int> _unresolvedIds(Object? rawEvents) {
    final events = _intList(rawEvents);
    final unresolved = <int>{};
    for (var index = 0; index + 1 < events.length; index += 2) {
      final id = events[index];
      if (!_locations.containsKey(id)) unresolved.add(id);
    }
    return unresolved;
  }

  List<LensPerformanceSample> _parseSamples(Object? rawEvents) {
    final events = _intList(rawEvents);
    final samples = <LensPerformanceSample>[];
    for (var index = 0; index + 1 < events.length; index += 2) {
      final id = events[index];
      final count = events[index + 1];
      final location = _locations[id];
      samples.add(
        LensPerformanceSample(
          name: location?.name ?? 'Location #$id',
          count: count,
          sourceLocation: location?.source,
        ),
      );
    }
    return samples;
  }

  Future<void> _resolveLocations() async {
    final context = await _context();
    if (!await _waitForExtension(_locationMapExtension)) return;
    final response = await context.service.callServiceExtension(
      _locationMapExtension,
      isolateId: context.isolateId,
    );
    final json = response.json;
    if (json?['errorMessage'] != null) {
      throw StateError(
        '$_locationMapExtension failed: ${json!['errorMessage']}',
      );
    }
    _processLocations(json?['result']);
  }

  Future<void> _setTrackingExtension(String extension, bool enabled) async {
    final context = await _context();
    if (!await _waitForExtension(extension)) {
      throw StateError('Flutter performance extension $extension is unavailable.');
    }
    final response = await context.service.callServiceExtension(
      extension,
      isolateId: context.isolateId,
      args: {'enabled': enabled},
    );
    final json = response.json;
    if (json?['errorMessage'] != null) {
      throw StateError('$extension failed: ${json!['errorMessage']}');
    }
  }

  Future<({VmService service, String isolateId})> _context() async {
    _checkNotDisposed();
    if (!serviceManager.connectedState.value.connected) {
      throw StateError('No VM Service connection is active.');
    }
    if (!serviceManager.connectedAppInitialized ||
        serviceManager.connectedApp?.isFlutterAppNow != true) {
      throw StateError('The connected application is not a Flutter app.');
    }
    if (serviceManager.isMainIsolatePaused) {
      throw StateError(
        'Performance instrumentation is unavailable while the main isolate is paused.',
      );
    }
    final service = await serviceManager.onServiceAvailable.timeout(
      _serviceTimeout,
    );
    final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;
    if (isolateId == null) {
      throw StateError('Flutter main isolate is unavailable.');
    }
    return (service: service, isolateId: isolateId);
  }

  Future<bool> _waitForExtension(String name) async {
    final manager = serviceManager.serviceExtensionManager;
    if (manager.isServiceExtensionAvailable(name)) return true;
    try {
      return await manager
          .waitForServiceExtensionAvailable(name)
          .timeout(_serviceTimeout, onTimeout: () => false);
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Flutter performance extension $name did not become available.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  List<int> _intList(Object? value) {
    if (value is! List) return const [];
    return value.map(_asInt).whereType<int>().toList(growable: false);
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  int? _asInt(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('DevToolsPerformanceSource has been disposed.');
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    try {
      if (_rebuildTrackingEnabled &&
          serviceManager.connectedState.value.connected &&
          !serviceManager.isMainIsolatePaused) {
        await _setTrackingExtension(_trackRebuildsExtension, false);
      }
      if (_repaintTrackingEnabled &&
          serviceManager.connectedState.value.connected &&
          !serviceManager.isMainIsolatePaused) {
        await _setTrackingExtension(_trackRepaintsExtension, false);
      }
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not disable Flutter performance instrumentation.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    _rebuildTrackingEnabled = false;
    _repaintTrackingEnabled = false;
    await _extensionSubscription?.cancel();
    await _updates.close();
    _disposed = true;
  }
}

class _PerformanceLocation {
  const _PerformanceLocation({required this.name, required this.source});

  final String name;
  final LensSourceLocation source;
}
