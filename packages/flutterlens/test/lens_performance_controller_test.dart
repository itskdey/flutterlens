import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/application/lens_performance_controller.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

void main() {
  test('aggregates frames, jank, and source hotspots', () async {
    final source = _FakePerformanceSource();
    final controller = LensPerformanceController(source);

    await controller.start();
    expect(controller.isStarted, isTrue);
    expect(source.startCalls, 1);

    source.emit(
      LensPerformanceUpdate(
        frame: const LensFrameMetric(
          frameNumber: 1,
          buildTime: Duration(milliseconds: 10),
          rasterTime: Duration(milliseconds: 8),
          elapsedTime: Duration(milliseconds: 12),
          vsyncOverhead: Duration(microseconds: 300),
        ),
        rebuilds: const [
          LensPerformanceSample(
            name: 'CounterCard',
            count: 3,
            sourceLocation: LensSourceLocation(
              file: 'lib/counter.dart',
              line: 12,
              column: 5,
            ),
          ),
        ],
      ),
    );
    source.emit(
      LensPerformanceUpdate(
        frame: const LensFrameMetric(
          frameNumber: 2,
          buildTime: Duration(milliseconds: 20),
          rasterTime: Duration(milliseconds: 5),
          elapsedTime: Duration(milliseconds: 22),
          vsyncOverhead: Duration(microseconds: 400),
        ),
        rebuilds: const [
          LensPerformanceSample(
            name: 'CounterCard',
            count: 2,
            sourceLocation: LensSourceLocation(
              file: 'lib/counter.dart',
              line: 12,
              column: 5,
            ),
          ),
        ],
        repaints: const [
          LensPerformanceSample(
            name: 'CounterCard',
            count: 4,
            sourceLocation: LensSourceLocation(
              file: 'lib/counter.dart',
              line: 12,
              column: 5,
            ),
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.totalFrames, 2);
    expect(controller.jankyFrames, 1);
    expect(controller.jankRate, 0.5);
    expect(controller.averageBuildTime, const Duration(milliseconds: 15));
    expect(controller.averageRasterTime, const Duration(microseconds: 6500));
    expect(controller.latestFrame?.frameNumber, 2);
    expect(controller.hotspots, hasLength(1));
    expect(controller.hotspots.single.rebuildCount, 5);
    expect(controller.hotspots.single.repaintCount, 4);
    expect(controller.hotspots.single.totalActivity, 9);

    controller.dispose();
  });

  test('tracking toggles delegate to source and clear resets metrics', () async {
    final source = _FakePerformanceSource();
    final controller = LensPerformanceController(source);

    await controller.start();
    await controller.setRebuildTracking(false);
    await controller.setRepaintTracking(true);

    expect(controller.rebuildTrackingEnabled, isFalse);
    expect(controller.repaintTrackingEnabled, isTrue);

    source.emit(
      const LensPerformanceUpdate(
        frame: LensFrameMetric(
          frameNumber: 9,
          buildTime: Duration(milliseconds: 4),
          rasterTime: Duration(milliseconds: 4),
          elapsedTime: Duration(milliseconds: 7),
          vsyncOverhead: Duration.zero,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.totalFrames, 1);

    controller.clear();
    expect(controller.totalFrames, 0);
    expect(controller.jankyFrames, 0);
    expect(controller.hotspots, isEmpty);
    expect(controller.latestFrame, isNull);

    controller.dispose();
  });

  test('can restart after disconnect without replacing subscription', () async {
    final source = _FakePerformanceSource();
    final controller = LensPerformanceController(source);

    await controller.start();
    controller.markDisconnected();
    expect(controller.isStarted, isFalse);

    await controller.start();
    expect(controller.isStarted, isTrue);
    expect(source.startCalls, 2);

    controller.dispose();
  });
}

class _FakePerformanceSource implements LensPerformanceSource {
  final _updates = StreamController<LensPerformanceUpdate>.broadcast();

  int startCalls = 0;
  bool _rebuildTrackingEnabled = true;
  bool _repaintTrackingEnabled = false;

  @override
  Stream<LensPerformanceUpdate> get updates => _updates.stream;

  @override
  bool get rebuildTrackingEnabled => _rebuildTrackingEnabled;

  @override
  bool get repaintTrackingEnabled => _repaintTrackingEnabled;

  @override
  Future<void> start() async {
    startCalls++;
  }

  @override
  Future<void> setRebuildTracking(bool enabled) async {
    _rebuildTrackingEnabled = enabled;
  }

  @override
  Future<void> setRepaintTracking(bool enabled) async {
    _repaintTrackingEnabled = enabled;
  }

  void emit(LensPerformanceUpdate update) => _updates.add(update);

  @override
  Future<void> dispose() => _updates.close();
}
