import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens_showcase_app/main.dart';

void main() {
  testWidgets('renders the real-app QA fixtures', (tester) async {
    await tester.pumpWidget(const ShowcaseApp());

    expect(find.text('FlutterLens Showcase'), findsWidgets);
    expect(find.text('Live inspector QA'), findsOneWidget);
    expect(find.byKey(const Key('qa_layout_sample')), findsOneWidget);
  });

  testWidgets('rebuild action changes inspectable state', (tester) async {
    await tester.pumpWidget(const ShowcaseApp());

    final rebuild = find.byKey(const Key('qa_rebuild_button'));
    await tester.ensureVisible(rebuild);
    await tester.tap(rebuild);
    await tester.pump();

    expect(find.text('Rebuild count: 1'), findsOneWidget);
  });

  testWidgets('layout action changes the sample dimensions', (tester) async {
    await tester.pumpWidget(const ShowcaseApp());

    final toggle = find.byKey(const Key('qa_layout_switch'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('Compact'), findsOneWidget);
  });

  testWidgets('framework error action emits an expected report',
      (tester) async {
    final previousHandler = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.pumpWidget(const ShowcaseApp());

    final trigger = find.byKey(const Key('qa_framework_error_button'));
    await tester.ensureVisible(trigger);
    await tester.tap(trigger);
    await tester.pump();

    expect(errors, hasLength(1));
    expect(errors.single.exception.toString(),
        contains('FlutterLens QA: expected framework error'));
  });

  testWidgets('paint animation can complete', (tester) async {
    await tester.pumpWidget(const ShowcaseApp());

    final animate = find.byKey(const Key('qa_paint_button'));
    await tester.ensureVisible(animate);
    await tester.tap(animate);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
