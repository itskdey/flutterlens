import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlens_showcase_app/main.dart';

void main() {
  testWidgets('renders showcase content', (tester) async {
    await tester.pumpWidget(const ShowcaseApp());

    expect(find.text('FlutterLens Showcase'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
  });
}
