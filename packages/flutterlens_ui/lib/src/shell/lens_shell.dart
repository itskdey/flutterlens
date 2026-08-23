import 'package:flutter/material.dart';

import '../theme/lens_colors.dart';

class LensShell extends StatelessWidget {
  const LensShell({
    required this.connection,
    required this.treePanel,
    required this.centerPanel,
    required this.inspectorPanel,
    this.onRefresh,
    this.refreshing = false,
    super.key,
  });

  final Widget connection;
  final Widget treePanel;
  final Widget centerPanel;
  final Widget inspectorPanel;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Toolbar(
            connection: connection,
            onRefresh: onRefresh,
            refreshing: refreshing,
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1050;
                return Row(
                  children: [
                    SizedBox(
                      width: compact ? 340 : 360,
                      child: treePanel,
                    ),
                    const VerticalDivider(width: 1),
                    if (!compact) ...[
                      Expanded(child: centerPanel),
                      const VerticalDivider(width: 1),
                    ],
                    SizedBox(
                      width: compact ? constraints.maxWidth - 341 : 360,
                      child: inspectorPanel,
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          const _StatusBar(),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.connection,
    required this.onRefresh,
    required this.refreshing,
  });

  final Widget connection;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: LensColors.accentMuted,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.center_focus_strong_rounded,
                size: 16,
                color: LensColors.accent,
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'FlutterLens',
              style: TextStyle(
                color: LensColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
            const Spacer(),
            connection,
            const SizedBox(width: 8),
            IconButton(
              onPressed: refreshing ? null : onRefresh,
              tooltip: 'Refresh runtime information',
              icon: refreshing
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
            ),
            IconButton(
              onPressed: null,
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined, size: 17),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 28,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              'Connection',
              style: TextStyle(color: LensColors.textSecondary, fontSize: 10),
            ),
            SizedBox(width: 18),
            Text(
              'Runtime',
              style: TextStyle(color: LensColors.textSecondary, fontSize: 10),
            ),
            SizedBox(width: 18),
            Text(
              'Errors',
              style: TextStyle(color: LensColors.textMuted, fontSize: 10),
            ),
            SizedBox(width: 18),
            Text(
              'Rebuilds',
              style: TextStyle(color: LensColors.textMuted, fontSize: 10),
            ),
            Spacer(),
            Text(
              'v0.1.0-dev',
              style: TextStyle(color: LensColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
