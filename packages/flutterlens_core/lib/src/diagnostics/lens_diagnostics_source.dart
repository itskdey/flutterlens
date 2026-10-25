import '../models/lens_diagnostic.dart';
import '../models/lens_source_location.dart';

abstract interface class LensDiagnosticsSource {
  Stream<LensDiagnostic> get events;

  Future<void> start();

  Future<void> navigateToSource(LensSourceLocation source);

  Future<void> dispose();
}
