import 'package:flutterlens_core/flutterlens_core.dart';

class DiagnosticsEventMapper {
  const DiagnosticsEventMapper();

  LensDiagnostic? fromFlutterError(
    Map<String, dynamic> data, {
    required int id,
    required DateTime timestamp,
    String? isolateId,
  }) {
    final rendered = data['renderedErrorText'];
    if (rendered is! String || rendered.trim().isEmpty) return null;

    final details = rendered.trim();
    final summary = _firstMeaningfulLine(details);
    return LensDiagnostic(
      id: id,
      kind: LensDiagnosticKind.frameworkError,
      timestamp: timestamp,
      title: summary,
      details: details,
      isolateId: isolateId,
    );
  }

  LensDiagnostic fromPausedException({
    required int id,
    required DateTime timestamp,
    String? isolateId,
    String? description,
  }) {
    final message = description?.trim();
    final details = message == null || message.isEmpty
        ? 'The Dart VM paused on an exception.'
        : message;
    return LensDiagnostic(
      id: id,
      kind: LensDiagnosticKind.pausedException,
      timestamp: timestamp,
      title: _firstMeaningfulLine(details),
      details: details,
      isolateId: isolateId,
    );
  }

  String _firstMeaningfulLine(String text) {
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('══') || line.startsWith('──')) {
        continue;
      }
      // Keep a concise headline; the unmodified diagnostic stays in details.
      return line.length > 160 ? '${line.substring(0, 160)}…' : line;
    }
    return 'Flutter runtime error';
  }
}
