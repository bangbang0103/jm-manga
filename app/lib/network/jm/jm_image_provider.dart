import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'jm_image_service_core.dart';

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
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<JmDecodedImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    JmDecodedImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.service.loadDecodedBytes(key.url);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is JmDecodedImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);
}
