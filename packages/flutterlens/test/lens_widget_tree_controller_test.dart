import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/application/lens_widget_tree_controller.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

void main() {
  test('refresh loads root and first level then expands lazily', () async {
    final source = _FakeWidgetTreeSource();
    final controller = LensWidgetTreeController(source);

    await controller.refresh();

    expect(source.refreshCount, 1);
    expect(source.childrenRequests, ['root']);
    expect(controller.visibleNodes.map((item) => item.widget.name), [
      'Scaffold',
      'Column',
    ]);

    final column = controller.visibleNodes.last.widget;
    await controller.toggleNode(column);

    expect(source.childrenRequests, ['root', 'column']);
    expect(controller.visibleNodes.map((item) => item.widget.name), [
      'Scaffold',
      'Column',
      'Text',
    ]);

    controller.selectWidget(column);
    expect(controller.selectedWidget, column);

    await controller.toggleNode(column);
    expect(controller.visibleNodes.map((item) => item.widget.name), [
      'Scaffold',
      'Column',
    ]);

    controller.dispose();
  });
}

class _FakeWidgetTreeSource implements LensWidgetTreeSource {
  static const root = LensWidget(
    id: 'root',
    name: 'Scaffold',
    hasChildren: true,
  );
  static const column = LensWidget(
    id: 'column',
    name: 'Column',
    hasChildren: true,
  );
  static const text = LensWidget(
    id: 'text',
    name: 'Text',
    hasChildren: false,
  );

  int refreshCount = 0;
  final List<String> childrenRequests = [];

  @override
  Future<LensWidget?> getRootWidget() async => root;

  @override
  Future<List<LensWidget>> getChildren(LensWidget widget) async {
    childrenRequests.add(widget.id);
    return switch (widget.id) {
      'root' => const [column],
      'column' => const [text],
      _ => const [],
    };
  }

  @override
  Future<void> refresh() async {
    refreshCount++;
  }

  @override
  Future<void> dispose() async {}
}
