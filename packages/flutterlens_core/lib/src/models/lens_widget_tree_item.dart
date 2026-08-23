import 'lens_widget.dart';

class LensWidgetTreeItem {
  const LensWidgetTreeItem({
    required this.widget,
    required this.depth,
    required this.isExpanded,
    required this.isLoading,
    this.errorMessage,
  });

  final LensWidget widget;
  final int depth;
  final bool isExpanded;
  final bool isLoading;
  final String? errorMessage;
}
