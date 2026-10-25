import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/devtools/diagnostics_event_mapper.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

void main() {
  const mapper = DiagnosticsEventMapper();
  final timestamp = DateTime.fromMillisecondsSinceEpoch(1720000000000);

  test('maps real Flutter.Error payload and preserves original details', () {
    const details =
        '══╡ ERROR ╞══\nRenderFlex overflowed by 12 pixels\n#0 stack';
    final diagnostic = mapper.fromFlutterError(
      {'renderedErrorText': details},
      id: 1,
      timestamp: timestamp,
      isolateId: 'isolates/1',
    );

    expect(diagnostic, isNotNull);
    expect(diagnostic!.kind, LensDiagnosticKind.frameworkError);
    expect(diagnostic.title, 'RenderFlex overflowed by 12 pixels');
    expect(diagnostic.details, details);
    expect(diagnostic.isolateId, 'isolates/1');
    expect(diagnostic.timestamp, timestamp);
  });

  test('ignores malformed or empty Flutter.Error payloads', () {
    for (final payload in [
      <String, dynamic>{},
      {'renderedErrorText': ''},
      {'renderedErrorText': 12},
    ]) {
      expect(
        mapper.fromFlutterError(payload, id: 1, timestamp: timestamp),
        isNull,
      );
    }
  });

  test('extracts source only from explicit Dart stack frame', () {
    final diagnostic = mapper.fromFlutterError({
      'renderedErrorText':
          'A failure happened\n#0 Widget.build (file:///tmp/lib/home.dart:42:7)'
    }, id: 4, timestamp: timestamp);

    expect(diagnostic!.sourceLocation?.display,
        'file:///tmp/lib/home.dart:42:7');
    expect(diagnostic.canNavigateToSource, isTrue);
    expect(diagnostic.report, contains('Source: file:///tmp/lib/home.dart:42:7'));
    expect(diagnostic.report, contains('Recorded:'));
  });

  test('package source is visible but cannot navigate as a file URI', () {
    final diagnostic = mapper.fromFlutterError({
      'renderedErrorText':
          'Bad state\n#0 Widget.build (package:app/home.dart:17:3)'
    }, id: 5, timestamp: timestamp);
    expect(diagnostic!.sourceLocation?.file, 'package:app/home.dart');
    expect(diagnostic.canNavigateToSource, isFalse);
  });

  test('does not guess source location from an ordinary exception', () {
    final diagnostic = mapper.fromFlutterError(
      {'renderedErrorText': 'StateError: no such item'},
      id: 6,
      timestamp: timestamp,
    );
    expect(diagnostic!.sourceLocation, isNull);
  });

  test('maps paused exception without inventing a stack trace', () {
    final diagnostic = mapper.fromPausedException(
      id: 2,
      timestamp: timestamp,
      description: 'StateError: failed',
    );

    expect(diagnostic.kind, LensDiagnosticKind.pausedException);
    expect(diagnostic.title, 'StateError: failed');
    expect(diagnostic.details, 'StateError: failed');
  });
}
