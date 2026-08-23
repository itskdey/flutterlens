import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

void main() {
  testWidgets('renders hierarchy and reports selection', (tester) async {
    LensWidget? selected;
    const scaffold = LensWidget(
      id: 'scaffold',
      name: 'Scaffold',
      hasChildren: true,
    );
    const column = LensWidget(
      id: 'column',
      name: 'Column',
      hasChildren: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LensTheme.dark(),
        home: Scaffold(
          body: LensWidgetTreeView(
            nodes: const [
              LensWidgetTreeItem(
                widget: scaffold,
                depth: 0,
                isExpanded: true,
                isLoading: false,
              ),
              LensWidgetTreeItem(
                widget: column,
                depth: 1,
                isExpanded: false,
                isLoading: false,
              ),
            ],
            onToggle: (_) {},
            onSelect: (widget) => selected = widget,
          ),
        ),
      ),
    );

    expect(find.text('Scaffold'), findsOneWidget);
    expect(find.text('Column'), findsOneWidget);

    await tester.tap(find.text('Column'));
    await tester.pump();

    expect(selected, column);
  });
}
