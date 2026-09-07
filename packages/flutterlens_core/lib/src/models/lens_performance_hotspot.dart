import 'lens_source_location.dart';

class LensPerformanceHotspot {
  const LensPerformanceHotspot({
    required this.name,
    required this.rebuildCount,
    required this.repaintCount,
    this.sourceLocation,
  });

  final String name;
  final LensSourceLocation? sourceLocation;
  final int rebuildCount;
  final int repaintCount;

  int get totalActivity => rebuildCount + repaintCount;
}
