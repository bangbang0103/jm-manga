import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'app_log_storage.dart';

enum LogLevel {
  debug('D', 'DEBUG'),
  info('I', 'INFO'),
  warning('W', 'WARN'),
  error('E', 'ERROR');

  final String short;
  final String label;

  const LogLevel(this.short, this.label);
}

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String get formattedTime {
    final t = time;
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '${t.year.toString().padLeft(4, '0')}-'
        '${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.$ms';
  }
}

/// 客户端日志记录器。
///
/// 日志会同时写入内存（最多保留 500 条）和本地文件，方便在页面上查看和导出。
class AppLogger extends ChangeNotifier {
  static const _maxInMemory = 500;

  final List<LogEntry> _entries = [];
  final _storage = createAppLogStorage();
  bool _initialized = false;
  LogLevel minLevel = kReleaseMode ? LogLevel.warning : LogLevel.debug;

  List<LogEntry> get entries => List.unmodifiable(_entries);

  Future<void> init() async {
    if (_initialized) return;
    await _storage.init();
    _initialized = true;
  }

  void _write(LogEntry entry) {
    final buffer = StringBuffer()
      ..write('[${entry.formattedTime}] ')
      ..write('[${entry.level.label}] ')
      ..writeln(entry.message);
    if (entry.error != null) {
      buffer.writeln('ERROR_OBJECT: ${entry.error}');
    }
    if (entry.stackTrace != null) {
      buffer.writeln(entry.stackTrace);
    }
    _storage.append(buffer.toString());
  }

  void _emit(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;

    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    _entries.add(entry);
    if (_entries.length > _maxInMemory) {
      _entries.removeAt(0);
    }
    _write(entry);
    developer.log(
      message,
      name: 'JM Manga',
      error: error,
      stackTrace: stackTrace,
    );
    notifyListeners();
  }

  void d(String message, {Object? error, StackTrace? stackTrace}) =>
      _emit(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  void i(String message, {Object? error, StackTrace? stackTrace}) =>
      _emit(LogLevel.info, message, error: error, stackTrace: stackTrace);

  void w(String message, {Object? error, StackTrace? stackTrace}) =>
      _emit(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _emit(LogLevel.error, message, error: error, stackTrace: stackTrace);

  void clear() {
    _entries.clear();
    _storage.clear();
    notifyListeners();
  }

  /// 将当前内存中的日志导出到临时文件并返回路径。
  Future<String> exportToTempFile() async {
    final buffer = StringBuffer();
    for (final entry in _entries) {
      buffer.write('[${entry.formattedTime}] ');
      buffer.write('[${entry.level.label}] ');
      buffer.writeln(entry.message);
      if (entry.error != null) buffer.writeln('ERROR_OBJECT: ${entry.error}');
      if (entry.stackTrace != null) buffer.writeln(entry.stackTrace);
    }
    return _storage.export(buffer.toString());
  }
}

/// 全局日志记录器，方便在不需要 BuildContext 的地方调用。
final globalLogger = AppLogger();
