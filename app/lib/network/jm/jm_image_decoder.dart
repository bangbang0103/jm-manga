import 'dart:typed_data';

import 'jm_constants.dart';
import 'jm_crypto.dart';

class JmImageDecoder {
  const JmImageDecoder._();

  static int segmentationCount({
    required int scrambleId,
    required int aid,
    required String filename,
  }) {
    if (aid < scrambleId) {
      return 0;
    }
    if (aid < JmConstants.scramble268850) {
      return 10;
    }

    final modulo = aid < JmConstants.scramble421926 ? 10 : 8;
    final digest = JmCrypto.md5Hex('$aid$filename');
    return (digest.codeUnitAt(digest.length - 1) % modulo) * 2 + 2;
  }

  static Uint8List restoreVerticalSegments({
    required List<int> pixels,
    required int rowStride,
    required int height,
    required int segmentCount,
  }) {
    if (segmentCount <= 1) {
      return Uint8List.fromList(pixels);
    }
    if (rowStride <= 0 || height <= 0) {
      throw ArgumentError('rowStride and height must be positive');
    }
    if (pixels.length != rowStride * height) {
      throw ArgumentError('pixels length must equal rowStride * height');
    }

    final output = Uint8List(pixels.length);
    final baseHeight = height ~/ segmentCount;
    final remainder = height % segmentCount;
    final blocks = <({int start, int end})>[];
    var totalHeight = 0;

    for (var i = 0; i < segmentCount; i++) {
      var end = baseHeight * (i + 1);
      if (i == segmentCount - 1) {
        end += remainder;
      }
      blocks.add((start: totalHeight, end: end));
      totalHeight = end;
    }

    var targetRow = 0;
    for (final block in blocks.reversed) {
      final copyHeight = block.end - block.start;
      final sourceOffset = block.start * rowStride;
      final targetOffset = targetRow * rowStride;
      output.setRange(
        targetOffset,
        targetOffset + copyHeight * rowStride,
        pixels,
        sourceOffset,
      );
      targetRow += copyHeight;
    }

    return output;
  }
}
