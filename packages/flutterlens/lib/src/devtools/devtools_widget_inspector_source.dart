import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:vm_service/vm_service.dart';

import 'inspector_diagnostics_mapper.dart';

class DevToolsWidgetInspectorSource implements LensWidgetInspectorSource {
  DevToolsWidgetInspectorSource({
    InspectorDiagnosticsMapper mapper = const InspectorDiagnosticsMapper(),
  })  : _mapper = mapper,
        _groupName = _nextGroupName();

  static const _propertiesExtension = 'ext.flutter.inspector.getProperties';
  static const _layoutExtension = 'ext.flutter.inspector.getLayoutExplorerNode';
  static const _disposeGroupExtension = 'ext.flutter.inspector.disposeGroup';
  static const _serviceTimeout = Duration(seconds: 3);

  static int _groupCounter = 0;

  final InspectorDiagnosticsMapper _mapper;
  String _groupName;
  bool _disposed = false;

  @override
  Future<LensWidgetInspection> inspect(LensWidget widget) async {
    _checkNotDisposed();
    await _replaceGroup();

    final context = await _contextFor(_propertiesExtension);
    final propertiesResponse = await context.service.callServiceExtension(
      _propertiesExtension,
      isolateId: context.isolateId,
      args: {
        'objectGroup': _groupName,
        'arg': widget.id,
      },
    );

    LensLayoutInfo? layout;
    if (await _waitForExtension(_layoutExtension)) {
      final layoutResponse = await context.service.callServiceExtension(
        _layoutExtension,
        isolateId: context.isolateId,
        args: {
          'groupName': _groupName,
          'id': widget.id,
          'subtreeDepth': '1',
        },
      );
      layout =
          _mapper.layoutFromJson(_resultOf(layoutResponse, _layoutExtension));
    }

    return LensWidgetInspection(
      widgetId: widget.id,
      properties: _mapper.propertiesFromJson(
        _resultOf(propertiesResponse, _propertiesExtension),
      ),
      layout: layout,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await _disposeCurrentGroup();
    _disposed = true;
  }

  Future<void> _replaceGroup() async {
    await _disposeCurrentGroup();
    _groupName = _nextGroupName();
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
        'Widget inspection is unavailable while the main isolate is paused.',
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
      throw StateError(
        'Flutter Inspector extension $extension is unavailable.',
      );
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
      throw StateError('DevToolsWidgetInspectorSource has been disposed.');
    }
  }

  static String _nextGroupName() {
    final id = _groupCounter++;
    return 'flutterlens-inspector-$id';
  }
}
