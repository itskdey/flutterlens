import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:test/test.dart';

void main() {
  test('runtime info compares by value', () {
    const first = LensRuntimeInfo(
      flutterVersion: '3.47.1',
      dartSdkVersion: '3.11.0',
      buildMode: LensBuildMode.debug,
      inspectorAvailable: true,
      dtdAvailable: false,
    );
    const second = LensRuntimeInfo(
      flutterVersion: '3.47.1',
      dartSdkVersion: '3.11.0',
      buildMode: LensBuildMode.debug,
      inspectorAvailable: true,
      dtdAvailable: false,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first.buildMode.label, 'Debug');
  });
}
