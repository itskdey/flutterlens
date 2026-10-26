import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

void main() {
  testWidgets('compact layout keeps every workspace panel accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(340, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LensShell(
          connection: const Text('Connected'),
          treePanel: const Text('Tree panel content'),
          centerPanel: const Text('Performance panel content'),
          inspectorPanel: const Text('Inspector panel content'),
        ),
      ),
    );

    expect(find.text('Tree panel content'), findsOneWidget);
    await tester.tap(find.text('Workspace'));
    await tester.pump();
    expect(find.text('Performance panel content'), findsOneWidget);
    await tester.tap(find.text('Inspector'));
    await tester.pump();
    expect(find.text('Inspector panel content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
