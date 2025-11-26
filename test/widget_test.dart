import 'package:flutter_test/flutter_test.dart';
import 'package:fin_trace/main.dart';

void main() {
  testWidgets('FinTrace app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FinTraceApp());

    expect(find.text('FinTrace'), findsOneWidget);
  });
}