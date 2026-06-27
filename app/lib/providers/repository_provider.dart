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

final apiRepositoryProvider = Provider<MangaRepository>((ref) {
  final account = ref.watch(selectedAccountProvider);
  final ownerKey = ref.watch(ownerKeyProvider);
  final proxyUrl = ref.watch(proxyUrlProvider);
  final autoUpdateDomains = ref.watch(autoUpdateJmDomainsProvider);

  return DirectMangaRepository(
    client: JmClient(
      proxyUrl: proxyUrl,
      autoUpdateDomains: autoUpdateDomains,
    ),
    proxyUrl: proxyUrl,
    ownerKey: ownerKey,
    username: account?.isAnonymous == false ? account?.username : null,
    password: account?.isAnonymous == false ? account?.password : null,
  );
});
