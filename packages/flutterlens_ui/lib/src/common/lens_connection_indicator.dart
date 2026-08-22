import 'package:flutter/material.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

import '../theme/lens_colors.dart';

class LensConnectionIndicator extends StatelessWidget {
  const LensConnectionIndicator({
    required this.snapshot,
    super.key,
  });

  final LensConnectionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final (dotColor, label) = switch (snapshot.status) {
      LensConnectionStatus.disconnected => (
          LensColors.textMuted,
          'Waiting for app',
        ),
      LensConnectionStatus.connecting => (LensColors.warning, 'Connecting'),
      LensConnectionStatus.connected => (LensColors.success, 'Connected'),
      LensConnectionStatus.error => (LensColors.error, 'Connection error'),
    };

    return Semantics(
      label: 'FlutterLens connection: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: LensColors.panelRaised,
          border: Border.all(color: LensColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: LensColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
