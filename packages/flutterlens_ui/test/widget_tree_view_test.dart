import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('supports keyboard selection and expansion', (tester) async {
    LensWidget? selected;
    LensWidget? toggled;
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
    const nodes = [
      LensWidgetTreeItem(
        widget: scaffold,
        depth: 0,
        isExpanded: false,
        isLoading: false,
      ),
      LensWidgetTreeItem(
        widget: column,
        depth: 1,
        isExpanded: false,
        isLoading: false,
      ),
    ];

    Future<void> pumpTree({String? selectedId}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LensTheme.dark(),
          home: Scaffold(
            body: LensWidgetTreeView(
              nodes: nodes,
              selectedId: selectedId,
              onToggle: (widget) => toggled = widget,
              onSelect: (widget) => selected = widget,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpTree();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selected, scaffold);

    await pumpTree(selectedId: 'scaffold');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(toggled, scaffold);
  });
}
