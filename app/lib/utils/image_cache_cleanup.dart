import '../network/jm/jm_image_service_stub.dart'
    if (dart.library.io) '../network/jm/jm_image_service_io.dart';

Future<void> evictImageCacheIfNeeded() async {
  await JmImageCache().evictIfNeeded();
}
