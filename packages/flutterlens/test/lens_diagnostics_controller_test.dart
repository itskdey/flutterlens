import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/application/lens_diagnostics_controller.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

void main() {
  test('records, filters, selects, and clears real events', () async {
    final source = _FakeDiagnosticsSource();
    final controller = LensDiagnosticsController(source);
    await controller.start();

    source.emit(_event(1, 'RenderFlex overflow'));
    source.emit(_event(2, 'Null check operator failed'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.isStarted, isTrue);
    expect(controller.totalEvents, 2);
    expect(controller.events.first.id, 2);
    controller.setQuery('renderflex');
    expect(controller.visibleEvents.single.id, 1);
    controller.select(controller.visibleEvents.single);
    expect(controller.selected?.id, 1);
    controller.clear();
    expect(controller.totalEvents, 0);
    expect(controller.selected, isNull);
    controller.dispose();
  });

  test('caps event memory and restores listener after disconnect', () async {
    final source = _FakeDiagnosticsSource();
    final controller = LensDiagnosticsController(source);
    await controller.start();

    for (var i = 0; i < LensDiagnosticsController.maxEvents + 5; i++) {
      source.emit(_event(i, 'Error $i'));
    }
    await Future<void>.delayed(Duration.zero);

    expect(controller.totalEvents, LensDiagnosticsController.maxEvents);
    expect(controller.events.last.id, 5);
    controller.markDisconnected();
    expect(controller.isStarted, isFalse);
    expect(controller.totalEvents, 0);
    await controller.start();
    expect(source.startCalls, 2);
    controller.dispose();
  });
  test('groups repeated reports and filters by category', () async {
    final source = _FakeDiagnosticsSource();
    final controller = LensDiagnosticsController(source);
    await controller.start();
    source.emit(_event(1, 'RenderFlex overflow'));
    source.emit(_event(2, 'RenderFlex overflow'));
    source.emit(_event(3, 'StateError'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.totalEvents, 3);
    expect(controller.visibleEvents, hasLength(2));
    final duplicate = controller.visibleEvents.last;
    expect(duplicate.id, 2);
    expect(controller.repeatCounts[2], 2);
    controller.setKindFilter(LensDiagnosticKind.pausedException);
    expect(controller.visibleEvents, isEmpty);
    controller.setKindFilter(LensDiagnosticKind.frameworkError);
    expect(controller.visibleEvents, hasLength(2));
    controller.dispose();
  });

  test('navigates to actual selected local source only', () async {
    final source = _FakeDiagnosticsSource();
    final controller = LensDiagnosticsController(source);
    await controller.start();
    source.emit(LensDiagnostic(
      id: 10,
      kind: LensDiagnosticKind.frameworkError,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1720000000000),
      title: 'Failed',
      details: 'Failed at /tmp/lib/main.dart:10:2',
      sourceLocation: const LensSourceLocation(
        file: '/tmp/lib/main.dart',
        line: 10,
        column: 2,
      ),
    ));
    await Future<void>.delayed(Duration.zero);

    await controller.openSelectedSource();
    expect(source.openedSource?.display, '/tmp/lib/main.dart:10:2');
    controller.dispose();
  });
}

LensDiagnostic _event(int id, String description) => LensDiagnostic(
      id: id,
      kind: LensDiagnosticKind.frameworkError,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1720000000000),
      title: description,
      details: '$description\n#0 stack',
    );

class _FakeDiagnosticsSource implements LensDiagnosticsSource {
  final StreamController<LensDiagnostic> _controller =
      StreamController<LensDiagnostic>.broadcast();

  int startCalls = 0;
  LensSourceLocation? openedSource;

  @override
  Stream<LensDiagnostic> get events => _controller.stream;

  @override
  Future<void> start() async {
    startCalls++;
  }

  void emit(LensDiagnostic event) => _controller.add(event);

  @override
  Future<void> navigateToSource(LensSourceLocation source) async {
    openedSource = source;
  }

  @override
  Future<void> dispose() => _controller.close();
}
