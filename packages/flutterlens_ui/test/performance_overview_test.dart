import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

void main() {
  testWidgets('renders live metrics and activity hotspots', (tester) async {
    var repaintEnabled = false;
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LensTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 900,
            child: LensPerformanceOverview(
              started: true,
              starting: false,
              rebuildTrackingEnabled: true,
              repaintTrackingEnabled: false,
              totalFrames: 42,
              jankyFrames: 2,
              jankRate: 2 / 42,
              averageBuildTime: const Duration(milliseconds: 8),
              averageRasterTime: const Duration(milliseconds: 6),
              latestFrame: const LensFrameMetric(
                frameNumber: 42,
                buildTime: Duration(milliseconds: 8),
                rasterTime: Duration(milliseconds: 6),
                elapsedTime: Duration(milliseconds: 12),
                vsyncOverhead: Duration(microseconds: 400),
              ),
              hotspots: const [
                LensPerformanceHotspot(
                  name: 'CounterCard',
                  rebuildCount: 12,
                  repaintCount: 3,
                  sourceLocation: LensSourceLocation(
                    file: 'lib/counter_card.dart',
                    line: 24,
                    column: 7,
                  ),
                ),
              ],
              onToggleRebuilds: (_) {},
              onToggleRepaints: (enabled) => repaintEnabled = enabled,
              onClear: () => cleared = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Live performance session'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(find.text('4.8%'), findsOneWidget);
    expect(find.text('Frame 42'), findsOneWidget);
    expect(find.text('CounterCard'), findsOneWidget);
    expect(find.text('counter_card.dart:24'), findsOneWidget);

    await tester.tap(find.text('Repaints'));
    expect(repaintEnabled, isTrue);

    await tester.tap(find.text('Clear'));
    expect(cleared, isTrue);
  });

  testWidgets('shows unavailable state when monitoring cannot start',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LensTheme.dark(),
        home: LensPerformanceOverview(
          started: false,
          starting: false,
          rebuildTrackingEnabled: false,
          repaintTrackingEnabled: false,
          totalFrames: 0,
          jankyFrames: 0,
          jankRate: 0,
          averageBuildTime: Duration.zero,
          averageRasterTime: Duration.zero,
          hotspots: const [],
          error: const LensError(
            code: 'performance_start_failed',
            message: 'Could not start Flutter performance monitoring.',
          ),
          onToggleRebuilds: _ignoreBool,
          onToggleRepaints: _ignoreBool,
          onClear: _ignore,
        ),
      ),
    );

    expect(find.text('Performance monitoring unavailable'), findsOneWidget);
    expect(
      find.text('Could not start Flutter performance monitoring.'),
      findsOneWidget,
    );
  });
}

void _ignoreBool(bool _) {}
void _ignore() {}
