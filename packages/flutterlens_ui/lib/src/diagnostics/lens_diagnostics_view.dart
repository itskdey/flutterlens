import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterlens_core/flutterlens_core.dart';

import '../theme/lens_colors.dart';

class LensDiagnosticsView extends StatelessWidget {
  const LensDiagnosticsView({
    required this.started,
    required this.starting,
    required this.totalEvents,
    required this.events,
    required this.selected,
    required this.query,
    required this.onSearch,
    required this.onSelect,
    required this.onClear,
    this.error,
    super.key,
  });

  final bool started;
  final bool starting;
  final int totalEvents;
  final List<LensDiagnostic> events;
  final LensDiagnostic? selected;
  final String query;
  final ValueChanged<String> onSearch;
  final ValueChanged<LensDiagnostic> onSelect;
  final VoidCallback onClear;
  final LensError? error;

  @override
  Widget build(BuildContext context) {
    if (starting && !started) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              const Icon(Icons.bug_report_outlined,
                  color: LensColors.error, size: 15),
              const SizedBox(width: 6),
              Text(
                '$totalEvents events',
                style: const TextStyle(
                  color: LensColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: totalEvents == 0 ? null : onClear,
                icon: const Icon(Icons.delete_sweep_outlined, size: 14),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: LensColors.textSecondary,
                  textStyle: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
          child: SizedBox(
            height: 34,
            child: TextField(
              onChanged: onSearch,
              controller: null,
              style: const TextStyle(
                color: LensColors.textPrimary,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                hintText: 'Search error messages…',
                hintStyle: const TextStyle(
                  color: LensColors.textMuted,
                  fontSize: 11,
                ),
                prefixIcon: const Icon(Icons.search, size: 15),
                prefixIconConstraints: const BoxConstraints(minWidth: 34),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: LensColors.panelRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              error!.message,
              style: const TextStyle(color: LensColors.error, fontSize: 11),
            ),
          ),
        if (!started && error == null)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Waiting for a connected Flutter runtime.',
              style: TextStyle(color: LensColors.textMuted, fontSize: 11),
            ),
          ),
        Expanded(
          flex: 2,
          child: events.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      totalEvents == 0
                          ? 'No runtime errors captured yet. New Flutter errors and paused exceptions appear here.'
                          : 'No errors match your search.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: LensColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final active = selected?.id == event.id;
                    return InkWell(
                      key: ValueKey('diagnostic-${event.id}'),
                      onTap: () => onSelect(event),
                      child: Container(
                        color: active ? LensColors.accentMuted : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              event.kind == LensDiagnosticKind.frameworkError
                                  ? Icons.error_outline_rounded
                                  : Icons.pause_circle_outline_rounded,
                              size: 15,
                              color: LensColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: LensColors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${event.kindLabel} · ${_time(event.timestamp)}',
                                    style: const TextStyle(
                                      color: LensColors.textMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 3,
          child: selected == null
              ? const Center(
                  child: Text(
                    'Select an event to inspect its details.',
                    style: TextStyle(
                      color: LensColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'EVENT DETAILS',
                              style: TextStyle(
                                color: LensColors.textMuted,
                                letterSpacing: 1,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy error details',
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: selected!.details),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                        child: SelectableText(
                          selected!.details,
                          style: const TextStyle(
                            color: LensColors.textSecondary,
                            fontSize: 10,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  static String _time(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
