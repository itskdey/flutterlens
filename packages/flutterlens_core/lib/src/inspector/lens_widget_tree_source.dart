import '../models/lens_widget.dart';

abstract interface class LensWidgetTreeSource {
  Future<LensWidget?> getRootWidget();

  Future<List<LensWidget>> getChildren(LensWidget widget);

  Future<void> refresh();

  Future<void> dispose();
}
