import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppLogStorage {
  static const _logFileName = 'jm_manga_app.log';
  static const _maxFileBytes = 1024 * 1024; // 1 MB
  static const _maxBackupCount = 3;

  /// 内存队列达到该条数后立即批量落盘。
  static const _flushThreshold = 50;

  /// 有未落盘日志时最长等待该间隔即批量落盘，避免日志长时间只留在内存。
  static const _flushInterval = Duration(seconds: 2);

  File? _logFile;
  final List<String> _pending = [];
  Timer? _flushTimer;
  Future<void>? _flushFuture;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/$_logFileName');
  }

  /// 仅写入内存队列，不做同步 IO。
  ///
  /// 达到 [_flushThreshold] 条或 [_flushInterval] 超时后批量写盘，
  /// 避免高频 debug 日志（如图片请求）逐条写文件阻塞 UI isolate。
  void append(String content) {
    if (_logFile == null) return;
    _pending.add(content);
    if (_pending.length >= _flushThreshold) {
      unawaited(flush());
    } else {
      _flushTimer ??= Timer(_flushInterval, () => unawaited(flush()));
    }
  }

  /// 将内存队列中的日志批量写入文件。
  ///
  /// 退出前或测试中可主动调用；多次调用会串行排队，不会并发写同一文件。
  Future<void> flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    // 串到上一次 flush 之后，保证阈值触发与手动 flush 不交错写入。
    final task = (_flushFuture ?? Future<void>.value()).then((_) => _drain());
    _flushFuture = task;
    return task;
  }

  Future<void> _drain() async {
    final file = _logFile;
    if (file == null || _pending.isEmpty) return;
    final batch = _pending.join();
    _pending.clear();
    try {
      await _rotateIfNeeded(file);
      await file.writeAsString(batch, mode: FileMode.append);
    } catch (_) {
      // 日志写入失败不应影响主流程。
    }
  }

  void clear() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pending.clear();
    // 排在进行中的批量写入之后清空文件，避免与在途 flush 乱序；
    // 之后的 flush 也会等清空完成。
    _flushFuture = flush().then((_) async {
      try {
        await _logFile?.writeAsString('', mode: FileMode.write);
        _deleteBackupFiles(_logFile);
      } catch (_) {
        // ignore
      }
    });
  }

  Future<String> export(String content) async {
    final tempDir = await getTemporaryDirectory();
    final outFile = File('${tempDir.path}/jm_manga_logs.txt');
    await outFile.writeAsString(content);
    return outFile.path;
  }

  Future<void> _rotateIfNeeded(File file) async {
    if (!await file.exists()) return;
    if (await file.length() < _maxFileBytes) return;

    final base = file.path;

    // 删除最旧的备份。
    final oldest = File('$base.$_maxBackupCount');
    if (await oldest.exists()) {
      await oldest.delete();
    }

    // 依次后移备份。
    for (var i = _maxBackupCount - 1; i >= 1; i--) {
      final current = File('$base.$i');
      if (await current.exists()) {
        await current.rename('$base.${i + 1}');
      }
    }

    // 当前日志移为 .1，然后创建新的当前日志文件。
    await file.rename('$base.1');
  }

  void _deleteBackupFiles(File? file) {
    if (file == null) return;
    final base = file.path;
    for (var i = 1; i <= _maxBackupCount; i++) {
      final backup = File('$base.$i');
      if (backup.existsSync()) {
        backup.deleteSync();
      }
    }
  }
}

AppLogStorage createPlatformAppLogStorage() => AppLogStorage();
