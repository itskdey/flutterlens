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
    if (_wasConnected) {
      unawaited(_tree.refresh());
    }
  }

  @override
  void dispose() {
    _connection.removeListener(_handleConnectionChanged);
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
      _inspector.clear();
      _tree.clear();
    }
  }

  void _selectWidget(LensWidget widget) {
    _tree.selectWidget(widget);
    unawaited(_inspector.inspect(widget));
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
    if (_tree.isLoading && rows.isEmpty) {
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
    if (rows.isEmpty) {
      return const LensEmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'Widget tree is not ready',
        description:
            'Render a Flutter frame, then refresh FlutterLens to query the Inspector again.',
      );
    }
    return LensWidgetTreeView(
      nodes: rows,
      selectedId: _tree.selectedWidget?.id,
      onToggle: _tree.toggleNode,
      onSelect: _selectWidget,
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
            ? 'Choose a node to inspect its layout, source, and diagnostic properties.'
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
      );
    }
    return const LensEmptyState(
      icon: Icons.hourglass_empty_rounded,
      title: 'Inspector data pending',
      description: 'Select the widget again to query live Inspector data.',
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
