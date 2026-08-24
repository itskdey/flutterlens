class LensBoxConstraints {
  const LensBoxConstraints({
    required this.minWidth,
    required this.maxWidth,
    required this.minHeight,
    required this.maxHeight,
  });

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  bool get hasBoundedWidth => maxWidth.isFinite;
  bool get hasBoundedHeight => maxHeight.isFinite;

  @override
  bool operator ==(Object other) {
    return other is LensBoxConstraints &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth &&
        other.minHeight == minHeight &&
        other.maxHeight == maxHeight;
  }

  @override
  int get hashCode => Object.hash(minWidth, maxWidth, minHeight, maxHeight);
}
