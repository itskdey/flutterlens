import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/application/lens_connection_controller.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

void main() {
  test('controller forwards source changes', () {
    final source = _FakeConnectionSource();
    final controller = LensConnectionController(source);
    var notifications = 0;
    controller.addListener(() => notifications++);

    source.setSnapshot(
      const LensConnectionSnapshot(
        status: LensConnectionStatus.connected,
        isFlutterApp: true,
        vmServiceAvailable: true,
      ),
    );

    expect(controller.snapshot.isConnected, isTrue);
    expect(notifications, 1);

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
