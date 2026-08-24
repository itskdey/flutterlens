import '../models/lens_widget.dart';
import '../models/lens_widget_inspection.dart';

abstract interface class LensWidgetInspectorSource {
  Future<LensWidgetInspection> inspect(LensWidget widget);

  Future<void> dispose();
}
