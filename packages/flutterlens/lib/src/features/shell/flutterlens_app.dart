import 'package:flutter/material.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

import '../../application/lens_connection_controller.dart';
import '../../devtools/devtools_connection_source.dart';

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
    _connection = LensConnectionController(DevToolsConnectionSource());
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
          return LensShell(
            connection: LensConnectionIndicator(snapshot: snapshot),
            treePanel: const _Panel(
              eyebrow: 'WIDGET TREE',
              child: LensEmptyState(
                icon: Icons.account_tree_outlined,
                title: 'Widget tree arrives next',
                description:
                    'Phase 1 proves the DevTools connection before querying Flutter Inspector APIs.',
              ),
            ),
            centerPanel: _Panel(
              eyebrow: 'SELECTION',
              child: LensEmptyState(
                icon: snapshot.isConnected
                    ? Icons.check_circle_outline_rounded
                    : Icons.link_off_rounded,
                title: snapshot.isConnected
                    ? 'Runtime connection ready'
                    : 'Waiting for Flutter application',
                description: snapshot.message ??
                    'Run a Flutter app in debug mode and open FlutterLens from DevTools.',
              ),
            ),
            inspectorPanel: const _Panel(
              eyebrow: 'INSPECTOR',
              child: LensEmptyState(
                icon: Icons.tune_rounded,
                title: 'Nothing selected',
                description:
                    'Select a runtime widget after the live inspector adapter is added in Phase 2.',
              ),
            ),
          );
        },
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
