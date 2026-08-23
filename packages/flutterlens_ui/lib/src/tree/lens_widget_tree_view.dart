import 'package:flutter/material.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

import '../theme/lens_colors.dart';

class LensWidgetTreeView extends StatelessWidget {
  const LensWidgetTreeView({
    required this.nodes,
    required this.onToggle,
    required this.onSelect,
    this.selectedId,
    super.key,
  });

  final List<LensWidgetTreeItem> nodes;
  final String? selectedId;
  final ValueChanged<LensWidget> onToggle;
  final ValueChanged<LensWidget> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final item = nodes[index];
        return _TreeRow(
          item: item,
          selected: item.widget.id == selectedId,
          onToggle: () => onToggle(item.widget),
          onSelect: () => onSelect(item.widget),
        );
      },
    );
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.item,
    required this.selected,
    required this.onToggle,
    required this.onSelect,
  });

  final LensWidgetTreeItem item;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final widget = item.widget;
    final source = widget.sourceLocation;
    final sourceName = source?.file.split('/').last;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: selected ? LensColors.accentMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onSelect,
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                SizedBox(width: 8 + item.depth * 16.0),
                SizedBox(
                  width: 20,
                  child: widget.hasChildren
                      ? InkResponse(
                          radius: 14,
                          onTap: onToggle,
                          child: item.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.3,
                                  ),
                                )
                              : Icon(
                                  item.isExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_right_rounded,
                                  size: 16,
                                  color: LensColors.textSecondary,
                                ),
                        )
                      : null,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? LensColors.textPrimary
                                : LensColors.textSecondary,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.description case final description?) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: LensColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.errorMessage != null)
                  const Tooltip(
                    message: 'Could not load widget children',
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 13,
                      color: LensColors.error,
                    ),
                  ),
                if (source != null) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: source.display,
                    child: Text(
                      sourceName!,
                      style: const TextStyle(
                        color: LensColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
