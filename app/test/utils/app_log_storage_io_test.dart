import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/utils/app_log_storage_io.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late File logFile;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('jm_log_storage_test_');
    logFile = File('${tempRoot.path}/jm_manga_app.log');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempRoot.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  Future<AppLogStorage> createStorage() async {
    final storage = AppLogStorage();
    await storage.init();
    return storage;
  }

  group('AppLogStorage', () {
    test('append 只入队不写盘，flush 后批量写入且保持顺序', () async {
      final storage = await createStorage();

      storage.append('first\n');
      storage.append('second\n');
      expect(await logFile.exists(), isFalse);

      await storage.flush();
      expect(await logFile.readAsString(), 'first\nsecond\n');
    });

    test('达到 50 条阈值时自动批量落盘', () async {
      final storage = await createStorage();

      for (var i = 1; i <= 50; i++) {
        storage.append('line $i\n');
      }
      // 等自动触发的 flush 完成。
      await storage.flush();

      final content = await logFile.readAsString();
      final expected = [for (var i = 1; i <= 50; i++) 'line $i\n'].join();
      expect(content, expected);
    });

    test('未到阈值时由定时器在 2 秒左右批量落盘', () async {
      final storage = await createStorage();

      storage.append('timer line\n');
      expect(await logFile.exists(), isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 2300));
      expect(await logFile.readAsString(), 'timer line\n');
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('flush 后可继续 append 并追加到同一文件', () async {
      final storage = await createStorage();

      storage.append('a\n');
      await storage.flush();
      storage.append('b\n');
      await storage.flush();

      expect(await logFile.readAsString(), 'a\nb\n');
    });

    test('clear 丢弃未落盘内容并清空文件', () async {
      final storage = await createStorage();

      storage.append('written\n');
      await storage.flush();
      storage.append('dropped\n');
      storage.clear();
      // clear 内部串行排队，随后的 flush 完成即代表清空完成。
      await storage.flush();

      expect(await logFile.readAsString(), isEmpty);
    });

    test('文件超过 1MB 时先轮转为 .1 再写入', () async {
      await logFile.writeAsBytes(List.filled(1024 * 1024 + 1, 0x61));
      final storage = await createStorage();

      storage.append('x\n');
      await storage.flush();

      final backup = File('${logFile.path}.1');
      expect(await backup.exists(), isTrue);
      expect(await backup.length(), 1024 * 1024 + 1);
      expect(await logFile.readAsString(), 'x\n');
    });

    test('未 init 时 append 与 flush 静默忽略', () async {
      final storage = AppLogStorage();
      storage.append('ignored\n');
      await storage.flush();
      expect(await logFile.exists(), isFalse);
    });
  });
}
