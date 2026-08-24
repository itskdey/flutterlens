import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

class LensWidgetTreeController extends ChangeNotifier {
  LensWidgetTreeController(this._source) {
    _selectionSubscription = _source.selectionChanges.listen((_) {
      unawaited(syncSelectionFromDevice());
    });
  }

  static const _maxExpandAllNodes = 2000;

  final LensWidgetTreeSource _source;
  final Map<String, _LensNodeState> _nodes = {};
  late final StreamSubscription<void> _selectionSubscription;

  LensWidget? _root;
  LensWidget? _selectedWidget;
  LensError? _treeError;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isExpandingAll = false;
  bool _disposed = false;
  int _generation = 0;

  LensWidget? get selectedWidget => _selectedWidget;
  LensError? get treeError => _treeError;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isExpandingAll => _isExpandingAll;
  bool get hasTree => _root != null;
  bool get showImplementationWidgets => _source.showImplementationWidgets;
  bool get selectModeEnabled => _source.selectModeEnabled;

  List<LensWidgetTreeItem> get visibleNodes {
    final root = _root;
    if (root == null) return const [];

    final rows = <LensWidgetTreeItem>[];
    if (_searchQuery.isEmpty) {
      _appendVisible(root.id, 0, rows);
      return rows;
    }

    final included = <String>{};
    for (final state in _nodes.values) {
      if (!_matchesSearch(state.widget)) continue;
      _includeAncestors(state, included);
    }
    _appendFiltered(root.id, 0, rows, included);
    return rows;
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final selectionPath = _selectionIdentityPath();
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
      if (root == null) return;

      _root = root;
      final state = _LensNodeState(root)..isExpanded = root.hasChildren;
      _nodes[root.id] = state;
      if (root.hasChildren) {
        await _loadChildren(state, generation, notifyBeforeLoad: false);
      }
      if (selectionPath.isNotEmpty) {
        await _restoreSelectionPath(selectionPath, generation);
      }
      if (_searchQuery.isNotEmpty) {
        await _expandAllInternal(generation);
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

  Future<void> setSearchQuery(String value) async {
    final query = value.trim().toLowerCase();
    if (_disposed || query == _searchQuery) return;
    _searchQuery = query;
    notifyListeners();
    if (query.isNotEmpty) {
      await expandAll();
    }
  }

  Future<void> expandAll() async {
    if (_disposed || _root == null || _isExpandingAll) return;
    _isExpandingAll = true;
    notifyListeners();
    try {
      await _expandAllInternal(_generation);
    } finally {
      if (!_disposed) {
        _isExpandingAll = false;
        notifyListeners();
      }
    }
  }

  void collapseAll() {
    if (_disposed) return;
    for (final state in _nodes.values) {
      state.isExpanded = false;
    }
    notifyListeners();
  }

  void selectWidget(LensWidget widget, {bool syncToDevice = true}) {
    if (_disposed || _selectedWidget?.id == widget.id) return;
    _selectedWidget = widget;
    notifyListeners();
    if (syncToDevice) {
      unawaited(_setDeviceSelection(widget));
    }
  }

  Future<void> syncSelectionFromDevice() async {
    if (_disposed || _isLoading || _root == null) return;
    try {
      final selected = await _source.getSelectedWidget();
      if (_disposed || selected == null) return;

      var state = _nodes[selected.id] ?? _findByIdentity(_WidgetIdentity(selected));
      if (state == null) {
        await expandAll();
        if (_disposed) return;
        state = _nodes[selected.id] ?? _findByIdentity(_WidgetIdentity(selected));
      }

      final widget = state?.widget ?? selected;
      if (_selectedWidget?.id == widget.id) return;
      _selectedWidget = widget;
      notifyListeners();
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not synchronize the Flutter Inspector selection.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setShowImplementationWidgets(bool value) async {
    if (_disposed || value == _source.showImplementationWidgets) return;
    final selectedIdentity = _selectedWidget == null
        ? null
        : _WidgetIdentity(_selectedWidget!);
    await _source.setShowImplementationWidgets(value);
    await refresh();

    if (!_disposed && _selectedWidget == null && selectedIdentity != null) {
      await expandAll();
      final match = _findByIdentity(selectedIdentity);
      if (match != null) {
        selectWidget(match.widget, syncToDevice: false);
      }
    }
  }

  Future<void> toggleSelectMode() async {
    if (_disposed) return;
    final next = !_source.selectModeEnabled;
    try {
      await _source.setSelectMode(next);
      if (!_disposed) notifyListeners();
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not toggle Flutter Inspector select mode.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> navigateToSource(LensWidget widget) async {
    final source = widget.sourceLocation;
    if (_disposed || source == null) return;
    try {
      await _source.navigateToSource(source);
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not open ${source.display} in the connected IDE.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void clear() {
    if (_disposed) return;
    _generation++;
    _root = null;
    _selectedWidget = null;
    _treeError = null;
    _isLoading = false;
    _isExpandingAll = false;
    _nodes.clear();
    notifyListeners();
  }

  Future<void> _setDeviceSelection(LensWidget widget) async {
    try {
      await _source.setSelectedWidget(widget);
    } catch (error, stackTrace) {
      LensLogger.warning(
        'Could not synchronize ${widget.name} with Flutter Inspector.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _expandAllInternal(int generation) async {
    final root = _root;
    if (root == null) return;
    final visited = <String>{};
    await _expandNode(root.id, generation, visited);
  }

  Future<void> _expandNode(
    String id,
    int generation,
    Set<String> visited,
  ) async {
    if (!_isCurrent(generation) ||
        visited.length >= _maxExpandAllNodes ||
        !visited.add(id)) {
      return;
    }
    final state = _nodes[id];
    if (state == null || !state.widget.hasChildren) return;

    state.isExpanded = true;
    if (!state.childrenLoaded) {
      await _loadChildren(state, generation, notifyBeforeLoad: false);
    }
    for (final childId in List<String>.of(state.childIds)) {
      await _expandNode(childId, generation, visited);
      if (visited.length >= _maxExpandAllNodes) break;
    }
  }

  Future<void> _restoreSelectionPath(
    List<_WidgetIdentity> path,
    int generation,
  ) async {
    final root = _root;
    if (root == null || path.isEmpty || !path.first.matches(root)) return;

    var current = _nodes[root.id];
    if (current == null) return;
    for (var index = 1; index < path.length; index++) {
      if (!current.widget.hasChildren) return;
      current.isExpanded = true;
      if (!current.childrenLoaded) {
        await _loadChildren(current, generation, notifyBeforeLoad: false);
      }
      if (!_isCurrent(generation)) return;

      _LensNodeState? match;
      for (final childId in current.childIds) {
        final child = _nodes[childId];
        if (child != null && path[index].matches(child.widget)) {
          match = child;
          break;
        }
      }
      if (match == null) return;
      current = match;
    }
    _selectedWidget = current.widget;
  }

  List<_WidgetIdentity> _selectionIdentityPath() {
    final selected = _selectedWidget;
    if (selected == null) return const [];
    var state = _nodes[selected.id];
    if (state == null) return [_WidgetIdentity(selected)];

    final path = <_WidgetIdentity>[];
    while (state != null) {
      path.add(_WidgetIdentity(state.widget));
      final parentId = state.parentId;
      state = parentId == null ? null : _nodes[parentId];
    }
    return path.reversed.toList(growable: false);
  }

  _LensNodeState? _findByIdentity(_WidgetIdentity identity) {
    for (final state in _nodes.values) {
      if (identity.matches(state.widget)) return state;
    }
    return null;
  }

  Future<void> _loadChildren(
    _LensNodeState state,
    int generation, {
    bool notifyBeforeLoad = true,
  }) async {
    state.isLoading = true;
    state.errorMessage = null;
    if (notifyBeforeLoad) notifyListeners();

    try {
      final children = await _source.getChildren(state.widget);
      if (!_isCurrent(generation)) return;
      state.childIds
        ..clear()
        ..addAll(children.map((child) => child.id));
      for (final child in children) {
        _nodes[child.id] = _LensNodeState(child, parentId: state.widget.id);
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

  void _includeAncestors(_LensNodeState state, Set<String> included) {
    _LensNodeState? current = state;
    while (current != null) {
      if (!included.add(current.widget.id)) break;
      final parentId = current.parentId;
      current = parentId == null ? null : _nodes[parentId];
    }
  }

  bool _matchesSearch(LensWidget widget) {
    final query = _searchQuery;
    if (query.isEmpty) return true;
    return widget.name.toLowerCase().contains(query) ||
        (widget.description?.toLowerCase().contains(query) ?? false) ||
        (widget.sourceLocation?.file.toLowerCase().contains(query) ?? false);
  }

  void _appendVisible(
    String id,
    int depth,
    List<LensWidgetTreeItem> rows,
  ) {
    final state = _nodes[id];
    if (state == null) return;
    rows.add(_treeItem(state, depth));
    if (!state.isExpanded) return;
    for (final childId in state.childIds) {
      _appendVisible(childId, depth + 1, rows);
    }
  }

  void _appendFiltered(
    String id,
    int depth,
    List<LensWidgetTreeItem> rows,
    Set<String> included,
  ) {
    final state = _nodes[id];
    if (state == null || !included.contains(id)) return;
    rows.add(_treeItem(state, depth));
    for (final childId in state.childIds) {
      _appendFiltered(childId, depth + 1, rows, included);
    }
  }

  LensWidgetTreeItem _treeItem(_LensNodeState state, int depth) {
    return LensWidgetTreeItem(
      widget: state.widget,
      depth: depth,
      isExpanded: state.isExpanded,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
    );
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_selectionSubscription.cancel());
    unawaited(_source.dispose());
    super.dispose();
  }
}

class _LensNodeState {
  _LensNodeState(this.widget, {this.parentId});

  final LensWidget widget;
  final String? parentId;
  final List<String> childIds = [];
  bool isExpanded = false;
  bool isLoading = false;
  bool childrenLoaded = false;
  String? errorMessage;
}

class _WidgetIdentity {
  const _WidgetIdentity(this.widget);

  final LensWidget widget;

  bool matches(LensWidget candidate) {
    final source = widget.sourceLocation;
    final candidateSource = candidate.sourceLocation;
    if (source != null && candidateSource != null) {
      return widget.name == candidate.name && source == candidateSource;
    }
    return widget.name == candidate.name &&
        widget.description == candidate.description;
  }
}
