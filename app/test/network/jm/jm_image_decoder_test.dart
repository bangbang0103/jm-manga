import 'package:jm_manga/network/jm/jm_image_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('JmImageDecoder', () {
    test('returns zero segments below scramble threshold', () {
      expect(
        JmImageDecoder.segmentationCount(
          scrambleId: 220980,
          aid: 220979,
          filename: '00001',
        ),
        0,
      );
    });

    test('uses legacy fixed ten segments below 268850', () {
      expect(
        JmImageDecoder.segmentationCount(
          scrambleId: 220980,
          aid: 268849,
          filename: '00001',
        ),
        10,
      );
    });

    test('uses md5 based segment count for newer images', () {
      expect(
        JmImageDecoder.segmentationCount(
          scrambleId: 220980,
          aid: 421927,
          filename: '00001',
        ),
        8,
      );
    });

    test('restores vertical segments by reversing block order', () {
      final pixels = <int>[1, 1, 2, 2, 3, 3, 4, 4, 5, 5];

      final restored = JmImageDecoder.restoreVerticalSegments(
        pixels: pixels,
        rowStride: 2,
        height: 5,
        segmentCount: 3,
      );

      expect(restored, [3, 3, 4, 4, 5, 5, 2, 2, 1, 1]);
    });
  });
}
