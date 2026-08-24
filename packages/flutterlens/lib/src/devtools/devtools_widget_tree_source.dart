import 'dart:async';

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:vm_service/vm_service.dart';

import 'inspector_diagnostics_mapper.dart';

class DevToolsWidgetTreeSource extends LensWidgetTreeSource {
  DevToolsWidgetTreeSource({
    InspectorDiagnosticsMapper mapper = const InspectorDiagnosticsMapper(),
  })  : _mapper = mapper,
        _groupName = _nextGroupName();

  static const _rootExtension = 'ext.flutter.inspector.getRootWidgetTree';
  static const _childrenSummaryExtension =
      'ext.flutter.inspector.getChildrenSummaryTree';
  static const _childrenFullExtension = 'ext.flutter.inspector.getChildren';
  static const _selectedSummaryExtension =
      'ext.flutter.inspector.getSelectedSummaryWidget';
  static const _selectedFullExtension =
      'ext.flutter.inspector.getSelectedWidget';
  static const _setSelectionExtension =
      'ext.flutter.inspector.setSelectionById';
  static const _selectModeExtension = 'ext.flutter.inspector.selectMode';
  static const _legacySelectModeExtension = 'ext.flutter.inspector.show';
  static const _readyExtension = 'ext.flutter.inspector.isWidgetTreeReady';
  static const _disposeGroupExtension = 'ext.flutter.inspector.disposeGroup';
  static const _serviceTimeout = Duration(seconds: 3);

  static int _groupCounter = 0;

  final InspectorDiagnosticsMapper _mapper;
  final StreamController<void> _selectionChanges =
      StreamController<void>.broadcast();
  StreamSubscription<Event>? _debugSubscription;
  String _groupName;
  bool _showImplementationWidgets = false;
  bool _selectModeEnabled = false;
  bool _disposed = false;

  @override
  Stream<void> get selectionChanges => _selectionChanges.stream;

  @override
  bool get showImplementationWidgets => _showImplementationWidgets;

  @override
  bool get selectModeEnabled => _selectModeEnabled;

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
        'isSummaryTree': '${!_showImplementationWidgets}',
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

    final extension = _showImplementationWidgets
        ? _childrenFullExtension
        : _childrenSummaryExtension;
    final context = await _contextFor(extension);
    final response = await context.service.callServiceExtension(
      extension,
      isolateId: context.isolateId,
      args: {
        'objectGroup': _groupName,
        'arg': widget.id,
      },
    );
    return _mapper.listFromJson(_resultOf(response, extension));
  }

  @override
  Future<LensWidget?> getSelectedWidget() async {
    final extension = _showImplementationWidgets
        ? _selectedFullExtension
        : _selectedSummaryExtension;
    final context = await _contextFor(extension);
    final response = await context.service.callServiceExtension(
      extension,
      isolateId: context.isolateId,
      args: {'objectGroup': _groupName},
    );
    final result = _resultOf(response, extension);
    if (result == null) return null;
    if (result is! Map) {
      throw StateError('Flutter Inspector returned an invalid selection.');
    }
    return _mapper.fromJson(result.cast<String, Object?>());
  }

  @override
  Future<void> setSelectedWidget(LensWidget widget) async {
    final context = await _contextFor(_setSelectionExtension);
    await context.service.callServiceExtension(
      _setSelectionExtension,
      isolateId: context.isolateId,
      args: {
        'objectGroup': _groupName,
        'arg': widget.id,
      },
    );
  }

  @override
  Future<void> setShowImplementationWidgets(bool value) async {
    _checkNotDisposed();
    _showImplementationWidgets = value;
  }

  @override
  Future<void> setSelectMode(bool enabled) async {
    _checkNotDisposed();
    final extension = await _selectModeExtensionForCurrentApp();
    final context = await _contextFor(extension);
    final response = await context.service.callServiceExtension(
      extension,
      isolateId: context.isolateId,
      args: {'enabled': enabled},
    );
    final json = response.json;
    if (json?['errorMessage'] != null) {
      throw StateError('$extension failed: ${json!['errorMessage']}');
    }
    _selectModeEnabled = enabled;
  }

  @override
  Future<void> navigateToSource(LensSourceLocation source) async {
    _checkNotDisposed();
    final service = await serviceManager.onServiceAvailable.timeout(
      _serviceTimeout,
    );
    final uri = _fileUri(source.file);
    if (uri == null) {
      throw StateError('FlutterLens cannot open non-local source ${source.file}.');
    }

    try {
      await service.postEvent('ToolEvent', 'navigate', <String, Object>{
        'fileUri': uri.toString(),
        'line': source.line ?? 1,
        'column': source.column ?? 1,
        'source': 'FlutterLens.inspector',
      });
    } on RPCError catch (error) {
      if (error.code == RPCErrorKind.kCustomStreamDoesNotExist.code) return;
      rethrow;
    }
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
    await _debugSubscription?.cancel();
    await _disposeCurrentGroup();
    await _selectionChanges.close();
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
    _ensureDebugSubscription(service);
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

  void _ensureDebugSubscription(VmService service) {
    _debugSubscription ??= service.onDebugEvent.listen((event) {
      if (!_disposed && event.kind == EventKind.kInspect) {
        _selectionChanges.add(null);
      }
    });
  }

  Future<String> _selectModeExtensionForCurrentApp() async {
    final manager = serviceManager.serviceExtensionManager;
    if (manager.isServiceExtensionAvailable(_selectModeExtension)) {
      return _selectModeExtension;
    }
    try {
      if (await manager
          .waitForServiceExtensionAvailable(_selectModeExtension)
          .timeout(_serviceTimeout, onTimeout: () => false)) {
        return _selectModeExtension;
      }
    } catch (_) {
      // Fall through to the legacy Inspector toggle.
    }
    if (await _waitForExtension(_legacySelectModeExtension)) {
      return _legacySelectModeExtension;
    }
    throw StateError('Flutter Inspector select mode is unavailable.');
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

  Uri? _fileUri(String file) {
    final parsed = Uri.tryParse(file);
    if (parsed?.scheme == 'file') return parsed;
    if (file.startsWith('/')) return Uri.file(file);
    if (RegExp(r'^[A-Za-z]:[\\/]').hasMatch(file)) {
      return Uri.file(file, windows: true);
    }
    return null;
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
