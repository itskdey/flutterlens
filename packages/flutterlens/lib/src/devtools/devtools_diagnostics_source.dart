import 'dart:async';

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:vm_service/vm_service.dart';

import 'diagnostics_event_mapper.dart';

class DevToolsDiagnosticsSource implements LensDiagnosticsSource {
  DevToolsDiagnosticsSource({DiagnosticsEventMapper? mapper})
      : _mapper = mapper ?? const DiagnosticsEventMapper();

  final DiagnosticsEventMapper _mapper;
  final StreamController<LensDiagnostic> _events =
      StreamController<LensDiagnostic>.broadcast();

  StreamSubscription<Event>? _extensionSubscription;
  StreamSubscription<Event>? _debugSubscription;
  VmService? _boundService;
  bool _disposed = false;
  int _nextId = 0;

  @override
  Stream<LensDiagnostic> get events => _events.stream;

  @override
  Future<void> start() async {
    if (_disposed) throw StateError('Diagnostics source has been disposed.');
    if (!serviceManager.connectedState.value.connected) {
      throw StateError('No VM Service connection is active.');
    }
    final service = await serviceManager.onServiceAvailable
        .timeout(const Duration(seconds: 3));
    if (identical(service, _boundService) &&
        _extensionSubscription != null &&
        _debugSubscription != null) {
      return;
    }

    await _extensionSubscription?.cancel();
    await _debugSubscription?.cancel();
    _boundService = service;
    _extensionSubscription = service.onExtensionEvent.listen(
      _handleExtensionEvent,
      onError: _logStreamError,
    );
    _debugSubscription = service.onDebugEvent.listen(
      _handleDebugEvent,
      onError: _logStreamError,
    );
  }

  void _handleExtensionEvent(Event event) {
    if (_disposed ||
        event.extensionKind != 'Flutter.Error' ||
        event.extensionData == null ||
        !_isActiveIsolate(event)) {
      return;
    }
    final diagnostic = _mapper.fromFlutterError(
      event.extensionData!.data,
      id: ++_nextId,
      timestamp: _timestamp(event),
      isolateId: event.isolate?.id,
    );
    if (diagnostic != null && !_events.isClosed) _events.add(diagnostic);
  }

  void _handleDebugEvent(Event event) {
    if (_disposed ||
        event.kind != EventKind.kPauseException ||
        !_isActiveIsolate(event)) {
      return;
    }
    final diagnostic = _mapper.fromPausedException(
      id: ++_nextId,
      timestamp: _timestamp(event),
      isolateId: event.isolate?.id,
      description: event.exception?.valueAsString,
    );
    if (!_events.isClosed) _events.add(diagnostic);
  }

  bool _isActiveIsolate(Event event) {
    final active = serviceManager.isolateManager.mainIsolate.value?.id;
    final incoming = event.isolate?.id;
    return active == null || incoming == null || incoming == active;
  }

  DateTime _timestamp(Event event) {
    final value = event.timestamp;
    return value == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(value);
  }

  void _logStreamError(Object error, StackTrace stackTrace) {
    LensLogger.warning(
      'Flutter diagnostic event stream failed.',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> navigateToSource(LensSourceLocation source) async {
    if (_disposed) throw StateError('Diagnostics source has been disposed.');
    final path = source.file;
    final uri = path.startsWith('file:')
        ? Uri.tryParse(path)
        : path.startsWith('/')
            ? Uri.file(path)
            : RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path)
                ? Uri.file(path, windows: true)
                : null;
    if (uri == null || uri.scheme != 'file') {
      throw StateError('Cannot navigate to a non-local Dart source.');
    }
    final service = await serviceManager.onServiceAvailable
        .timeout(const Duration(seconds: 3));
    try {
      await service.postEvent('ToolEvent', 'navigate', <String, Object>{
        'fileUri': uri.toString(),
        'line': source.line ?? 1,
        'column': source.column ?? 1,
        'source': 'FlutterLens.diagnostics',
      });
    } on RPCError catch (error) {
      if (error.code == RPCErrorKind.kCustomStreamDoesNotExist.code) return;
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _extensionSubscription?.cancel();
    await _debugSubscription?.cancel();
    _boundService = null;
    await _events.close();
  }
}
