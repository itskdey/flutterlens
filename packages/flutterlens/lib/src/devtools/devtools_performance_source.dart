import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:vm_service/vm_service.dart';

import 'performance_event_mapper.dart';

class DevToolsPerformanceSource implements LensPerformanceSource {
  DevToolsPerformanceSource({
    PerformanceEventMapper mapper = const PerformanceEventMapper(),
  }) : _mapper = mapper;

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

  final PerformanceEventMapper _mapper;
  final StreamController<LensPerformanceUpdate> _updates =
      StreamController<LensPerformanceUpdate>.broadcast();

  StreamSubscription<Event>? _extensionSubscription;
  VmService? _boundService;
  String? _boundIsolateId;
  String? _activeEventIsolateId;
  bool _hasStartedOnce = false;
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
    final context = await _context();
    final sameBinding = identical(_boundService, context.service) &&
        _boundIsolateId == context.isolateId &&
        _extensionSubscription != null;
    if (sameBinding) return;

    final shouldTrackRebuilds =
        _hasStartedOnce ? _rebuildTrackingEnabled : true;
    final shouldTrackRepaints = _repaintTrackingEnabled;

    await _extensionSubscription?.cancel();
    _boundService = context.service;
    _boundIsolateId = context.isolateId;
    _activeEventIsolateId = context.isolateId;
    _mapper.resetLocations();
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

    _hasStartedOnce = true;
    _rebuildTrackingEnabled = shouldTrackRebuilds;
    _repaintTrackingEnabled = shouldTrackRepaints;

    if (shouldTrackRebuilds) {
      await _setTrackingExtensionOnContext(
        _trackRebuildsExtension,
        true,
        context,
      );
    }
    if (shouldTrackRepaints) {
      await _setTrackingExtensionOnContext(
        _trackRepaintsExtension,
        true,
        context,
      );
    }
  }

  @override
  Future<void> setRebuildTracking(bool enabled) async {
    _checkNotDisposed();
    final context = await _context();
    await _setTrackingExtensionOnContext(
      _trackRebuildsExtension,
      enabled,
      context,
    );
    _rebuildTrackingEnabled = enabled;
  }

  @override
  Future<void> setRepaintTracking(bool enabled) async {
    _checkNotDisposed();
    final context = await _context();
    await _setTrackingExtensionOnContext(
      _trackRepaintsExtension,
      enabled,
      context,
    );
    _repaintTrackingEnabled = enabled;
  }

  Future<void> _handleExtensionEvent(Event event) async {
    if (_disposed || event.extensionData == null) return;
    final kind = event.extensionKind;
    if (kind != _frameEvent && kind != _rebuildEvent && kind != _repaintEvent) {
      return;
    }

    final isolateId = event.isolate?.id;
    if (isolateId != null && isolateId != _activeEventIsolateId) {
      _activeEventIsolateId = isolateId;
      _mapper.resetLocations();
    }

    final data = event.extensionData!.data;
    try {
      if (kind == _frameEvent) {
        final frame = _mapper.frameFromJson(data);
        if (frame != null) {
          _updates.add(
            LensPerformanceUpdate(
              frame: frame,
              frameNumber: frame.frameNumber,
            ),
          );
        }
        return;
      }

      _mapper.processLocations(data['locations']);
      if (_mapper.unresolvedIds(data['events']).isNotEmpty) {
        await _resolveLocations();
      }
      final samples = _mapper.samplesFromEvents(data['events']);
      final frameNumber = _mapper.intValue(data['frameNumber']);
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
    _mapper.processLocations(json?['result']);
  }

  Future<void> _setTrackingExtensionOnContext(
    String extension,
    bool enabled,
    ({VmService service, String isolateId}) context,
  ) async {
    if (!await _waitForExtension(extension)) {
      throw StateError(
        'Flutter performance extension $extension is unavailable.',
      );
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
        final context = await _context();
        await _setTrackingExtensionOnContext(
          _trackRebuildsExtension,
          false,
          context,
        );
      }
      if (_repaintTrackingEnabled &&
          serviceManager.connectedState.value.connected &&
          !serviceManager.isMainIsolatePaused) {
        final context = await _context();
        await _setTrackingExtensionOnContext(
          _trackRepaintsExtension,
          false,
          context,
        );
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
    _boundService = null;
    _boundIsolateId = null;
    _activeEventIsolateId = null;
    await _extensionSubscription?.cancel();
    await _updates.close();
    _disposed = true;
  }
}
