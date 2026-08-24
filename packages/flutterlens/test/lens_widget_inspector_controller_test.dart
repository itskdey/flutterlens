import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens/src/application/lens_widget_inspector_controller.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

void main() {
  test('loads live inspection for selected widget', () async {
    final source = _FakeInspectorSource();
    final controller = LensWidgetInspectorController(source);

    await controller.inspect(_FakeInspectorSource.widget);

    expect(controller.selectedWidget, _FakeInspectorSource.widget);
    expect(controller.error, isNull);
    expect(controller.isLoading, isFalse);
    expect(controller.inspection?.properties.single.name, 'padding');
    expect(controller.inspection?.layout?.width, 200);

    controller.dispose();
  });

  test('clear removes selected inspection state', () async {
    final controller = LensWidgetInspectorController(_FakeInspectorSource());

    await controller.inspect(_FakeInspectorSource.widget);
    controller.clear();

    expect(controller.selectedWidget, isNull);
    expect(controller.inspection, isNull);
    expect(controller.error, isNull);
    expect(controller.isLoading, isFalse);

    controller.dispose();
  });
}

class _FakeInspectorSource implements LensWidgetInspectorSource {
  static const widget = LensWidget(
    id: 'container',
    name: 'Container',
    hasChildren: false,
  );

  @override
  Future<LensWidgetInspection> inspect(LensWidget widget) async {
    return LensWidgetInspection(
      widgetId: widget.id,
      properties: const [
        LensWidgetProperty(name: 'padding', value: 'EdgeInsets.all(16.0)'),
      ],
      layout: const LensLayoutInfo(width: 200, height: 80),
    );
  }

  @override
  Future<void> dispose() async {}
}
