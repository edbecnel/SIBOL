import 'package:flutter_test/flutter_test.dart';

/// Avoid [WidgetTester.pumpAndSettle] after Firestore streams attach — it may never settle.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
  Duration step = const Duration(milliseconds: 500),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsOneWidget);
}
