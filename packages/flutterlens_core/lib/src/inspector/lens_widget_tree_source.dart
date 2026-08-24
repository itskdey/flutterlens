import '../models/lens_source_location.dart';
import '../models/lens_widget.dart';

abstract class LensWidgetTreeSource {
  Stream<void> get selectionChanges => const Stream<void>.empty();

  bool get showImplementationWidgets => false;

  bool get selectModeEnabled => false;

  Future<LensWidget?> getRootWidget();

  Future<List<LensWidget>> getChildren(LensWidget widget);

  Future<LensWidget?> getSelectedWidget() async => null;

  Future<void> setSelectedWidget(LensWidget widget) async {}

  Future<void> setShowImplementationWidgets(bool value) async {}

  Future<void> setSelectMode(bool enabled) async {}

  Future<void> navigateToSource(LensSourceLocation source) async {}

  Future<void> refresh();

  Future<void> dispose();
}
