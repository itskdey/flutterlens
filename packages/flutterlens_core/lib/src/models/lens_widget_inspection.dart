import 'lens_layout_info.dart';
import 'lens_widget_property.dart';

class LensWidgetInspection {
  const LensWidgetInspection({
    required this.widgetId,
    required this.properties,
    this.layout,
  });

  final String widgetId;
  final List<LensWidgetProperty> properties;
  final LensLayoutInfo? layout;
}
