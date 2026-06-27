import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppLogStorage {
  static const _logFileName = 'jm_manga_app.log';
  static const _maxFileBytes = 1024 * 1024; // 1 MB
  static const _maxBackupCount = 3;

  File? _logFile;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/$_logFileName');
  }

  void append(String content) {
    final file = _logFile;
    if (file == null) return;
    try {
      _rotateIfNeeded(file);
      file.writeAsStringSync(content, mode: FileMode.append);
    } catch (_) {
      // 日志写入失败不应影响主流程。
    }
  }

  void clear() {
    try {
      _logFile?.writeAsStringSync('', mode: FileMode.write);
      _deleteBackupFiles(_logFile);
    } catch (_) {
      // ignore
    }
  }

  Future<String> export(String content) async {
    final tempDir = await getTemporaryDirectory();
    final outFile = File('${tempDir.path}/jm_manga_logs.txt');
    await outFile.writeAsString(content);
    return outFile.path;
  }

  void _rotateIfNeeded(File file) {
    if (!file.existsSync()) return;
    if (file.lengthSync() < _maxFileBytes) return;

    final base = file.path;

    // 删除最旧的备份。
    final oldest = File('$base.$_maxBackupCount');
    if (oldest.existsSync()) {
      oldest.deleteSync();
    }

    // 依次后移备份。
    for (var i = _maxBackupCount - 1; i >= 1; i--) {
      final current = File('$base.$i');
      if (current.existsSync()) {
        current.renameSync('$base.${i + 1}');
      }
    }

    // 当前日志移为 .1，然后创建新的当前日志文件。
    file.renameSync('$base.1');
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
