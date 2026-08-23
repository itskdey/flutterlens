import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

class LensWidgetTreeController extends ChangeNotifier {
  LensWidgetTreeController(this._source);

  final LensWidgetTreeSource _source;
  final Map<String, _LensNodeState> _nodes = {};

  LensWidget? _root;
  LensWidget? _selectedWidget;
  LensError? _treeError;
  bool _isLoading = false;
  bool _disposed = false;
  int _generation = 0;

  LensWidget? get selectedWidget => _selectedWidget;
  LensError? get treeError => _treeError;
  bool get isLoading => _isLoading;
  bool get hasTree => _root != null;

  List<LensWidgetTreeItem> get visibleNodes {
    final root = _root;
    if (root == null) return const [];
    final rows = <LensWidgetTreeItem>[];
    _appendVisible(root.id, 0, rows);
    return rows;
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    _isLoading = true;
    _treeError = null;
    _selectedWidget = null;
    _root = null;
    _nodes.clear();
    notifyListeners();

    try {
      await _source.refresh();
      final root = await _source.getRootWidget();
      if (!_isCurrent(generation)) return;
      if (root == null) {
        return;
      }

      _root = root;
      final state = _LensNodeState(root)..isExpanded = root.hasChildren;
      _nodes[root.id] = state;
      if (root.hasChildren) {
        await _loadChildren(state, generation, notifyBeforeLoad: false);
      }
    } catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _treeError = LensError(
        code: 'widget_tree_load_failed',
        message: 'Could not load the live Flutter widget tree.',
        cause: error,
      );
      LensLogger.error(
        'Widget tree refresh failed.',
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

  Future<void> toggleNode(LensWidget widget) async {
    final state = _nodes[widget.id];
    if (state == null || !widget.hasChildren || _disposed) return;

    if (state.isExpanded) {
      state.isExpanded = false;
      notifyListeners();
      return;
    }

    state.isExpanded = true;
    state.errorMessage = null;
    if (state.childrenLoaded) {
      notifyListeners();
      return;
    }

    await _loadChildren(state, _generation);
  }

  void selectWidget(LensWidget widget) {
    if (_disposed || _selectedWidget?.id == widget.id) return;
    _selectedWidget = widget;
    notifyListeners();
  }

  void clear() {
    if (_disposed) return;
    _generation++;
    _root = null;
    _selectedWidget = null;
    _treeError = null;
    _isLoading = false;
    _nodes.clear();
    notifyListeners();
  }

  Future<void> _loadChildren(
    _LensNodeState state,
    int generation, {
    bool notifyBeforeLoad = true,
  }) async {
    state.isLoading = true;
    if (notifyBeforeLoad) notifyListeners();

    try {
      final children = await _source.getChildren(state.widget);
      if (!_isCurrent(generation)) return;
      state.childIds
        ..clear()
        ..addAll(children.map((child) => child.id));
      for (final child in children) {
        _nodes[child.id] = _LensNodeState(child);
      }
      state.childrenLoaded = true;
    } catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      state.errorMessage = 'Could not load children';
      LensLogger.warning(
        'Could not load children for ${state.widget.name}.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (_isCurrent(generation)) {
        state.isLoading = false;
        if (notifyBeforeLoad) notifyListeners();
      }
    }
  }

  void _appendVisible(
    String id,
    int depth,
    List<LensWidgetTreeItem> rows,
  ) {
    final state = _nodes[id];
    if (state == null) return;
    rows.add(
      LensWidgetTreeItem(
        widget: state.widget,
        depth: depth,
        isExpanded: state.isExpanded,
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
      ),
    );
    if (!state.isExpanded) return;
    for (final childId in state.childIds) {
      _appendVisible(childId, depth + 1, rows);
    }
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

class _LensNodeState {
  _LensNodeState(this.widget);

  final LensWidget widget;
  final List<String> childIds = [];
  bool isExpanded = false;
  bool isLoading = false;
  bool childrenLoaded = false;
  String? errorMessage;
}
