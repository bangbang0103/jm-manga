import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../utils/custom_domain_utils.dart';

/// 封面网格密度。列数由屏幕宽度决定，密度决定单格最大宽度。
enum GridDensity { compact, standard, loose }

extension GridDensityLayout on GridDensity {
  /// 封面网格单格最大宽度（逻辑像素）。
  /// 以 390dp 手机（网格可用宽度约 358）为参照：compact 约 3-4 列、
  /// standard 约 3 列（对齐旧版默认观感）、loose 约 2 列。
  double get maxCrossAxisExtent => switch (this) {
    GridDensity.compact => 100,
    GridDensity.standard => 150,
    GridDensity.loose => 240,
  };

  String get prefValue => switch (this) {
    GridDensity.compact => 'compact',
    GridDensity.standard => 'standard',
    GridDensity.loose => 'loose',
  };

  static GridDensity parse(String? value) => switch (value) {
    'compact' => GridDensity.compact,
    'loose' => GridDensity.loose,
    _ => GridDensity.standard,
  };

  /// 旧的「每行列数」设置（2–4）迁移映射：列数越少封面越大，
  /// 对应越宽松的密度（2 列 → loose，3 列 → standard，4 列 → compact）。
  static GridDensity fromLegacyColumns(int columns) => switch (columns) {
    2 => GridDensity.loose,
    4 => GridDensity.compact,
    _ => GridDensity.standard,
  };
}

/// 阅读器翻页模式：竖向滚动 / 点击翻页。
enum ReaderMode { scroll, paged }

extension ReaderModePref on ReaderMode {
  String get prefValue => switch (this) {
    ReaderMode.scroll => 'scroll',
    ReaderMode.paged => 'paged',
  };

  static ReaderMode parse(String? value) => switch (value) {
    'paged' => ReaderMode.paged,
    _ => ReaderMode.scroll,
  };
}

class AppConfig {
  final ThemeMode themeMode;
  final int preloadCount;
  final Locale locale;
  final GridDensity gridDensity;
  final ReaderMode readerMode;
  final bool autoSelectJmDomain;
  final String? proxyUrl;
  final LogLevel logLevel;
  final List<String> customApiDomains;
  final List<String> customImageDomains;

  const AppConfig({
    this.themeMode = ThemeMode.system,
    this.preloadCount = 5,
    this.locale = const Locale('en'),
    this.gridDensity = GridDensity.standard,
    this.readerMode = ReaderMode.scroll,
    this.autoSelectJmDomain = true,
    this.proxyUrl,
    this.logLevel = LogLevel.info,
    this.customApiDomains = const <String>[],
    this.customImageDomains = const <String>[],
  });

  AppConfig copyWith({
    ThemeMode? themeMode,
    int? preloadCount,
    Locale? locale,
    GridDensity? gridDensity,
    ReaderMode? readerMode,
    bool? autoSelectJmDomain,
    String? proxyUrl,
    LogLevel? logLevel,
    List<String>? customApiDomains,
    List<String>? customImageDomains,
    bool clearProxyUrl = false,
    bool clearCustomApiDomains = false,
    bool clearCustomImageDomains = false,
  }) {
    return AppConfig(
      themeMode: themeMode ?? this.themeMode,
      preloadCount: preloadCount ?? this.preloadCount,
      locale: locale ?? this.locale,
      gridDensity: gridDensity ?? this.gridDensity,
      readerMode: readerMode ?? this.readerMode,
      autoSelectJmDomain: autoSelectJmDomain ?? this.autoSelectJmDomain,
      proxyUrl: clearProxyUrl ? null : (proxyUrl ?? this.proxyUrl),
      logLevel: logLevel ?? this.logLevel,
      customApiDomains: clearCustomApiDomains
          ? const <String>[]
          : (customApiDomains ?? this.customApiDomains),
      customImageDomains: clearCustomImageDomains
          ? const <String>[]
          : (customImageDomains ?? this.customImageDomains),
    );
  }
}

class ConfigNotifier extends StateNotifier<AppConfig> {
  static const _themeModeKey = 'themeMode';
  static const _preloadCountKey = 'preloadCount';
  static const _localeKey = 'locale';
  static const _gridDensityKey = 'gridDensity';
  static const _legacyGridColumnsKey = 'gridColumns';
  static const _readerModeKey = 'readerMode';
  static const _autoSelectJmDomainKey = 'autoSelectJmDomain';
  static const _proxyUrlKey = 'proxyUrl';
  static const _logLevelKey = 'logLevel';
  static const _customApiDomainsKey = 'customApiDomains';
  static const _customImageDomainsKey = 'customImageDomains';

  ConfigNotifier() : super(const AppConfig()) {
    load();
  }

  static LogLevel _parseLogLevel(String? value) {
    return switch (value) {
      'info' => LogLevel.info,
      'warning' => LogLevel.warning,
      'error' => LogLevel.error,
      'debug' => LogLevel.debug,
      _ => kDebugMode ? LogLevel.debug : LogLevel.info,
    };
  }

  static String _logLevelToString(LogLevel level) {
    return switch (level) {
      LogLevel.debug => 'debug',
      LogLevel.info => 'info',
      LogLevel.warning => 'warning',
      LogLevel.error => 'error',
    };
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

  static List<String> _decodeStringList(String? value) {
    if (value == null || value.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded.whereType<String>().toList();
    } catch (_) {
      return const <String>[];
    }
  }

  static String _encodeStringList(List<String> list) {
    return jsonEncode(list);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final preloadCount = prefs.getInt(_preloadCountKey);
    final themeMode = _parseThemeMode(prefs.getString(_themeModeKey));
    final locale = _parseLocale(prefs.getString(_localeKey));
    // 旧的 gridColumns（int，2–4）一次性迁移为密度预设。
    final gridDensityPref = prefs.getString(_gridDensityKey);
    final legacyGridColumns = prefs.getInt(_legacyGridColumnsKey);
    final gridDensity = gridDensityPref != null
        ? GridDensityLayout.parse(gridDensityPref)
        : (legacyGridColumns == null
              ? state.gridDensity
              : GridDensityLayout.fromLegacyColumns(legacyGridColumns));
    final readerMode = ReaderModePref.parse(prefs.getString(_readerModeKey));
    final autoSelectJmDomain = prefs.getBool(_autoSelectJmDomainKey);
    final proxyUrl = prefs.getString(_proxyUrlKey);
    final logLevel = _parseLogLevel(prefs.getString(_logLevelKey));
    final customApiDomains = _decodeStringList(
      prefs.getString(_customApiDomainsKey),
    );
    final customImageDomains = _decodeStringList(
      prefs.getString(_customImageDomainsKey),
    );

    globalLogger.minLevel = logLevel;

    state = AppConfig(
      themeMode: themeMode,
      preloadCount: preloadCount ?? state.preloadCount,
      locale: locale,
      gridDensity: gridDensity,
      readerMode: readerMode,
      autoSelectJmDomain: autoSelectJmDomain ?? state.autoSelectJmDomain,
      proxyUrl: proxyUrl,
      logLevel: logLevel,
      customApiDomains: customApiDomains,
      customImageDomains: customImageDomains,
    );
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

  Future<void> setGridDensity(GridDensity density) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gridDensityKey, density.prefValue);
    // 迁移完成后清掉旧 key，避免下次启动重复映射。
    await prefs.remove(_legacyGridColumnsKey);
    state = state.copyWith(gridDensity: density);
  }

  Future<void> setReaderMode(ReaderMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readerModeKey, mode.prefValue);
    state = state.copyWith(readerMode: mode);
  }

  Future<void> setProxyUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = url?.trim();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(_proxyUrlKey);
      state = state.copyWith(clearProxyUrl: true);
      return;
    }
    await prefs.setString(_proxyUrlKey, normalized);
    state = state.copyWith(proxyUrl: normalized);
  }

  Future<void> setLogLevel(LogLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logLevelKey, _logLevelToString(level));
    globalLogger.minLevel = level;
    state = state.copyWith(logLevel: level);
  }

  Future<void> setCustomApiDomains(List<String> domains) async {
    final normalized = <String>[];
    for (final domain in domains) {
      final trimmed = domain.trim();
      if (trimmed.isEmpty) continue;
      final result = CustomDomainUtils.parse(trimmed);
      if (result.uri == null) {
        throw ArgumentError(result.error ?? 'Invalid domain: $trimmed');
      }
      normalized.add(result.uri.toString());
    }

    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(_customApiDomainsKey);
      state = state.copyWith(clearCustomApiDomains: true);
    } else {
      await prefs.setString(
        _customApiDomainsKey,
        _encodeStringList(normalized),
      );
      state = state.copyWith(customApiDomains: normalized);
    }
  }

  Future<void> setCustomImageDomains(List<String> domains) async {
    final normalized = <String>[];
    for (final domain in domains) {
      final trimmed = domain.trim();
      if (trimmed.isEmpty) continue;
      final result = CustomDomainUtils.parse(trimmed);
      if (result.uri == null) {
        throw ArgumentError(result.error ?? 'Invalid domain: $trimmed');
      }
      normalized.add(result.uri.toString());
    }

    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(_customImageDomainsKey);
      state = state.copyWith(clearCustomImageDomains: true);
    } else {
      await prefs.setString(
        _customImageDomainsKey,
        _encodeStringList(normalized),
      );
      state = state.copyWith(customImageDomains: normalized);
    }
  }
}

final configProvider = StateNotifierProvider<ConfigNotifier, AppConfig>((ref) {
  return ConfigNotifier();
});
