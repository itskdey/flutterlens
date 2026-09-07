import 'lens_source_location.dart';

class LensPerformanceSample {
  const LensPerformanceSample({
    required this.name,
    required this.count,
    this.sourceLocation,
  });

  final String name;
  final int count;
  final LensSourceLocation? sourceLocation;

  String get identity =>
      '${sourceLocation?.file ?? ''}:${sourceLocation?.line ?? 0}:${sourceLocation?.column ?? 0}:$name';
}
