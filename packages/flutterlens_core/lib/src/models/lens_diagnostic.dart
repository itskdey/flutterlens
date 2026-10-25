enum LensDiagnosticKind { frameworkError, pausedException }

class LensDiagnostic {
  const LensDiagnostic({
    required this.id,
    required this.kind,
    required this.timestamp,
    required this.title,
    required this.details,
    this.isolateId,
  });

  final int id;
  final LensDiagnosticKind kind;
  final DateTime timestamp;
  final String title;
  final String details;
  final String? isolateId;

  String get kindLabel => switch (kind) {
        LensDiagnosticKind.frameworkError => 'Flutter error',
        LensDiagnosticKind.pausedException => 'Paused exception',
      };
}
