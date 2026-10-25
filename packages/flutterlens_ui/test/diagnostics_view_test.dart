import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

void main() {
  testWidgets('renders errors, selects events, and reports search and clear',
      (tester) async {
    var searched = '';
    var cleared = false;
    var opened = false;
    LensDiagnosticKind? filter;
    LensDiagnostic? selected;
    final event = LensDiagnostic(
      id: 7,
      kind: LensDiagnosticKind.frameworkError,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1720000000000),
      title: 'RenderFlex overflow',
      details: 'RenderFlex overflow\n#0 main.dart:17',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LensTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 680,
            height: 850,
            child: LensDiagnosticsView(
              started: true,
              starting: false,
              totalEvents: 1,
              events: [event],
              selected: event,
              query: '',
              onSearch: (value) => searched = value,
              onSelect: (value) => selected = value,
              onClear: () => cleared = true,
              repeatCounts: const {7: 3},
              kindFilter: null,
              onKindFilterChanged: (value) => filter = value,
              onOpenSource: () => opened = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 events'), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);
    expect(find.text('/tmp/main.dart:17:2'), findsOneWidget);
    expect(find.byTooltip('Copy incident report'), findsOneWidget);
    await tester.tap(find.text('Open source'));
    expect(opened, isTrue);
    await tester.tap(find.byTooltip('Filter error type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paused exceptions').last);
    expect(filter, LensDiagnosticKind.pausedException);
    expect(find.text('RenderFlex overflow'), findsOneWidget);
    expect(find.textContaining('#0 main.dart:17'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'overflow');
    expect(searched, 'overflow');
    await tester.tap(find.byKey(const ValueKey('diagnostic-7')));
    expect(selected, event);
    await tester.tap(find.text('Clear'));
    expect(cleared, isTrue);
    expect(find.byTooltip('Copy error details'), findsOneWidget);
  });

  testWidgets('shows empty capture state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LensTheme.dark(),
        home: Scaffold(
          body: LensDiagnosticsView(
            started: true,
            starting: false,
            totalEvents: 0,
            events: const [],
            selected: null,
            query: '',
            onSearch: (_) {},
            onSelect: (_) {},
            onClear: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('No runtime errors captured'), findsOneWidget);
  });
}
