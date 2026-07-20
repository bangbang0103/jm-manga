import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 永远不完成加载的 ImageProvider：让阅读页保持占位高度，
/// 避免测试环境里 NetworkImage 400 触发 precache 的 FlutterError 上报。
class PendingImageProvider extends ImageProvider<PendingImageProvider> {
  const PendingImageProvider();

  @override
  Future<PendingImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<PendingImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    PendingImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
  }
}
