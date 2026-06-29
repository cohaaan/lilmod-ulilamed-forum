import 'package:flutter_test/flutter_test.dart';
import 'package:lilmod_ulilamed/main.dart';

void main() {
  testWidgets('App renders home screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const LilmodUlilamedApp());
    await tester.pumpAndSettle();

    expect(find.text('Lilmod Ulilamed'), findsWidgets);
    expect(find.text('Recent discussions'), findsOneWidget);
  });
}
