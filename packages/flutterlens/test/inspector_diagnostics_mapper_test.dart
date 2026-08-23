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
}
