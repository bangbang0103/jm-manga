import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureHttpClientAdapter(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) => 'DIRECT';
      return client;
    },
  );
}
