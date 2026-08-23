import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/application/lens_connection_controller.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

void main() {
  test('controller forwards source changes and probes runtime', () async {
    final source = _FakeConnectionSource();
    final probe = _FakeRuntimeProbe();
    final controller = LensConnectionController(source, probe);
    var notifications = 0;
    controller.addListener(() => notifications++);

    source.setSnapshot(
      const LensConnectionSnapshot(
        status: LensConnectionStatus.connected,
        isFlutterApp: true,
        vmServiceAvailable: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.snapshot.isConnected, isTrue);
    expect(controller.runtimeInfo, probe.result);
    expect(probe.calls, 1);
    expect(notifications, greaterThanOrEqualTo(2));

    await controller.refreshRuntime();
    expect(probe.calls, 2);

    controller.dispose();
  });

  test('disconnect clears runtime state', () async {
    final source = _FakeConnectionSource();
    final probe = _FakeRuntimeProbe();
    final controller = LensConnectionController(source, probe);

    source.setSnapshot(
      const LensConnectionSnapshot(
        status: LensConnectionStatus.connected,
        isFlutterApp: true,
        vmServiceAvailable: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.runtimeInfo, isNotNull);

    source.setSnapshot(const LensConnectionSnapshot.disconnected());

    expect(controller.runtimeInfo, isNull);
    expect(controller.runtimeError, isNull);

    controller.dispose();
  });
}

class _FakeConnectionSource implements LensConnectionSource {
  LensConnectionSnapshot _current = const LensConnectionSnapshot.disconnected();
  final List<LensConnectionListener> _listeners = [];

  @override
  LensConnectionSnapshot get current => _current;

  void setSnapshot(LensConnectionSnapshot snapshot) {
    _current = snapshot;
    for (final listener in List<LensConnectionListener>.of(_listeners)) {
      listener();
    }
  }

  @override
  void addListener(LensConnectionListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(LensConnectionListener listener) {
    _listeners.remove(listener);
  }
}

class _FakeRuntimeProbe implements LensRuntimeProbe {
  int calls = 0;

  final LensRuntimeInfo result = const LensRuntimeInfo(
    flutterVersion: '3.47.1',
    dartSdkVersion: '3.11.0',
    operatingSystem: 'macos',
    vmName: 'vm',
    mainIsolateName: 'main',
    mainIsolateId: 'isolates/1',
    buildMode: LensBuildMode.debug,
    inspectorAvailable: true,
    dtdAvailable: true,
  );

  @override
  Future<LensRuntimeInfo> probe() async {
    calls++;
    return result;
  }
}
