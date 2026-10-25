import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/devtools/performance_event_mapper.dart';

void main() {
  test('maps Flutter.Frame payload into frame timing', () {
    final mapper = PerformanceEventMapper();

    final frame = mapper.frameFromJson({
      'number': 42,
      'build': 18000,
      'raster': 7000,
      'elapsed': 21000,
      'vsyncOverhead': 500,
    });

    expect(frame, isNotNull);
    expect(frame!.frameNumber, 42);
    expect(frame.buildTime, const Duration(microseconds: 18000));
    expect(frame.rasterTime, const Duration(microseconds: 7000));
    expect(frame.elapsedTime, const Duration(microseconds: 21000));
    expect(frame.vsyncOverhead, const Duration(microseconds: 500));
    expect(frame.isJanky, isTrue);
  });

  test('returns null for incomplete frame payloads', () {
    final mapper = PerformanceEventMapper();

    expect(
      mapper.frameFromJson({
        'number': 1,
        'build': 1000,
      }),
      isNull,
    );
  });

  test('maps rebuild and repaint ids to source locations', () {
    final mapper = PerformanceEventMapper();
    mapper.processLocations({
      'package:showcase/main.dart': {
        'ids': [7, 9],
        'lines': [20, 48],
        'columns': [5, 11],
        'names': ['HomeScreen', 'CounterCard'],
      },
    });

    expect(mapper.unresolvedIds([7, 3, 11, 2]), {11});

    final samples = mapper.samplesFromEvents([7, 3, 9, 4, 11, 2]);
    expect(samples, hasLength(3));
    expect(samples[0].name, 'HomeScreen');
    expect(samples[0].count, 3);
    expect(samples[0].sourceLocation?.file, 'package:showcase/main.dart');
    expect(samples[0].sourceLocation?.line, 20);
    expect(samples[1].name, 'CounterCard');
    expect(samples[1].count, 4);
    expect(samples[2].name, 'Location #11');
    expect(samples[2].sourceLocation, isNull);
  });

  test('resetLocations invalidates cached source ids', () {
    final mapper = PerformanceEventMapper();
    mapper.processLocations({
      'file:///tmp/main.dart': {
        'ids': [1],
        'lines': [2],
        'columns': [3],
        'names': ['App'],
      },
    });

    expect(mapper.unresolvedIds([1, 1]), isEmpty);
    mapper.resetLocations();
    expect(mapper.unresolvedIds([1, 1]), {1});
  });
}
