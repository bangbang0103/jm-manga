import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('dark theme uses dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('dark theme color scheme has expected primary and surface', () {
      final theme = AppTheme.dark();
      expect(theme.colorScheme.primary, const Color(0xFFFFC485));
      expect(theme.colorScheme.surface, const Color(0xFF131314));
    });

    test('light theme uses light brightness', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('light theme surface is light', () {
      final theme = AppTheme.light();
      expect(theme.colorScheme.surface, const Color(0xFFFDFDFD));
    });
  });
}
