import 'package:flutter/material.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

import '../theme/lens_colors.dart';

class LensRuntimeOverview extends StatelessWidget {
  const LensRuntimeOverview({required this.info, super.key});

  final LensRuntimeInfo info;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Runtime connection',
          style: TextStyle(
            color: LensColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Live metadata reported by the DevTools-managed VM Service connection.',
          style: TextStyle(
            color: LensColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        _ValueRow(label: 'Build mode', value: info.buildMode.label),
        if (info.flutterVersion case final version?)
          _ValueRow(label: 'Flutter', value: version),
        if (info.dartSdkVersion case final version?)
          _ValueRow(label: 'Dart SDK', value: version),
        if (info.operatingSystem case final operatingSystem?)
          _ValueRow(label: 'Platform', value: operatingSystem),
        if (info.vmName case final vmName?)
          _ValueRow(label: 'VM', value: vmName),
        if (info.mainIsolateName case final isolateName?)
          _ValueRow(label: 'Main isolate', value: isolateName),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),
        _CapabilityRow(
          label: 'VM Service',
          available: true,
          detail: 'Reachable',
        ),
        const SizedBox(height: 8),
        _CapabilityRow(
          label: 'Flutter Inspector',
          available: info.inspectorAvailable,
          detail: info.inspectorAvailable ? 'Reachable' : 'Unavailable',
        ),
        const SizedBox(height: 8),
        _CapabilityRow(
          label: 'Dart Tooling Daemon',
          available: info.dtdAvailable,
          detail: info.dtdAvailable ? 'Connected' : 'Not connected',
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: LensColors.textMuted,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LensColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.label,
    required this.available,
    required this.detail,
  });

  final String label;
  final bool available;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = available ? LensColors.success : LensColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: LensColors.panelRaised,
        border: Border.all(color: LensColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            available
                ? Icons.check_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: LensColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            detail,
            style: TextStyle(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
