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

  LensSourceLocation? _sourceLocation(Object? value) {
    if (value is! Map) return null;
    final json = value.cast<String, Object?>();
    final file = _string(json['file']);
    if (file == null) return null;
    return LensSourceLocation(
      file: file,
      line: _int(json['line']),
      column: _int(json['column']),
    );
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
}
