import 'package:flutterlens_core/flutterlens_core.dart';

class PerformanceEventMapper {
  final Map<int, _PerformanceLocation> _locations = {};

  void resetLocations() => _locations.clear();

  LensFrameMetric? frameFromJson(Map<String, dynamic> data) {
    final frameNumber = intValue(data['number']);
    final build = intValue(data['build']);
    final raster = intValue(data['raster']);
    final elapsed = intValue(data['elapsed']);
    final vsync = intValue(data['vsyncOverhead']);
    if (frameNumber == null ||
        build == null ||
        raster == null ||
        elapsed == null ||
        vsync == null) {
      return null;
    }
    return LensFrameMetric(
      frameNumber: frameNumber,
      buildTime: Duration(microseconds: build),
      rasterTime: Duration(microseconds: raster),
      elapsedTime: Duration(microseconds: elapsed),
      vsyncOverhead: Duration(microseconds: vsync),
    );
  }

  void processLocations(Object? rawLocations) {
    if (rawLocations is! Map) return;
    for (final entry in rawLocations.entries) {
      final file = entry.key.toString();
      final raw = entry.value;
      if (raw is! Map) continue;
      final ids = intList(raw['ids']);
      final lines = intList(raw['lines']);
      final columns = intList(raw['columns']);
      final names = stringList(raw['names']);
      final length = [ids.length, lines.length, columns.length, names.length]
          .reduce((a, b) => a < b ? a : b);
      for (var index = 0; index < length; index++) {
        _locations[ids[index]] = _PerformanceLocation(
          name: names[index],
          source: LensSourceLocation(
            file: file,
            line: lines[index],
            column: columns[index],
          ),
        );
      }
    }
  }

  Set<int> unresolvedIds(Object? rawEvents) {
    final events = intList(rawEvents);
    final unresolved = <int>{};
    for (var index = 0; index + 1 < events.length; index += 2) {
      final id = events[index];
      if (!_locations.containsKey(id)) unresolved.add(id);
    }
    return unresolved;
  }

  List<LensPerformanceSample> samplesFromEvents(Object? rawEvents) {
    final events = intList(rawEvents);
    final samples = <LensPerformanceSample>[];
    for (var index = 0; index + 1 < events.length; index += 2) {
      final id = events[index];
      final count = events[index + 1];
      final location = _locations[id];
      samples.add(
        LensPerformanceSample(
          name: location?.name ?? 'Location #$id',
          count: count,
          sourceLocation: location?.source,
        ),
      );
    }
    return samples;
  }

  List<int> intList(Object? value) {
    if (value is! List) return const [];
    return value.map(intValue).whereType<int>().toList(growable: false);
  }

  List<String> stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  int? intValue(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };
  }
}

class _PerformanceLocation {
  const _PerformanceLocation({required this.name, required this.source});

  final String name;
  final LensSourceLocation source;
}
