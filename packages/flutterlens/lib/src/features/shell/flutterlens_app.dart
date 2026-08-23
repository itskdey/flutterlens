import 'package:flutter/material.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

import '../../application/lens_connection_controller.dart';
import '../../devtools/devtools_connection_source.dart';
import '../../devtools/devtools_runtime_probe.dart';

class FlutterLensApp extends StatefulWidget {
  const FlutterLensApp({super.key});

  @override
  State<FlutterLensApp> createState() => _FlutterLensAppState();
}

class _FlutterLensAppState extends State<FlutterLensApp> {
  late final LensConnectionController _connection;

  @override
  void initState() {
    super.initState();
    _connection = LensConnectionController(
      DevToolsConnectionSource(),
      DevToolsRuntimeProbe(),
    );
  }

  @override
  void dispose() {
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
        listenable: _connection,
        builder: (context, _) {
          final snapshot = _connection.snapshot;
          final runtimeInfo = _connection.runtimeInfo;
          return LensShell(
            connection: LensConnectionIndicator(snapshot: snapshot),
            onRefresh: snapshot.isConnected ? _connection.refreshRuntime : null,
            refreshing: _connection.isLoadingRuntime,
            treePanel: const _Panel(
              eyebrow: 'WIDGET TREE',
              child: LensEmptyState(
                icon: Icons.account_tree_outlined,
                title: 'Live tree is Phase 3',
                description:
                    'Phase 2 verifies the VM Service and Flutter Inspector before requesting diagnostic nodes.',
              ),
            ),
            centerPanel: _Panel(
              eyebrow: 'RUNTIME',
              child: _buildRuntimePanel(snapshot, runtimeInfo),
            ),
            inspectorPanel: _Panel(
              eyebrow: 'INSPECTOR',
              child: LensEmptyState(
                icon: runtimeInfo?.inspectorAvailable == true
                    ? Icons.check_circle_outline_rounded
                    : Icons.tune_rounded,
                title: runtimeInfo?.inspectorAvailable == true
                    ? 'Inspector service reachable'
                    : 'Nothing selected',
                description: runtimeInfo?.inspectorAvailable == true
                    ? 'FlutterLens can call the live Flutter Inspector. Widget queries begin in Phase 3.'
                    : 'Connect a debug Flutter application to verify Inspector availability.',
              ),
            ),
          );
        },
      ),
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
}
