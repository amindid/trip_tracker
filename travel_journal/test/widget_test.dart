// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:travel_journal/main.dart';

void main() {
  testWidgets('Travel Journal app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TravelJournalApp());

    // Verify that our app loads and shows the bottom navigation.
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
  });
}
