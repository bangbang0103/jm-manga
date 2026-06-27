import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/screens/home_screen.dart';

import '../testable_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders app title and search icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('JM Manga'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
