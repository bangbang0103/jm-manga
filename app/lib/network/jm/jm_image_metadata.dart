import 'jm_constants.dart';

class JmImageMetadata {
  final Uri requestUri;
  final int photoId;
  final String filename;
  final String filenameWithoutExtension;
  final int scrambleId;
  final bool hasScrambleId;
  final bool isGif;
  final bool isCover;

  const JmImageMetadata({
    required this.requestUri,
    required this.photoId,
    required this.filename,
    required this.filenameWithoutExtension,
    required this.scrambleId,
    required this.hasScrambleId,
    required this.isGif,
    required this.isCover,
  });

  factory JmImageMetadata.fromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final photosIndex = segments.indexOf('photos');
    final albumsIndex = segments.indexOf('albums');

    final int photoId;
    final String filename;
    final bool isCover;
    if (photosIndex >= 0 && photosIndex + 2 < segments.length) {
      photoId = int.parse(segments[photosIndex + 1]);
      filename = segments[photosIndex + 2];
      isCover = false;
    } else if (albumsIndex >= 0 && albumsIndex + 1 < segments.length) {
      // 封面图：/media/albums/{aid}{size}.jpg
      final rawId = segments[albumsIndex + 1].split('_').first;
      photoId = int.tryParse(rawId) ?? 0;
      filename = segments[albumsIndex + 1];
      isCover = true;
    } else {
      throw FormatException('Unsupported JM image url: $url');
    }

    final dot = filename.lastIndexOf('.');
    final filenameWithoutExtension = dot <= 0
        ? filename
        : filename.substring(0, dot);
    final query = Map<String, String>.from(uri.queryParameters)
      ..remove('scramble_id');
    final rawScrambleId = uri.queryParameters['scramble_id'];
    final scrambleId = isCover
        ? JmConstants.scramble220980
        : (int.tryParse(rawScrambleId ?? '') ?? JmConstants.scramble220980);

    return JmImageMetadata(
      requestUri: uri.replace(queryParameters: query.isEmpty ? null : query),
      photoId: photoId,
      filename: filename,
      filenameWithoutExtension: filenameWithoutExtension,
      scrambleId: scrambleId,
      hasScrambleId:
          !isCover && rawScrambleId != null && rawScrambleId.isNotEmpty,
      isGif: filename.toLowerCase().endsWith('.gif'),
      isCover: isCover,
    );
  }
}
