import 'lens_source_location.dart';

class LensWidget {
  const LensWidget({
    required this.id,
    required this.name,
    required this.hasChildren,
    this.description,
    this.sourceLocation,
  });

  final String id;
  final String name;
  final String? description;
  final LensSourceLocation? sourceLocation;
  final bool hasChildren;

  @override
  bool operator ==(Object other) {
    return other is LensWidget &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.sourceLocation == sourceLocation &&
        other.hasChildren == hasChildren;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        sourceLocation,
        hasChildren,
      );
}
