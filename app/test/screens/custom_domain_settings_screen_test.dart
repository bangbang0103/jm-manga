import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/screens/custom_domain_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../testable_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CustomDomainSettingsScreen', () {
    testWidgets('renders empty state and allows adding a domain via dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const CustomDomainSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No custom domains. Add one below.'), findsWidgets);

      // Open the add dialog from the first section (API domains).
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, 'api.example.com');

      final dialogAddButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Add domain'),
      );
      await tester.tap(dialogAddButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('api.example.com'), findsOneWidget);
      expect(find.text('https'), findsOneWidget);
    });
  });
}
