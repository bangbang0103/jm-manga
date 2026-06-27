import 'package:dio/dio.dart';

import '../network/jm/jm_client.dart';
import '../l10n/app_localizations.dart';
import 'app_logger.dart';

/// 把异常映射为用户友好的本地化文案。
///
/// 详细异常会被记录到日志，返回的字符串只用于 UI 展示。
String mapErrorToUserMessage(Object error, AppLocalizations l10n) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return l10n.errorNetworkUnavailable;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return l10n.errorLoginExpired;
        }
        return l10n.errorServerResponse;
      case DioExceptionType.cancel:
        return l10n.errorGeneric;
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        break;
    }
  }

  if (error is FormatException) {
    return l10n.errorLocalDataCorrupted;
  }

  if (error is JmApiException) {
    return l10n.errorServerResponse;
  }

  // 兜底：记录未知异常详情，但 UI 不暴露原始信息。
  globalLogger.w('Unhandled UI error: $error');
  return l10n.errorGeneric;
}
