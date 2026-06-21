import 'package:dio/dio.dart';

import 'api_client_platform_stub.dart'
    if (dart.library.io) 'api_client_platform_io.dart';

void configurePlatformHttpClient(Dio dio) {
  configureHttpClientAdapter(dio);
}
