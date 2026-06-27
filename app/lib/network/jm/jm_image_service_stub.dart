import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'jm_client.dart';

class JmDecodedImageProvider extends ImageProvider<JmDecodedImageProvider> {
  final String url;
  final JmImageService service;
  final double scale;

  const JmDecodedImageProvider({
    required this.url,
    required this.service,
    this.scale = 1.0,
  });

  @override
  Future<JmDecodedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<JmDecodedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    JmDecodedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    throw UnsupportedError('Direct JM images are not supported on Web');
  }
}

class JmImageService {
  JmImageService({
    required Dio dio,
    JmImageCache? cache,
    int maxConcurrent = 5,
    JmClient? client,
  });

  factory JmImageService.forClient(JmClient client, {String? proxyUrl}) {
    throw UnsupportedError('Direct JM images are not supported on Web');
  }

  Future<Uint8List> loadDecodedBytes(String url) {
    throw UnsupportedError('Direct JM images are not supported on Web');
  }
}

class JmImageMetadata {
  factory JmImageMetadata.fromUrl(String url) {
    throw UnsupportedError('Direct JM images are not supported on Web');
  }
}

class JmImageCache {
  Future<void> evictIfNeeded() async {}
}

Uint8List decodeJmImageBytesForTest({
  required Uint8List bytes,
  required int photoId,
  required String filename,
  required int scrambleId,
  bool isGif = false,
}) {
  throw UnsupportedError('Direct JM images are not supported on Web');
}
