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

  return DirectMangaRepository(
    client: JmClient(
      proxyUrl: proxyUrl,
      autoUpdateDomains: autoUpdateDomains,
      customApiDomains: customApiDomains,
      customImageDomains: customImageDomains,
    ),
    proxyUrl: proxyUrl,
    ownerKey: ownerKey,
    username: account?.isAnonymous == false ? account?.username : null,
    password: account?.isAnonymous == false ? account?.password : null,
  );
});
