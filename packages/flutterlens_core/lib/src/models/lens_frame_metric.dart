class LensFrameMetric {
  const LensFrameMetric({
    required this.frameNumber,
    required this.buildTime,
    required this.rasterTime,
    required this.elapsedTime,
    required this.vsyncOverhead,
  });

  static const targetFrameTime60Hz = Duration(microseconds: 16667);

  final int frameNumber;
  final Duration buildTime;
  final Duration rasterTime;
  final Duration elapsedTime;
  final Duration vsyncOverhead;

  bool get isUiJanky => buildTime > targetFrameTime60Hz;
  bool get isRasterJanky => rasterTime > targetFrameTime60Hz;
  bool get isJanky => isUiJanky || isRasterJanky;

  @override
  bool operator ==(Object other) {
    return other is LensFrameMetric &&
        other.frameNumber == frameNumber &&
        other.buildTime == buildTime &&
        other.rasterTime == rasterTime &&
        other.elapsedTime == elapsedTime &&
        other.vsyncOverhead == vsyncOverhead;
  }

  @override
  int get hashCode => Object.hash(
        frameNumber,
        buildTime,
        rasterTime,
        elapsedTime,
        vsyncOverhead,
      );
}
