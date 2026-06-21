import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/api_repository.dart';
import 'account_provider.dart';
import 'config_provider.dart';
import 'device_provider.dart';

final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  final config = ref.watch(configProvider);
  final account = ref.watch(selectedAccountProvider);
  final deviceId = ref.watch(deviceIdProvider);
  final client = ApiClient(
    baseUrl: config.baseUrl,
    apiToken: config.apiToken,
    jmUsername: account?.username,
    deviceId: deviceId,
    onUnauthorized: () async {
      // 服务端返回 401 时清空本地保存的 token，避免反复使用无效凭据。
      await ref
          .read(configProvider.notifier)
          .setConnection(config.baseUrl, null);
    },
  );
  return ApiRepository(client: client);
});
