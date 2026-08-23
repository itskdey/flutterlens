import 'lens_box_constraints.dart';

class LensLayoutInfo {
  const LensLayoutInfo({
    this.width,
    this.height,
    this.constraints,
    this.offsetX,
    this.offsetY,
    this.renderObject,
    this.flexFactor,
    this.flexFit,
    this.isFlex = false,
  });

  final double? width;
  final double? height;
  final LensBoxConstraints? constraints;
  final double? offsetX;
  final double? offsetY;
  final String? renderObject;
  final int? flexFactor;
  final String? flexFit;
  final bool isFlex;

  bool get hasSize => width != null && height != null;

  @override
  bool operator ==(Object other) {
    return other is LensLayoutInfo &&
        other.width == width &&
        other.height == height &&
        other.constraints == constraints &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY &&
        other.renderObject == renderObject &&
        other.flexFactor == flexFactor &&
        other.flexFit == flexFit &&
        other.isFlex == isFlex;
  }

  @override
  int get hashCode => Object.hash(
        width,
        height,
        constraints,
        offsetX,
        offsetY,
        renderObject,
        flexFactor,
        flexFit,
        isFlex,
      );
}
