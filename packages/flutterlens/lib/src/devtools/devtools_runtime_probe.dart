import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:vm_service/vm_service.dart';

class DevToolsRuntimeProbe implements LensRuntimeProbe {
  static const _inspectorReadyExtension =
      'ext.flutter.inspector.isWidgetTreeReady';
  static const _serviceTimeout = Duration(seconds: 3);

  @override
  Future<LensRuntimeInfo> probe() async {
    if (!serviceManager.connectedState.value.connected) {
      throw StateError('No VM Service connection is active.');
    }

    final service = await serviceManager.onServiceAvailable.timeout(
      _serviceTimeout,
    );
    final connectedApp = serviceManager.connectedApp;
    if (connectedApp == null || !serviceManager.connectedAppInitialized) {
      throw StateError('The connected application is not initialized.');
    }

    final isFlutterApp = connectedApp.isFlutterAppNow ?? false;
    final mainIsolate = serviceManager.isolateManager.mainIsolate.value;
    final inspectorAvailable = isFlutterApp
        ? await _probeInspector(service, mainIsolate)
        : false;
    final vm = serviceManager.vm ?? await service.getVM();
    final buildMode = !isFlutterApp
        ? LensBuildMode.unknown
        : connectedApp.isProfileBuildNow == true
        ? LensBuildMode.profile
        : LensBuildMode.debug;

    return LensRuntimeInfo(
      flutterVersion: isFlutterApp
          ? connectedApp.flutterVersionNow?.version
          : null,
      dartSdkVersion: serviceManager.sdkVersion ?? vm.version,
      operatingSystem: connectedApp.operatingSystem == 'unknown_OS'
          ? null
          : connectedApp.operatingSystem,
      vmName: vm.name,
      mainIsolateName: mainIsolate?.name,
      mainIsolateId: mainIsolate?.id,
      buildMode: buildMode,
      inspectorAvailable: inspectorAvailable,
      dtdAvailable: dtdManager.hasConnection,
    );
  }

  Future<bool> _probeInspector(
    VmService service,
    IsolateRef? mainIsolate,
  ) async {
    final isolateId = mainIsolate?.id;
    if (isolateId == null) return false;

    final extensionManager = serviceManager.serviceExtensionManager;
    var available = extensionManager.isServiceExtensionAvailable(
      _inspectorReadyExtension,
    );
    if (!available) {
      try {
        available = await extensionManager
            .waitForServiceExtensionAvailable(_inspectorReadyExtension)
            .timeout(_serviceTimeout, onTimeout: () => false);
      } catch (error, stackTrace) {
        LensLogger.warning(
          'Inspector service extension did not become available.',
          error: error,
          stackTrace: stackTrace,
        );
        return false;
      }
    }
    if (!available) return false;

    try {
      await service.callServiceExtension(
        _inspectorReadyExtension,
        isolateId: isolateId,
      );
      return true;
    } on RPCError catch (error, stackTrace) {
      LensLogger.warning(
        'Flutter Inspector service extension call failed.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not probe the Flutter Inspector service extension.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
