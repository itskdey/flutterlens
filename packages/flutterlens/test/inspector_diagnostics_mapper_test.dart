import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/devtools/inspector_diagnostics_mapper.dart';

void main() {
  const mapper = InspectorDiagnosticsMapper();

  test('maps Flutter Inspector diagnostic JSON to LensWidget', () {
    final widget = mapper.fromJson({
      'valueId': 'inspector-1',
      'widgetRuntimeType': 'Container',
      'description': 'Container',
      'hasChildren': true,
      'creationLocation': {
        'file': 'lib/features/home/home_screen.dart',
        'line': 42,
        'column': 9,
      },
    });

    expect(widget, isNotNull);
    expect(widget!.id, 'inspector-1');
    expect(widget.name, 'Container');
    expect(widget.hasChildren, isTrue);
    expect(
      widget.sourceLocation?.display,
      'lib/features/home/home_screen.dart:42:9',
    );
  });

  test('embedded empty children override hasChildren', () {
    final widget = mapper.fromJson({
      'valueId': 'inspector-2',
      'widgetRuntimeType': 'Text',
      'hasChildren': true,
      'children': <Object?>[],
    });

    expect(widget?.hasChildren, isFalse);
  });

  test('maps diagnostic properties', () {
    final properties = mapper.propertiesFromJson([
      {
        'name': 'color',
        'description': 'Color(0xff54a8ff)',
        'propertyType': 'Color',
        'level': 'info',
        'tooltip': 'foreground color',
      },
      {
        'name': 'enabled',
        'description': 'true',
        'propertyType': 'bool',
        'level': 'fine',
      },
    ]);

    expect(properties, hasLength(2));
    expect(properties.first.name, 'color');
    expect(properties.first.type, 'Color');
    expect(properties.first.tooltip, 'foreground color');
    expect(properties.last.isDefault, isTrue);
  });

  test('maps layout explorer diagnostics', () {
    final layout = mapper.layoutFromJson({
      'widgetRuntimeType': 'Row',
      'size': {'width': '320.0', 'height': '56.0'},
      'constraints': {
        'minWidth': '0.0',
        'maxWidth': 'Infinity',
        'minHeight': '56.0',
        'maxHeight': '56.0',
      },
      'parentData': {'offsetX': '12.0', 'offsetY': '8.0'},
      'renderObject': {'description': 'RenderFlex#abc'},
      'flexFactor': 2,
      'flexFit': 'tight',
    });

    expect(layout, isNotNull);
    expect(layout!.width, 320);
    expect(layout.height, 56);
    expect(layout.constraints?.maxWidth, double.infinity);
    expect(layout.offsetX, 12);
    expect(layout.offsetY, 8);
    expect(layout.renderObject, 'RenderFlex#abc');
    expect(layout.flexFactor, 2);
    expect(layout.flexFit, 'tight');
    expect(layout.isFlex, isTrue);
  });
}
