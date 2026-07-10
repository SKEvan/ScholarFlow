import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_flow/main.dart';

void main() {
  testWidgets('ScholarFlowApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ScholarFlowApp());

    // Verify that the title 'ScholarFlow' is displayed
    expect(find.text('ScholarFlow'), findsOneWidget);
  });
}
