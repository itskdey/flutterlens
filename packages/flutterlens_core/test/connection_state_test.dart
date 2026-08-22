import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:test/test.dart';

void main() {
  test('disconnected snapshot reports disconnected state', () {
    const snapshot = LensConnectionSnapshot.disconnected();

    expect(snapshot.status, LensConnectionStatus.disconnected);
    expect(snapshot.isConnected, isFalse);
    expect(snapshot.vmServiceAvailable, isFalse);
  });

  test('connected snapshot reports connected state', () {
    const snapshot = LensConnectionSnapshot(
      status: LensConnectionStatus.connected,
      isFlutterApp: true,
      vmServiceAvailable: true,
    );

    expect(snapshot.isConnected, isTrue);
    expect(snapshot.isFlutterApp, isTrue);
  });
}
