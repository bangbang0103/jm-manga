import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/screens/main_screen.dart';

import '../testable_app.dart';

void main() {
  group('BottomNavigationBar', () {
    Widget build() => testable(const MainScreen());

    testWidgets('renders four navigation tabs', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.items.length, 4);
    });

    testWidgets('initially selects the home tab', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });
  });
}
