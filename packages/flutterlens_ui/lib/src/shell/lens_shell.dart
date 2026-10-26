import 'package:flutter/material.dart';

import '../theme/lens_colors.dart';

class LensShell extends StatefulWidget {
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
  State<LensShell> createState() => _LensShellState();
}

enum _CompactPanel { tree, workspace, inspector }

class _LensShellState extends State<LensShell> {
  _CompactPanel _selected = _CompactPanel.tree;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Toolbar(
            connection: widget.connection,
            onRefresh: widget.onRefresh,
            refreshing: widget.refreshing,
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1250) {
                  return Column(
                    children: [
                      _CompactNavigation(
                        selected: _selected,
                        onSelected: (panel) =>
                            setState(() => _selected = panel),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: switch (_selected) {
                          _CompactPanel.tree => widget.treePanel,
                          _CompactPanel.workspace => widget.centerPanel,
                          _CompactPanel.inspector => widget.inspectorPanel,
                        },
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(width: 340, child: widget.treePanel),
                    const VerticalDivider(width: 1),
                    Expanded(child: widget.centerPanel),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 340, child: widget.inspectorPanel),
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

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({required this.selected, required this.onSelected});

  final _CompactPanel selected;
  final ValueChanged<_CompactPanel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          for (final panel in _CompactPanel.values)
            Expanded(
              child: TextButton(
                onPressed: () => onSelected(panel),
                style: TextButton.styleFrom(
                  foregroundColor: selected == panel
                      ? LensColors.accent
                      : LensColors.textSecondary,
                  backgroundColor: selected == panel
                      ? LensColors.accentMuted
                      : Colors.transparent,
                  shape: const RoundedRectangleBorder(),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: Text(switch (panel) {
                  _CompactPanel.tree => 'Tree',
                  _CompactPanel.workspace => 'Workspace',
                  _CompactPanel.inspector => 'Inspector',
                }),
              ),
            ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 460;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
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
              if (!narrow) ...[
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
              ],
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
              if (!narrow)
                IconButton(
                  onPressed: null,
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined, size: 17),
                ),
            ]),
          );
        },
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Text(
              'Connection',
              style: TextStyle(color: LensColors.textSecondary, fontSize: 10),
            ),
            if (!compact) ...[
              const SizedBox(width: 18),
              const Text(
                'Runtime',
                style: TextStyle(color: LensColors.textSecondary, fontSize: 10),
              ),
              const SizedBox(width: 18),
              const Text(
                'Errors',
                style: TextStyle(color: LensColors.textMuted, fontSize: 10),
              ),
              const SizedBox(width: 18),
              const Text(
                'Rebuilds',
                style: TextStyle(color: LensColors.textMuted, fontSize: 10),
              ),
            ],
            const Spacer(),
            const Text(
              'v0.1.0-dev',
              style: TextStyle(color: LensColors.textMuted, fontSize: 10),
            ),
          ]),
        );
      }),
    );
  }
}
