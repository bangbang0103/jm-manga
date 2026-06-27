import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'network/http_overrides.dart';
import 'providers/config_provider.dart';
import 'router.dart';
import 'utils/app_logger.dart';
import 'utils/image_cache_cleanup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureNoProxyHttpOverrides();
  await globalLogger.init();

  // 冷启动时异步清理过期/超限图片缓存，不阻塞 UI。
  evictImageCacheIfNeeded().catchError((Object _) {});

  runApp(const ProviderScope(child: JmApp()));
}

class JmApp extends ConsumerWidget {
  const JmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    return MaterialApp.router(
      title: 'JM Manga',
      debugShowCheckedModeBanner: false,
      themeMode: config.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      locale: config.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
