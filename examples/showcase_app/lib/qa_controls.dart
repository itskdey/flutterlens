import 'dart:async';

import 'package:flutter/material.dart';

/// Deliberate, opt-in interactions for exercising FlutterLens against a live
/// Flutter VM Service session. This widget is used only by the showcase app.
class ShowcaseQaControls extends StatefulWidget {
  const ShowcaseQaControls({super.key});

  @override
  State<ShowcaseQaControls> createState() => _ShowcaseQaControlsState();
}

class _ShowcaseQaControlsState extends State<ShowcaseQaControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _rebuildCount = 0;
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _reportFrameworkError() {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('FlutterLens QA: expected framework error'),
        stack: StackTrace.current,
        library: 'flutterlens showcase',
        context: ErrorDescription('while exercising the Errors panel'),
      ),
    );
  }

  void _throwAsyncException() {
    // The user must explicitly request this test. The debugger may pause,
    // depending on its exception-pause setting; resume through DevTools.
    Timer.run(() {
      throw StateError('FlutterLens QA: expected uncaught async exception');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live inspector QA',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Opt-in rebuild, layout, repaint and diagnostic events.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text('Rebuild count: $_rebuildCount'),
            SwitchListTile.adaptive(
              key: const Key('qa_layout_switch'),
              title: const Text('Compact sample layout'),
              value: _compact,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _compact = value),
            ),
            AnimatedContainer(
              key: const Key('qa_layout_sample'),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              width: _compact ? 96 : 200,
              height: 54,
              decoration: BoxDecoration(
                color: _compact
                    ? const Color(0xFFFFD5BA)
                    : const Color(0xFFBBD9FF),
                borderRadius: BorderRadius.circular(_compact ? 14 : 8),
              ),
              alignment: Alignment.center,
              child: Text(_compact ? 'Compact' : 'Expanded'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => CustomPaint(
                  painter: _QaPulsePainter(_pulse.value),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  key: const Key('qa_rebuild_button'),
                  onPressed: () => setState(() => _rebuildCount++),
                  child: const Text('Rebuild sample'),
                ),
                OutlinedButton(
                  key: const Key('qa_paint_button'),
                  onPressed: () => unawaited(_pulse.forward(from: 0)),
                  child: const Text('Animate repaint'),
                ),
                OutlinedButton(
                  key: const Key('qa_framework_error_button'),
                  onPressed: _reportFrameworkError,
                  child: const Text('Report framework error'),
                ),
                TextButton(
                  key: const Key('qa_uncaught_button'),
                  onPressed: _throwAsyncException,
                  child: const Text('Throw uncaught async'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QaPulsePainter extends CustomPainter {
  const _QaPulsePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFE6EDF8),
    );
    canvas.drawCircle(
      Offset(12 + (size.width - 24) * progress, size.height / 2),
      9,
      Paint()..color = const Color(0xFF4B8DFF),
    );
  }

  @override
  bool shouldRepaint(covariant _QaPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
