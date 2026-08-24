import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

import '../../application/lens_connection_controller.dart';
import '../../application/lens_widget_inspector_controller.dart';
import '../../application/lens_widget_tree_controller.dart';
import '../../devtools/devtools_connection_source.dart';
import '../../devtools/devtools_runtime_probe.dart';
import '../../devtools/devtools_widget_inspector_source.dart';
import '../../devtools/devtools_widget_tree_source.dart';

class FlutterLensApp extends StatefulWidget {
  const FlutterLensApp({super.key});

  @override
  State<FlutterLensApp> createState() => _FlutterLensAppState();
}

class _FlutterLensAppState extends State<FlutterLensApp> {
  late final LensConnectionController _connection;
  late final LensWidgetTreeController _tree;
  late final LensWidgetInspectorController _inspector;
  late final Listenable _workspace;
  late bool _wasConnected;
  String? _lastInspectedSelectionId;

  @override
  void initState() {
    super.initState();
    _connection = LensConnectionController(
      DevToolsConnectionSource(),
      DevToolsRuntimeProbe(),
    );
    _tree = LensWidgetTreeController(DevToolsWidgetTreeSource());
    _inspector = LensWidgetInspectorController(
      DevToolsWidgetInspectorSource(),
    );
    _workspace = Listenable.merge([_connection, _tree, _inspector]);
    _wasConnected = _connection.snapshot.isConnected;
    _connection.addListener(_handleConnectionChanged);
    _tree.addListener(_handleTreeChanged);
    if (_wasConnected) {
      unawaited(_tree.refresh());
    }
  }

  @override
  void dispose() {
    _connection.removeListener(_handleConnectionChanged);
    _tree.removeListener(_handleTreeChanged);
    _inspector.dispose();
    _tree.dispose();
    _connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterLens',
      debugShowCheckedModeBanner: false,
      theme: LensTheme.dark(),
      home: ListenableBuilder(
        listenable: _workspace,
        builder: (context, _) {
          final snapshot = _connection.snapshot;
          final runtimeInfo = _connection.runtimeInfo;
          return LensShell(
            connection: LensConnectionIndicator(snapshot: snapshot),
            onRefresh: snapshot.isConnected ? _refreshAll : null,
            refreshing: _connection.isLoadingRuntime ||
                _tree.isLoading ||
                _inspector.isLoading,
            treePanel: _Panel(
              eyebrow: 'WIDGET TREE',
              child: _buildTreePanel(snapshot),
            ),
            centerPanel: _Panel(
              eyebrow: 'RUNTIME',
              child: _buildRuntimePanel(snapshot, runtimeInfo),
            ),
            inspectorPanel: _Panel(
              eyebrow: 'INSPECTOR',
              child: _buildInspectorPanel(runtimeInfo),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshAll() async {
    _inspector.clear();
    _lastInspectedSelectionId = null;
    await Future.wait([
      _connection.refreshRuntime(),
      _tree.refresh(),
    ]);
  }

  void _handleConnectionChanged() {
    final connected = _connection.snapshot.isConnected;
    if (connected == _wasConnected) return;
    _wasConnected = connected;
    if (connected) {
      unawaited(_tree.refresh());
    } else {
      _lastInspectedSelectionId = null;
      _inspector.clear();
      _tree.clear();
    }
  }

  void _handleTreeChanged() {
    final selected = _tree.selectedWidget;
    final selectedId = selected?.id;
    if (selectedId == _lastInspectedSelectionId) return;
    _lastInspectedSelectionId = selectedId;
    if (selected == null) {
      _inspector.clear();
      return;
    }
    unawaited(_inspector.inspect(selected));
  }

  void _selectWidget(LensWidget widget) {
    _tree.selectWidget(widget);
  }

  Widget _buildTreePanel(LensConnectionSnapshot snapshot) {
    if (!snapshot.isConnected) {
      return const LensEmptyState(
        icon: Icons.account_tree_outlined,
        title: 'Waiting for Flutter application',
        description:
            'Connect a debug Flutter app to inspect its live widget tree.',
      );
    }
    final rows = _tree.visibleNodes;
    if (_tree.isLoading && !_tree.hasTree) {
      return const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    if (_tree.treeError case final error?) {
      return LensEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load widget tree',
        description: error.message,
      );
    }
    if (!_tree.hasTree) {
      return const LensEmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'Widget tree is not ready',
        description:
            'Render a Flutter frame, then refresh FlutterLens to query the Inspector again.',
      );
    }

    return Column(
      children: [
        _TreeTools(tree: _tree),
        const Divider(height: 1),
        Expanded(
          child: rows.isEmpty && _tree.searchQuery.isNotEmpty
              ? const LensEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching widgets',
                  description:
                      'Try a widget type, description, or source filename.',
                )
              : LensWidgetTreeView(
                  nodes: rows,
                  selectedId: _tree.selectedWidget?.id,
                  onToggle: _tree.toggleNode,
                  onSelect: _selectWidget,
                ),
        ),
      ],
    );
  }

  Widget _buildRuntimePanel(
    LensConnectionSnapshot snapshot,
    LensRuntimeInfo? runtimeInfo,
  ) {
    if (!snapshot.isConnected) {
      return LensEmptyState(
        icon: Icons.link_off_rounded,
        title: 'Waiting for Flutter application',
        description: snapshot.message ??
            'Run a Flutter app in debug mode and open FlutterLens from DevTools.',
      );
    }
    if (_connection.isLoadingRuntime && runtimeInfo == null) {
      return const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    if (_connection.runtimeError case final error?) {
      return LensEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Runtime probe failed',
        description: error.message,
      );
    }
    if (runtimeInfo != null) {
      return LensRuntimeOverview(info: runtimeInfo);
    }
    return const LensEmptyState(
      icon: Icons.hourglass_empty_rounded,
      title: 'Runtime information pending',
      description: 'Refresh to query the connected VM Service again.',
    );
  }

  Widget _buildInspectorPanel(LensRuntimeInfo? runtimeInfo) {
    final selected = _tree.selectedWidget;
    if (selected == null) {
      return LensEmptyState(
        icon: runtimeInfo?.inspectorAvailable == true
            ? Icons.touch_app_outlined
            : Icons.tune_rounded,
        title: runtimeInfo?.inspectorAvailable == true
            ? 'Select a widget'
            : 'Inspector unavailable',
        description: runtimeInfo?.inspectorAvailable == true
            ? 'Choose a node or use Select Widget Mode to inspect live layout, source, and properties.'
            : 'Connect a debug Flutter application with the Inspector service available.',
      );
    }

    if (_inspector.isLoading) {
      return const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    if (_inspector.error case final error?) {
      return LensEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not inspect widget',
        description: error.message,
      );
    }
    final inspection = _inspector.inspection;
    if (inspection != null && inspection.widgetId == selected.id) {
      return LensWidgetInspectorView(
        widget: selected,
        inspection: inspection,
        onOpenSource: selected.sourceLocation == null
            ? null
            : () => unawaited(_tree.navigateToSource(selected)),
      );
    }
    return const LensEmptyState(
      icon: Icons.hourglass_empty_rounded,
      title: 'Inspector data pending',
      description: 'FlutterLens is querying live Inspector data.',
    );
  }
}

class _TreeTools extends StatelessWidget {
  const _TreeTools({required this.tree});

  final LensWidgetTreeController tree;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: TextField(
              onChanged: (value) => unawaited(tree.setSearchQuery(value)),
              style: const TextStyle(
                color: LensColors.textPrimary,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                hintText: 'Search widgets…',
                hintStyle: const TextStyle(
                  color: LensColors.textMuted,
                  fontSize: 11,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 15),
                prefixIconConstraints: const BoxConstraints(minWidth: 34),
                suffixIcon: tree.isExpandingAll
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(strokeWidth: 1.2),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: LensColors.panelRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: LensColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: LensColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: LensColors.accent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _ToolButton(
                tooltip: tree.selectModeEnabled
                    ? 'Disable Select Widget Mode'
                    : 'Select a widget from the running app',
                active: tree.selectModeEnabled,
                icon: Icons.ads_click_rounded,
                onPressed: tree.toggleSelectMode,
              ),
              _ToolButton(
                tooltip: tree.showImplementationWidgets
                    ? 'Hide implementation widgets'
                    : 'Show framework and implementation widgets',
                active: tree.showImplementationWidgets,
                icon: Icons.code_rounded,
                onPressed: () => unawaited(
                  tree.setShowImplementationWidgets(
                    !tree.showImplementationWidgets,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(width: 1, height: 16, color: LensColors.border),
              const SizedBox(width: 4),
              _ToolButton(
                tooltip: 'Expand all loaded widgets',
                icon: Icons.unfold_more_rounded,
                onPressed: tree.isExpandingAll ? null : tree.expandAll,
              ),
              _ToolButton(
                tooltip: 'Collapse all widgets',
                icon: Icons.unfold_less_rounded,
                onPressed: tree.collapseAll,
              ),
              const Spacer(),
              const Tooltip(
                message: 'Keyboard: ↑ ↓ navigate · ← → collapse/expand',
                child: Icon(
                  Icons.keyboard_alt_outlined,
                  size: 15,
                  color: LensColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 30, height: 28),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 15,
          color: active ? LensColors.accent : LensColors.textSecondary,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.eyebrow, required this.child});

  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 38,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                eyebrow,
                style: const TextStyle(
                  color: LensColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}
