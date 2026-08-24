class LensWidgetProperty {
  const LensWidgetProperty({
    required this.name,
    required this.value,
    this.type,
    this.level,
    this.tooltip,
    this.unit,
    this.isDefault = false,
    this.isDiagnosticable = false,
    this.hasException = false,
  });

  final String name;
  final String value;
  final String? type;
  final String? level;
  final String? tooltip;
  final String? unit;
  final bool isDefault;
  final bool isDiagnosticable;
  final bool hasException;

  @override
  bool operator ==(Object other) {
    return other is LensWidgetProperty &&
        other.name == name &&
        other.value == value &&
        other.type == type &&
        other.level == level &&
        other.tooltip == tooltip &&
        other.unit == unit &&
        other.isDefault == isDefault &&
        other.isDiagnosticable == isDiagnosticable &&
        other.hasException == hasException;
  }

  @override
  int get hashCode => Object.hash(
        name,
        value,
        type,
        level,
        tooltip,
        unit,
        isDefault,
        isDiagnosticable,
        hasException,
      );
}
