import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:jm_manga/router.dart';
import 'package:jm_manga/screens/server_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_repository.dart';

void main() {
  group('Router', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('initial route without server shows ServerSelectionScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiRepositoryProvider.overrideWithValue(FakeApiRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ServerSelectionScreen), findsOneWidget);
    });
  });
}
