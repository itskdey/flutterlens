import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

void main() {
  testWidgets('renders selected widget layout, source, and properties', (
    tester,
  ) async {
    var openSourceCount = 0;
    const widget = LensWidget(
      id: 'widget-1',
      name: 'Container',
      description: 'Container(color: blue)',
      hasChildren: false,
      sourceLocation: LensSourceLocation(
        file: 'lib/features/home/home_screen.dart',
        line: 42,
        column: 9,
      ),
    );

    const inspection = LensWidgetInspection(
      widgetId: 'widget-1',
      layout: LensLayoutInfo(
        width: 320,
        height: 96,
        constraints: LensBoxConstraints(
          minWidth: 0,
          maxWidth: 390,
          minHeight: 0,
          maxHeight: 844,
        ),
        offsetX: 12,
        offsetY: 24,
        renderObject: 'RenderConstrainedBox',
      ),
      properties: [
        LensWidgetProperty(
          name: 'color',
          value: 'MaterialColor(primary value: Color(0xff2196f3))',
          type: 'DiagnosticsProperty<Color>',
        ),
        LensWidgetProperty(
          name: 'alignment',
          value: 'Alignment.center',
          isDefault: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LensTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 760,
            child: LensWidgetInspectorView(
              widget: widget,
              inspection: inspection,
              onOpenSource: () => openSourceCount++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Container'), findsOneWidget);
    expect(find.text('LAYOUT'), findsOneWidget);
    expect(find.text('320 × 96'), findsOneWidget);
    expect(find.text('SOURCE'), findsOneWidget);
    expect(find.text('lib/features/home/home_screen.dart'), findsOneWidget);
    expect(find.text('Open Source'), findsOneWidget);
    expect(find.text('PROPERTIES'), findsOneWidget);
    expect(find.text('color'), findsOneWidget);
    expect(find.text('alignment'), findsOneWidget);
    expect(find.text('RenderConstrainedBox'), findsOneWidget);

    await tester.tap(find.text('Open Source'));
    await tester.pump();
    expect(openSourceCount, 1);
  });
}
