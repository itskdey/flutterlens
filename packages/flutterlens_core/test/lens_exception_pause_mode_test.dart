import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:test/test.dart';

void main() {
  test('maps only documented VM exception pause values', () {
    expect(
      LensExceptionPauseMode.fromVmValue('None'),
      LensExceptionPauseMode.none,
    );
    expect(
      LensExceptionPauseMode.fromVmValue('Unhandled'),
      LensExceptionPauseMode.unhandled,
    );
    expect(
      LensExceptionPauseMode.fromVmValue('All'),
      LensExceptionPauseMode.all,
    );
    expect(LensExceptionPauseMode.fromVmValue('unknown'), isNull);
    expect(LensExceptionPauseMode.fromVmValue(null), isNull);
  });
}
