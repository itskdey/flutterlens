import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:vm_service/vm_service.dart';

import 'inspector_diagnostics_mapper.dart';

class DevToolsWidgetTreeSource implements LensWidgetTreeSource {
  DevToolsWidgetTreeSource({
    InspectorDiagnosticsMapper mapper = const InspectorDiagnosticsMapper(),
  }) : _mapper = mapper,
       _groupName = _nextGroupName();

  static const _rootExtension = 'ext.flutter.inspector.getRootWidgetTree';
  static const _childrenExtension =
      'ext.flutter.inspector.getChildrenSummaryTree';
  static const _readyExtension = 'ext.flutter.inspector.isWidgetTreeReady';
  static const _disposeGroupExtension = 'ext.flutter.inspector.disposeGroup';
  static const _serviceTimeout = Duration(seconds: 3);

  static int _groupCounter = 0;

  final InspectorDiagnosticsMapper _mapper;
  String _groupName;
  bool _disposed = false;

  @override
  Future<LensWidget?> getRootWidget() async {
    final context = await _contextFor(_rootExtension);
    if (!await _isWidgetTreeReady(context.service, context.isolateId)) {
      return null;
    }

    final response = await context.service.callServiceExtension(
      _rootExtension,
      isolateId: context.isolateId,
      args: {
        'groupName': _groupName,
        'isSummaryTree': 'true',
        'withPreviews': 'true',
        'fullDetails': 'false',
      },
    );
    final result = _resultOf(response, _rootExtension);
    if (result is! Map) {
      throw StateError('Flutter Inspector returned an invalid root widget.');
    }
    return _mapper.fromJson(result.cast<String, Object?>());
  }

  @override
  Future<List<LensWidget>> getChildren(LensWidget widget) async {
    if (!widget.hasChildren) return const [];

    final context = await _contextFor(_childrenExtension);
    final response = await context.service.callServiceExtension(
      _childrenExtension,
      isolateId: context.isolateId,
      args: {
        'objectGroup': _groupName,
        'arg': widget.id,
      },
    );
    return _mapper.listFromJson(_resultOf(response, _childrenExtension));
  }

  @override
  Future<void> refresh() async {
    _checkNotDisposed();
    await _disposeCurrentGroup();
    _groupName = _nextGroupName();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await _disposeCurrentGroup();
    _disposed = true;
  }

  Future<({VmService service, String isolateId})> _contextFor(
    String extension,
  ) async {
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
        'Widget tree queries are unavailable while the main isolate is paused.',
      );
    }

    final service = await serviceManager.onServiceAvailable.timeout(
      _serviceTimeout,
    );
    final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;
    if (isolateId == null) {
      throw StateError('Flutter main isolate is unavailable.');
    }
    if (!await _waitForExtension(extension)) {
      throw StateError('Flutter Inspector extension $extension is unavailable.');
    }
    return (service: service, isolateId: isolateId);
  }

  Future<bool> _isWidgetTreeReady(VmService service, String isolateId) async {
    if (!await _waitForExtension(_readyExtension)) return false;
    final response = await service.callServiceExtension(
      _readyExtension,
      isolateId: isolateId,
    );
    final result = _resultOf(response, _readyExtension);
    return result == true || result == 'true';
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
        'Flutter Inspector extension $name did not become available.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Object? _resultOf(Response response, String method) {
    final json = response.json;
    if (json == null) {
      throw StateError('Flutter Inspector returned no response for $method.');
    }
    final errorMessage = json['errorMessage'];
    if (errorMessage != null) {
      throw StateError('$method failed: $errorMessage');
    }
    return json['result'];
  }

  Future<void> _disposeCurrentGroup() async {
    if (!serviceManager.connectedState.value.connected) return;
    final service = serviceManager.service;
    final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;
    if (service == null || isolateId == null) return;
    if (!serviceManager.serviceExtensionManager.isServiceExtensionAvailable(
      _disposeGroupExtension,
    )) {
      return;
    }

    try {
      await service.callServiceExtension(
        _disposeGroupExtension,
        isolateId: isolateId,
        args: {'objectGroup': _groupName},
      );
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not dispose Flutter Inspector object group $_groupName.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('DevToolsWidgetTreeSource has been disposed.');
    }
  }

  static String _nextGroupName() {
    final id = _groupCounter++;
    return 'flutterlens-tree-$id';
  }
}
