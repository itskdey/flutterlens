import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

class DevToolsConnectionSource implements LensConnectionSource {
  @override
  LensConnectionSnapshot get current {
    final connected = serviceManager.connectedState.value.connected;
    if (!connected) return const LensConnectionSnapshot.disconnected();

    final isFlutterApp = serviceManager.connectedApp?.isFlutterAppNow ?? false;
    return LensConnectionSnapshot(
      status: LensConnectionStatus.connected,
      isFlutterApp: isFlutterApp,
      vmServiceAvailable: serviceManager.isServiceAvailable,
      message: isFlutterApp
          ? 'Flutter debug application connected'
          : 'VM Service connected',
    );
  }

  @override
  void addListener(LensConnectionListener listener) {
    serviceManager.connectedState.addListener(listener);
  }

  @override
  void removeListener(LensConnectionListener listener) {
    serviceManager.connectedState.removeListener(listener);
  }
}
