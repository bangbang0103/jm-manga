import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppLogStorage {
  static const _logFileName = 'jm_manga_app.log';

  File? _logFile;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/$_logFileName');
  }

  void append(String content) {
    final file = _logFile;
    if (file == null) return;
    try {
      file.writeAsStringSync(content, mode: FileMode.append);
    } catch (_) {
      // 日志写入失败不应影响主流程。
    }
  }

  void clear() {
    try {
      _logFile?.writeAsStringSync('', mode: FileMode.write);
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
}

AppLogStorage createPlatformAppLogStorage() => AppLogStorage();
