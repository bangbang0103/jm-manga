import 'dart:async';
import 'dart:collection';

/// 简单的 Future 信号量，控制同时进行的图片下载数量，避免一次性
/// 发起几十张图片请求导致连接排队、乱序和超时。
///
/// 也作为图片缓存 evict 的串行化锁使用（容量 1），防止并发写入
/// 同时触发多次全目录扫描。
class JmImageSemaphore {
  final int _max;
  int _current = 0;
  final _queue = Queue<Completer<void>>();

  JmImageSemaphore(this._max);

  Future<void> acquire() async {
    if (_current < _max) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().complete();
    } else {
      _current--;
    }
  }
}
