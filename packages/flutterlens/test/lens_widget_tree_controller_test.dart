import 'dart:async';

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
    await Future<void>.delayed(Duration.zero);
    expect(controller.selectedWidget, column);
    expect(source.deviceSelection, column);

    await controller.toggleNode(column);
    expect(controller.visibleNodes.map((item) => item.widget.name), [
      'Scaffold',
      'Column',
    ]);

    controller.dispose();
  });

  test('search loads lazy descendants and keeps matching ancestry', () async {
    final source = _FakeWidgetTreeSource();
    final controller = LensWidgetTreeController(source);

    await controller.refresh();
    await controller.setSearchQuery('text');

    expect(source.childrenRequests, ['root', 'column']);
    expect(controller.visibleNodes.map((item) => item.widget.name), [
      'Scaffold',
      'Column',
      'Text',
    ]);

    await controller.setSearchQuery('missing');
    expect(controller.visibleNodes, isEmpty);

    await controller.setSearchQuery('');
    controller.collapseAll();
    expect(
        controller.visibleNodes.map((item) => item.widget.name), ['Scaffold']);

    await controller.expandAll();
    expect(controller.visibleNodes.map((item) => item.widget.name), [
      'Scaffold',
      'Column',
      'Text',
    ]);

    controller.dispose();
  });

  test('syncs Inspector selection, toggles and source navigation', () async {
    final source = _FakeWidgetTreeSource();
    final controller = LensWidgetTreeController(source);

    await controller.refresh();
    await controller.expandAll();
    final text = controller.visibleNodes.last.widget;
    final column = controller.visibleNodes[1].widget;

    controller.selectWidget(text);
    await Future<void>.delayed(Duration.zero);
    expect(source.deviceSelection, text);

    source.deviceSelection = column;
    source.emitSelectionChanged();
    await Future<void>.delayed(Duration.zero);
    expect(controller.selectedWidget, column);

    expect(controller.selectModeEnabled, isFalse);
    await controller.toggleSelectMode();
    expect(controller.selectModeEnabled, isTrue);

    expect(controller.showImplementationWidgets, isFalse);
    await controller.setShowImplementationWidgets(true);
    expect(controller.showImplementationWidgets, isTrue);

    await controller.navigateToSource(text);
    expect(source.navigatedSource, text.sourceLocation);

    controller.dispose();
  });
}

class _FakeWidgetTreeSource extends LensWidgetTreeSource {
  static const root = LensWidget(
    id: 'root',
    name: 'Scaffold',
    hasChildren: true,
    sourceLocation: LensSourceLocation(file: '/app/lib/main.dart', line: 10),
  );
  static const column = LensWidget(
    id: 'column',
    name: 'Column',
    hasChildren: true,
    sourceLocation: LensSourceLocation(file: '/app/lib/main.dart', line: 20),
  );
  static const text = LensWidget(
    id: 'text',
    name: 'Text',
    hasChildren: false,
    sourceLocation: LensSourceLocation(file: '/app/lib/main.dart', line: 30),
  );

  final StreamController<void> _selectionChanges = StreamController.broadcast();
  int refreshCount = 0;
  final List<String> childrenRequests = [];
  LensWidget? deviceSelection;
  LensSourceLocation? navigatedSource;

  @override
  bool showImplementationWidgets = false;

  @override
  bool selectModeEnabled = false;

  @override
  Stream<void> get selectionChanges => _selectionChanges.stream;

  void emitSelectionChanged() => _selectionChanges.add(null);

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
  Future<LensWidget?> getSelectedWidget() async => deviceSelection;

  @override
  Future<void> setSelectedWidget(LensWidget widget) async {
    deviceSelection = widget;
  }

  @override
  Future<void> setShowImplementationWidgets(bool value) async {
    showImplementationWidgets = value;
  }

  @override
  Future<void> setSelectMode(bool enabled) async {
    selectModeEnabled = enabled;
  }

  @override
  Future<void> navigateToSource(LensSourceLocation source) async {
    navigatedSource = source;
  }

  @override
  Future<void> refresh() async {
    refreshCount++;
  }

  @override
  Future<void> dispose() async {
    await _selectionChanges.close();
  }
}
