import '../models/lens_diagnostic.dart';

abstract interface class LensDiagnosticsSource {
  Stream<LensDiagnostic> get events;

  Future<void> start();

  Future<void> dispose();
}
