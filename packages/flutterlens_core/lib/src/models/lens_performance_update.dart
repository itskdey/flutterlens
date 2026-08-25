import 'lens_frame_metric.dart';
import 'lens_performance_sample.dart';

class LensPerformanceUpdate {
  const LensPerformanceUpdate({
    this.frame,
    this.frameNumber,
    this.rebuilds = const [],
    this.repaints = const [],
  });

  final LensFrameMetric? frame;
  final int? frameNumber;
  final List<LensPerformanceSample> rebuilds;
  final List<LensPerformanceSample> repaints;
}
