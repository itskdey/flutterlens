import '../models/lens_performance_update.dart';

abstract interface class LensPerformanceSource {
  Stream<LensPerformanceUpdate> get updates;

  bool get rebuildTrackingEnabled;
  bool get repaintTrackingEnabled;

  Future<void> start();

  Future<void> setRebuildTracking(bool enabled);

  Future<void> setRepaintTracking(bool enabled);

  Future<void> dispose();
}
