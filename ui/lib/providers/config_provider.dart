import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jm_manga/l10n/app_localizations.dart';

import '../utils/secure_storage.dart';

class AppConfig {
  final String baseUrl;
  final String? apiToken;
  final ThemeMode themeMode;
  final int preloadCount;
  final Locale locale;
  final int gridColumns;

  const AppConfig({
    required this.baseUrl,
    this.apiToken,
    this.themeMode = ThemeMode.system,
    this.preloadCount = 5,
    this.locale = const Locale('en'),
    this.gridColumns = 3,
  });

  AppConfig copyWith({
    String? baseUrl,
    String? apiToken,
    ThemeMode? themeMode,
    int? preloadCount,
    Locale? locale,
    int? gridColumns,
  }) {
    return AppConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiToken: apiToken ?? this.apiToken,
      themeMode: themeMode ?? this.themeMode,
      preloadCount: preloadCount ?? this.preloadCount,
      locale: locale ?? this.locale,
      gridColumns: gridColumns ?? this.gridColumns,
    );
  }
}

class ConfigNotifier extends StateNotifier<AppConfig> {
  static const _baseUrlKey = 'baseUrl';
  static const _apiTokenKey = 'apiToken';
  static const _themeModeKey = 'themeMode';
  static const _preloadCountKey = 'preloadCount';
  static const _localeKey = 'locale';
  static const _gridColumnsKey = 'gridColumns';

  ConfigNotifier() : super(const AppConfig(baseUrl: 'http://127.0.0.1:8000')) {
    load();
  }

  static ThemeMode _parseThemeMode(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  static Locale _parseLocale(String? value) {
    return switch (value) {
      'zh' => const Locale('zh'),
      _ => const Locale('en'),
    };
  }

  static String _localeToString(Locale locale) {
    return switch (locale.languageCode) {
      'zh' => 'zh',
      _ => 'en',
    };
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_baseUrlKey);
    final preloadCount = prefs.getInt(_preloadCountKey);
    final themeMode = _parseThemeMode(prefs.getString(_themeModeKey));
    final locale = _parseLocale(prefs.getString(_localeKey));
    final gridColumns = prefs.getInt(_gridColumnsKey);

    final apiToken = await SecureStorage.read(_apiTokenKey);

    state = AppConfig(
      baseUrl: baseUrl ?? state.baseUrl,
      apiToken: apiToken,
      themeMode: themeMode,
      preloadCount: preloadCount ?? state.preloadCount,
      locale: locale,
      gridColumns: gridColumns == null
          ? state.gridColumns
          : gridColumns.clamp(2, 4),
    );
  }

  Future<void> setConnection(String baseUrl, String? token) async {
    final normalized = normalizeBaseUrl(baseUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
    await SecureStorage.write(_apiTokenKey, token);
    state = state.copyWith(baseUrl: normalized, apiToken: token);
  }

  Future<void> setPreloadCount(int count) async {
    final clamped = count.clamp(0, 20);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_preloadCountKey, clamped);
    state = state.copyWith(preloadCount: clamped);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, _localeToString(locale));
    state = state.copyWith(locale: locale);
  }

  Future<void> setGridColumns(int columns) async {
    final clamped = columns.clamp(2, 4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gridColumnsKey, clamped);
    state = state.copyWith(gridColumns: clamped);
  }

  static String normalizeBaseUrl(String url) {
    var normalized = url.trim();
    if (normalized.isEmpty) {
      return 'http://127.0.0.1:8000';
    }
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    normalized = normalized.replaceAll(RegExp(r'/+$'), '');
    return normalized;
  }

  static String? validateBaseUrl(String url, AppLocalizations l10n) {
    final normalized = normalizeBaseUrl(url);
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.host.contains(RegExp(r'[^a-zA-Z0-9.\-:_]'))) {
      return l10n.urlValidationError;
    }
    return null;
  }
}

final configProvider = StateNotifierProvider<ConfigNotifier, AppConfig>((ref) {
  return ConfigNotifier();
});
