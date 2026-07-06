import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:jm_manga/network/jm/jm_client.dart';
import 'package:jm_manga/utils/error_mapper.dart';

void main() {
  group('mapErrorToUserMessage', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('maps connection timeout to network unavailable', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(mapErrorToUserMessage(error, l10n), contains('Network unavailable'));
    });

    test('maps 401 bad response to login expired', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 401,
        ),
      );
      expect(mapErrorToUserMessage(error, l10n), contains('Session expired'));
    });

    test('maps other bad response to server response', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 500,
        ),
      );
      expect(
        mapErrorToUserMessage(error, l10n),
        contains('unexpected response'),
      );
    });

    test('maps cancel to generic error', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.cancel,
      );
      expect(mapErrorToUserMessage(error, l10n), contains('Something went wrong'));
    });

    test('maps FormatException to local data corrupted', () {
      expect(
        mapErrorToUserMessage(const FormatException(), l10n),
        contains('corrupted'),
      );
    });

    test('maps JmApiException to server response', () {
      expect(
        mapErrorToUserMessage(
          const JmApiException(code: 500, message: 'fail'),
          l10n,
        ),
        contains('unexpected response'),
      );
    });

    test('maps unknown error to generic error', () {
      expect(
        mapErrorToUserMessage(Exception('x'), l10n),
        contains('Something went wrong'),
      );
    });
  });
}
