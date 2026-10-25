import 'lens_source_location.dart';

enum LensDiagnosticKind { frameworkError, pausedException }

class LensDiagnostic {
  const LensDiagnostic({
    required this.id,
    required this.kind,
    required this.timestamp,
    required this.title,
    required this.details,
    this.isolateId,
    this.sourceLocation,
  });

  final int id;
  final LensDiagnosticKind kind;
  final DateTime timestamp;
  final String title;
  final String details;
  final String? isolateId;
  final LensSourceLocation? sourceLocation;

  String get kindLabel => switch (kind) {
        LensDiagnosticKind.frameworkError => 'Flutter error',
        LensDiagnosticKind.pausedException => 'Paused exception',
      };

  /// A stable, session-local grouping key; full details stay on each event.
  String get fingerprint =>
      '${kind.name}\u0000${title.trim().toLowerCase()}\u0000${sourceLocation?.display ?? ''}';

  String get report {
    final lines = <String>[
      'FlutterLens diagnostic report',
      'Type: $kindLabel',
      'Recorded: ${timestamp.toUtc().toIso8601String()}',
      if (isolateId != null) 'Isolate: $isolateId',
      if (sourceLocation != null) 'Source: ${sourceLocation!.display}',
      'Title: $title',
      '',
      details,
    ];
    return lines.join('\n');
  }

  /// VM ToolEvent navigation requires a local file URI, not package: paths.
  bool get canNavigateToSource {
    final path = sourceLocation?.file;
    return path != null &&
        (path.startsWith('/') ||
            path.startsWith('file:') ||
            RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path));
  }
}
