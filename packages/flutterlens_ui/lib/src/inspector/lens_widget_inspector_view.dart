import 'package:flutter/material.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

import '../theme/lens_colors.dart';

class LensWidgetInspectorView extends StatelessWidget {
  const LensWidgetInspectorView({
    required this.widget,
    required this.inspection,
    super.key,
  });

  final LensWidget widget;
  final LensWidgetInspection inspection;

  @override
  Widget build(BuildContext context) {
    final layout = inspection.layout;
    final source = widget.sourceLocation;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        Text(
          widget.name,
          style: const TextStyle(
            color: LensColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.description case final description?) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: LensColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (layout != null) ...[
          const _SectionTitle('LAYOUT'),
          const SizedBox(height: 7),
          _LayoutCard(layout: layout),
          const SizedBox(height: 18),
        ],
        if (source != null) ...[
          const _SectionTitle('SOURCE'),
          const SizedBox(height: 7),
          _SourceCard(source: source),
          const SizedBox(height: 18),
        ],
        const _SectionTitle('PROPERTIES'),
        const SizedBox(height: 7),
        if (inspection.properties.isEmpty)
          const _MutedMessage('No diagnostic properties were reported.')
        else
          _PropertiesCard(properties: inspection.properties),
      ],
    );
  }
}

class _LayoutCard extends StatelessWidget {
  const _LayoutCard({required this.layout});

  final LensLayoutInfo layout;

  @override
  Widget build(BuildContext context) {
    final constraints = layout.constraints;
    return _Card(
      child: Column(
        children: [
          if (layout.hasSize)
            _DataRow(
              label: 'Size',
              value: '${_number(layout.width)} × ${_number(layout.height)}',
            ),
          if (constraints != null)
            _DataRow(
              label: 'Constraints',
              value:
                  'w ${_range(constraints.minWidth, constraints.maxWidth)}  ·  h ${_range(constraints.minHeight, constraints.maxHeight)}',
            ),
          if (layout.offsetX != null || layout.offsetY != null)
            _DataRow(
              label: 'Offset',
              value:
                  '${_number(layout.offsetX ?? 0)}, ${_number(layout.offsetY ?? 0)}',
            ),
          if (layout.flexFactor != null)
            _DataRow(label: 'Flex', value: '${layout.flexFactor}'),
          if (layout.flexFit != null)
            _DataRow(label: 'Fit', value: layout.flexFit!),
          if (layout.renderObject != null)
            _DataRow(label: 'Render', value: layout.renderObject!),
        ],
      ),
    );
  }

  static String _range(double min, double max) {
    return '${_number(min)}…${_number(max)}';
  }

  static String _number(double value) {
    if (value.isInfinite) return '∞';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final LensSourceLocation source;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _DataRow(label: 'File', value: source.file, selectable: true),
          if (source.line != null)
            _DataRow(label: 'Line', value: '${source.line}'),
          if (source.column != null)
            _DataRow(label: 'Column', value: '${source.column}'),
        ],
      ),
    );
  }
}

class _PropertiesCard extends StatelessWidget {
  const _PropertiesCard({required this.properties});

  final List<LensWidgetProperty> properties;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < properties.length; index++) ...[
            _PropertyRow(property: properties[index]),
            if (index != properties.length - 1)
              const Divider(height: 1, color: LensColors.border),
          ],
        ],
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.property});

  final LensWidgetProperty property;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 94,
            child: Text(
              property.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  property.value,
                  style: TextStyle(
                    color: property.hasException
                        ? LensColors.error
                        : property.isDefault
                            ? LensColors.textMuted
                            : LensColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
                if (property.type != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    property.type!,
                    style: const TextStyle(
                      color: LensColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final tooltip = property.tooltip;
    return tooltip == null || tooltip.isEmpty
        ? content
        : Tooltip(message: tooltip, child: content);
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: LensColors.textMuted,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: _valueStyle)
                : Text(value, style: _valueStyle),
          ),
        ],
      ),
    );
  }

  static const _valueStyle = TextStyle(
    color: LensColors.textPrimary,
    fontSize: 10,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: LensColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LensColors.panelRaised,
        border: Border.all(color: LensColors.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _MutedMessage extends StatelessWidget {
  const _MutedMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(color: LensColors.textMuted, fontSize: 10),
    );
  }
}
