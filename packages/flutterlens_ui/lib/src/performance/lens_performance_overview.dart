import 'package:flutter/material.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

import '../common/lens_empty_state.dart';
import '../theme/lens_colors.dart';

class LensPerformanceOverview extends StatelessWidget {
  const LensPerformanceOverview({
    required this.started,
    required this.starting,
    required this.rebuildTrackingEnabled,
    required this.repaintTrackingEnabled,
    required this.totalFrames,
    required this.jankyFrames,
    required this.jankRate,
    required this.averageBuildTime,
    required this.averageRasterTime,
    required this.hotspots,
    required this.onToggleRebuilds,
    required this.onToggleRepaints,
    required this.onClear,
    this.latestFrame,
    this.error,
    super.key,
  });

  final bool started;
  final bool starting;
  final bool rebuildTrackingEnabled;
  final bool repaintTrackingEnabled;
  final int totalFrames;
  final int jankyFrames;
  final double jankRate;
  final Duration averageBuildTime;
  final Duration averageRasterTime;
  final LensFrameMetric? latestFrame;
  final List<LensPerformanceHotspot> hotspots;
  final LensError? error;
  final ValueChanged<bool> onToggleRebuilds;
  final ValueChanged<bool> onToggleRepaints;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (starting && !started) {
      return const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }

    if (!started && error != null) {
      return LensEmptyState(
        icon: Icons.speed_rounded,
        title: 'Performance monitoring unavailable',
        description: error!.message,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      children: [
        _Header(
          started: started,
          rebuildTrackingEnabled: rebuildTrackingEnabled,
          repaintTrackingEnabled: repaintTrackingEnabled,
          onToggleRebuilds: onToggleRebuilds,
          onToggleRepaints: onToggleRepaints,
          onClear: onClear,
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          _InlineError(message: error!.message),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'FRAMES',
                    value: '$totalFrames',
                    detail: 'live session',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'JANK',
                    value: '${(jankRate * 100).toStringAsFixed(1)}%',
                    detail: '$jankyFrames over budget',
                    status: jankyFrames == 0
                        ? _MetricStatus.good
                        : _MetricStatus.warning,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'AVG UI',
                    value: _formatDuration(averageBuildTime),
                    detail: 'build time',
                    status: averageBuildTime > LensFrameMetric.targetFrameTime60Hz
                        ? _MetricStatus.bad
                        : _MetricStatus.neutral,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'AVG RASTER',
                    value: _formatDuration(averageRasterTime),
                    detail: 'raster time',
                    status:
                        averageRasterTime > LensFrameMetric.targetFrameTime60Hz
                            ? _MetricStatus.bad
                            : _MetricStatus.neutral,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        const _SectionLabel('LATEST FRAME'),
        const SizedBox(height: 7),
        if (latestFrame case final frame?)
          _LatestFrameCard(frame: frame)
        else
          const _WaitingCard(
            message: 'Interact with the running app to capture frame timing.',
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: _SectionLabel('ACTIVITY HOTSPOTS')),
            Text(
              '${hotspots.length}',
              style: const TextStyle(
                color: LensColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (hotspots.isEmpty)
          const _WaitingCard(
            message:
                'Rebuild activity will appear here with its source location.',
          )
        else
          for (final hotspot in hotspots.take(20))
            _HotspotRow(hotspot: hotspot),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '—';
    return '${(duration.inMicroseconds / 1000).toStringAsFixed(1)} ms';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.started,
    required this.rebuildTrackingEnabled,
    required this.repaintTrackingEnabled,
    required this.onToggleRebuilds,
    required this.onToggleRepaints,
    required this.onClear,
  });

  final bool started;
  final bool rebuildTrackingEnabled;
  final bool repaintTrackingEnabled;
  final ValueChanged<bool> onToggleRebuilds;
  final ValueChanged<bool> onToggleRepaints;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: started ? LensColors.success : LensColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              started ? 'Live performance session' : 'Performance session',
              style: const TextStyle(
                color: LensColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_sweep_outlined, size: 14),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: LensColors.textSecondary,
                textStyle: const TextStyle(fontSize: 10),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _TrackingChip(
              label: 'Rebuilds',
              enabled: rebuildTrackingEnabled,
              onChanged: onToggleRebuilds,
            ),
            _TrackingChip(
              label: 'Repaints',
              enabled: repaintTrackingEnabled,
              onChanged: onToggleRepaints,
            ),
            const _BudgetChip(),
          ],
        ),
      ],
    );
  }
}

class _TrackingChip extends StatelessWidget {
  const _TrackingChip({
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!enabled),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: enabled ? LensColors.accentMuted : LensColors.panelRaised,
          border: Border.all(
            color: enabled ? LensColors.accent : LensColors.border,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled ? Icons.check_rounded : Icons.add_rounded,
              size: 13,
              color: enabled ? LensColors.accent : LensColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: enabled
                    ? LensColors.textPrimary
                    : LensColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetChip extends StatelessWidget {
  const _BudgetChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        border: Border.all(color: LensColors.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Center(
        child: Text(
          '60 Hz · 16.7 ms budget',
          style: TextStyle(color: LensColors.textMuted, fontSize: 10),
        ),
      ),
    );
  }
}

enum _MetricStatus { neutral, good, warning, bad }

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    this.status = _MetricStatus.neutral,
  });

  final String label;
  final String value;
  final String detail;
  final _MetricStatus status;

  @override
  Widget build(BuildContext context) {
    final valueColor = switch (status) {
      _MetricStatus.good => LensColors.success,
      _MetricStatus.warning => LensColors.warning,
      _MetricStatus.bad => LensColors.error,
      _MetricStatus.neutral => LensColors.textPrimary,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LensColors.panelRaised,
        border: Border.all(color: LensColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LensColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(color: LensColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _LatestFrameCard extends StatelessWidget {
  const _LatestFrameCard({required this.frame});

  final LensFrameMetric frame;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: LensColors.panelRaised,
        border: Border.all(
          color: frame.isJanky ? LensColors.warning : LensColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Frame ${frame.frameNumber}',
                style: const TextStyle(
                  color: LensColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                frame.isJanky ? 'OVER BUDGET' : 'WITHIN BUDGET',
                style: TextStyle(
                  color: frame.isJanky ? LensColors.warning : LensColors.success,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FrameTimingRow(
            label: 'UI build',
            duration: frame.buildTime,
            overBudget: frame.isUiJanky,
          ),
          const SizedBox(height: 6),
          _FrameTimingRow(
            label: 'Raster',
            duration: frame.rasterTime,
            overBudget: frame.isRasterJanky,
          ),
          const SizedBox(height: 6),
          _FrameTimingRow(
            label: 'Elapsed',
            duration: frame.elapsedTime,
            overBudget: frame.elapsedTime > LensFrameMetric.targetFrameTime60Hz,
          ),
        ],
      ),
    );
  }
}

class _FrameTimingRow extends StatelessWidget {
  const _FrameTimingRow({
    required this.label,
    required this.duration,
    required this.overBudget,
  });

  final String label;
  final Duration duration;
  final bool overBudget;

  @override
  Widget build(BuildContext context) {
    final millis = duration.inMicroseconds / 1000;
    final fraction = (millis / 16.667).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(color: LensColors.textMuted, fontSize: 9),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: LensColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                overBudget ? LensColors.warning : LensColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            '${millis.toStringAsFixed(1)} ms',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: overBudget ? LensColors.warning : LensColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HotspotRow extends StatelessWidget {
  const _HotspotRow({required this.hotspot});

  final LensPerformanceHotspot hotspot;

  @override
  Widget build(BuildContext context) {
    final source = hotspot.sourceLocation;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: LensColors.panelRaised,
        border: Border.all(color: LensColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotspot.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LensColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  source == null
                      ? 'Source location pending'
                      : '${_shortFile(source.file)}:${source.line ?? 0}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LensColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          _CountBadge(label: 'B', count: hotspot.rebuildCount),
          const SizedBox(width: 5),
          _CountBadge(label: 'P', count: hotspot.repaintCount),
        ],
      ),
    );
  }

  static String _shortFile(String file) {
    final normalized = file.replaceAll('\\', '/');
    final segments = normalized.split('/');
    if (segments.length <= 2) return file;
    return segments.sublist(segments.length - 2).join('/');
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: LensColors.background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$label $count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: LensColors.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: LensColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: LensColors.textMuted,
          fontSize: 10,
          height: 1.4,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: LensColors.error.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 13, color: LensColors.error),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: LensColors.textSecondary, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: LensColors.textMuted,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
  }
}
