import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/widgets/error_placeholder.dart';

void main() {
  group('ErrorPlaceholder', () {
    Widget build(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    testWidgets('renders title, message and retry action', (tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        build(
          ErrorPlaceholder(
            title: 'Load failed',
            message: 'Network unavailable',
            retryLabel: 'Retry',
            onRetry: () => retryCount += 1,
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Load failed'), findsOneWidget);
      expect(find.text('Network unavailable'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryCount, 1);
    });

    testWidgets('hides retry action when no callback is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(
          const ErrorPlaceholder(
            message: 'Nothing to retry',
            retryLabel: 'Retry',
          ),
        ),
      );

      expect(find.text('Nothing to retry'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
