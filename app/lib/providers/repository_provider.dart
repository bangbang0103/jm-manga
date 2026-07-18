import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/direct_manga_repository.dart';
import '../data/manga_repository.dart';
import '../network/jm/jm_client.dart';
import 'account_provider.dart';
import 'config_provider.dart';
import 'owner_key_provider.dart';

final proxyUrlProvider = Provider<String?>((ref) {
  return ref.watch(configProvider.select((config) => config.proxyUrl));
});

final autoUpdateJmDomainsProvider = Provider<bool>((ref) {
  return ref.watch(
    configProvider.select((config) => config.autoSelectJmDomain),
  );
});

final customApiDomainsProvider = Provider<List<String>>((ref) {
  return ref.watch(
    configProvider.select((config) => config.customApiDomains),
  );
});

final customImageDomainsProvider = Provider<List<String>>((ref) {
  return ref.watch(
    configProvider.select((config) => config.customImageDomains),
  );
});

final apiRepositoryProvider = Provider<MangaRepository>((ref) {
  final account = ref.watch(selectedAccountProvider);
  final ownerKey = ref.watch(ownerKeyProvider);
  final proxyUrl = ref.watch(proxyUrlProvider);
  final autoUpdateDomains = ref.watch(autoUpdateJmDomainsProvider);
  final customApiDomains = ref.watch(customApiDomainsProvider);
  final customImageDomains = ref.watch(customImageDomainsProvider);

  final client = JmClient(
    proxyUrl: proxyUrl,
    autoUpdateDomains: autoUpdateDomains,
    customApiDomains: customApiDomains,
    customImageDomains: customImageDomains,
  );
  // 配置变更会重建本 provider；关闭旧 client 的 Dio，避免连接池累积。
  ref.onDispose(client.close);

  final repository = DirectMangaRepository(
    client: client,
    proxyUrl: proxyUrl,
    ownerKey: ownerKey,
    username: account?.isAnonymous == false ? account?.username : null,
    password: account?.isAnonymous == false ? account?.password : null,
  );
  // 图片服务持有独立的 image Dio，同样需要在重建时关闭。
  ref.onDispose(repository.imageService.close);

  return repository;
});
