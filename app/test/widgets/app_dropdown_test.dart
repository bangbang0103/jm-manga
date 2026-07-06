import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/widgets/app_dropdown.dart';

void main() {
  group('AppDropdownMenu', () {
    Widget build(Widget child) {
      return MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );
    }

    testWidgets('renders the selected item and label', (tester) async {
      await tester.pumpWidget(
        build(
          AppDropdownMenu<String>(
            value: 'one',
            items: const ['one', 'two'],
            label: 'Sort',
            width: 240,
            labelFor: (value) => value == 'one' ? 'One' : 'Two',
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Sort'), findsWidgets);
      expect(find.text('One'), findsWidgets);
    });

    testWidgets('notifies selected value from the menu', (tester) async {
      String? selected;

      await tester.pumpWidget(
        build(
          AppDropdownMenu<String>(
            value: 'one',
            items: const ['one', 'two'],
            width: 240,
            labelFor: (value) => value == 'one' ? 'One' : 'Two',
            onSelected: (value) => selected = value,
          ),
        ),
      );

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Two').last);
      await tester.pumpAndSettle();

      expect(selected, 'two');
    });
  });
}
