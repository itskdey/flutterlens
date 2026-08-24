import 'package:flutterlens_core/flutterlens_core.dart';

class InspectorDiagnosticsMapper {
  const InspectorDiagnosticsMapper();

  LensWidget? fromJson(Map<String, Object?> json) {
    final valueId = _string(json['valueId']);
    final objectId = _string(json['objectId']);
    final id = valueId ?? objectId;
    if (id == null) return null;

    final runtimeType = _string(json['widgetRuntimeType']);
    final description = _string(json['description']);
    final diagnosticName = _string(json['name']);
    final name = runtimeType ?? diagnosticName ?? description ?? 'Widget';

    final rawChildren = json['children'];
    final hasChildren = rawChildren is List<Object?>
        ? rawChildren.isNotEmpty
        : json['hasChildren'] == true;

    return LensWidget(
      id: id,
      name: name,
      description: description == name ? null : description,
      sourceLocation: _sourceLocation(json['creationLocation']),
      // Flutter Inspector child queries use valueId. A diagnostic without a
      // valueId can still be displayed, but cannot be lazily expanded safely.
      hasChildren: hasChildren && valueId != null,
    );
  }

  List<LensWidget> listFromJson(Object? value) {
    if (value is! List<Object?>) return const [];

    final widgets = <LensWidget>[];
    for (final item in value) {
      if (item is! Map) continue;
      final widget = fromJson(item.cast<String, Object?>());
      if (widget != null) widgets.add(widget);
    }
    return widgets;
  }

  List<LensWidgetProperty> propertiesFromJson(Object? value) {
    if (value is! List<Object?>) return const [];

    final properties = <LensWidgetProperty>[];
    for (final item in value) {
      if (item is! Map) continue;
      final json = item.cast<String, Object?>();
      final name = _string(json['name']);
      final description = _string(json['description']);
      final exception = _string(json['exception']);
      if (name == null && description == null && exception == null) continue;

      properties.add(
        LensWidgetProperty(
          name: name ?? _string(json['propertyType']) ?? 'value',
          value: exception ?? description ?? 'null',
          type: _string(json['propertyType']) ?? _string(json['type']),
          level: _string(json['level']),
          tooltip: _string(json['tooltip']),
          unit: _string(json['unit']),
          isDefault: _string(json['level']) == 'fine',
          isDiagnosticable: json['isDiagnosticableValue'] == true,
          hasException: exception != null,
        ),
      );
    }
    return properties;
  }

  LensLayoutInfo? layoutFromJson(Object? value) {
    if (value is! Map) return null;
    final json = value.cast<String, Object?>();
    final size = _map(json['size']);
    final constraints = _map(json['constraints']);
    final parentData = _map(json['parentData']);
    final renderObject = _map(json['renderObject']);
    final runtimeType = _string(json['widgetRuntimeType']);

    final width = _double(size?['width']);
    final height = _double(size?['height']);
    final boxConstraints = constraints == null
        ? null
        : LensBoxConstraints(
            minWidth: _double(constraints['minWidth']) ?? 0,
            maxWidth: _double(constraints['maxWidth']) ?? double.infinity,
            minHeight: _double(constraints['minHeight']) ?? 0,
            maxHeight: _double(constraints['maxHeight']) ?? double.infinity,
          );

    if (width == null &&
        height == null &&
        boxConstraints == null &&
        renderObject == null) {
      return null;
    }

    return LensLayoutInfo(
      width: width,
      height: height,
      constraints: boxConstraints,
      offsetX: _double(parentData?['offsetX']),
      offsetY: _double(parentData?['offsetY']),
      renderObject: _string(renderObject?['description']) ??
          _string(renderObject?['widgetRuntimeType']),
      flexFactor: _int(json['flexFactor']),
      flexFit: _string(json['flexFit']),
      isFlex: runtimeType == 'Row' || runtimeType == 'Column' || runtimeType == 'Flex',
    );
  }

  LensSourceLocation? _sourceLocation(Object? value) {
    final json = _map(value);
    if (json == null) return null;
    final file = _string(json['file']);
    if (file == null) return null;
    return LensSourceLocation(
      file: file,
      line: _int(json['line']),
      column: _int(json['column']),
    );
  }

  Map<String, Object?>? _map(Object? value) {
    if (value is! Map) return null;
    return value.cast<String, Object?>();
  }

  String? _string(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _double(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
