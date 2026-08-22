import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens_core/flutterlens_core.dart';
import 'package:flutterlens_ui/flutterlens_ui.dart';

void main() {
  testWidgets('shows connected state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LensTheme.dark(),
        home: const Scaffold(
          body: LensConnectionIndicator(
            snapshot: LensConnectionSnapshot(
              status: LensConnectionStatus.connected,
              isFlutterApp: true,
              vmServiceAvailable: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Connected'), findsOneWidget);
  });
}
