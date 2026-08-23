import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

class LensWidgetInspectorController extends ChangeNotifier {
  LensWidgetInspectorController(this._source);

  final LensWidgetInspectorSource _source;

  LensWidget? _selectedWidget;
  LensWidgetInspection? _inspection;
  LensError? _error;
  bool _isLoading = false;
  bool _disposed = false;
  int _generation = 0;

  LensWidget? get selectedWidget => _selectedWidget;
  LensWidgetInspection? get inspection => _inspection;
  LensError? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> inspect(LensWidget widget) async {
    if (_disposed) return;
    final generation = ++_generation;
    _selectedWidget = widget;
    _inspection = null;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final inspection = await _source.inspect(widget);
      if (!_isCurrent(generation)) return;
      _inspection = inspection;
    } catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _error = LensError(
        code: 'widget_inspection_failed',
        message: 'Could not inspect the selected Flutter widget.',
        cause: error,
      );
      LensLogger.error(
        'Widget inspection failed for ${widget.name}.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    final selected = _selectedWidget;
    if (selected == null) return;
    await inspect(selected);
  }

  void clear() {
    if (_disposed) return;
    _generation++;
    _selectedWidget = null;
    _inspection = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_source.dispose());
    super.dispose();
  }
}
