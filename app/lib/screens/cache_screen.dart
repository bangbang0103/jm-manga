import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../local/local_manga_store.dart';
import '../providers/owner_key_provider.dart';

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

Future<int> _directorySize(Directory dir) async {
  if (!await dir.exists()) return 0;
  var total = 0;
  try {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
  } catch (_) {
    // 忽略无法读取的文件。
  }
  return total;
}

Future<int> _coverCacheSize() async {
  final temp = await getTemporaryDirectory();
  final dir = Directory('${temp.path}/jm_covers');
  return _directorySize(dir);
}

Future<int> _imageCacheSize() async {
  final temp = await getTemporaryDirectory();
  final dir = Directory('${temp.path}/jm_decoded_images');
  return _directorySize(dir);
}

Future<int> _databaseSize(String ownerKey) async {
  try {
    final sizes = await LocalMangaStore().sizes(ownerKey);
    return sizes['database'] ?? 0;
  } catch (_) {
    return 0;
  }
}

Future<void> _clearCoverCache() async {
  final temp = await getTemporaryDirectory();
  final dir = Directory('${temp.path}/jm_covers');
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}

Future<void> _clearImageCache() async {
  final temp = await getTemporaryDirectory();
  final dir = Directory('${temp.path}/jm_decoded_images');
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}

Future<void> _clearAllCache() async {
  await _clearCoverCache();
  await _clearImageCache();
}

class _CacheSizes {
  final int coverCache;
  final int imageCache;
  final int database;

  const _CacheSizes({
    required this.coverCache,
    required this.imageCache,
    required this.database,
  });
}

class CacheScreen extends ConsumerStatefulWidget {
  const CacheScreen({super.key});

  @override
  ConsumerState<CacheScreen> createState() => _CacheScreenState();
}

class _CacheScreenState extends ConsumerState<CacheScreen> {
  late Future<_CacheSizes> _sizesFuture;
  var _initialLoad = true;

  @override
  void initState() {
    super.initState();
    _sizesFuture = _loadSizes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_initialLoad) {
      _initialLoad = false;
      return;
    }
    if (route?.isCurrent == true) {
      _refresh();
    }
  }

  Future<_CacheSizes> _loadSizes() async {
    final ownerKey = ref.read(ownerKeyProvider);
    final results = await Future.wait([
      _coverCacheSize(),
      _imageCacheSize(),
      _databaseSize(ownerKey),
    ]);
    return _CacheSizes(
      coverCache: results[0],
      imageCache: results[1],
      database: results[2],
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _sizesFuture = _loadSizes();
    });
  }

  Future<void> _clearAndRefresh(Future<void> Function() clear) async {
    await clear();
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cacheTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_CacheSizes>(
          future: _sizesFuture,
          builder: (context, snapshot) {
            final sizes = snapshot.data ??
                const _CacheSizes(coverCache: 0, imageCache: 0, database: 0);
            final ready = snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.image_outlined),
                        title: Text(l10n.cacheCoverCache),
                        subtitle: ready && sizes.coverCache == 0
                            ? Text(
                                l10n.cacheCoverCacheZeroHint,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              )
                            : null,
                        trailing: Text(
                          ready
                              ? _formatBytes(sizes.coverCache)
                              : l10n.calculatingLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: Text(l10n.cacheImageCache),
                        subtitle: ready && sizes.imageCache == 0
                            ? Text(
                                l10n.cacheImageCacheZeroHint,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              )
                            : null,
                        trailing: Text(
                          ready
                              ? _formatBytes(sizes.imageCache)
                              : l10n.calculatingLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.storage_outlined),
                        title: Text(l10n.cacheDatabase),
                        trailing: Text(
                          ready
                              ? _formatBytes(sizes.database)
                              : l10n.calculatingLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (ready)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _clearAndRefresh(_clearCoverCache),
                              child: Text(l10n.cacheClearCovers),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _clearAndRefresh(_clearImageCache),
                              child: Text(l10n.cacheClearImages),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _clearAndRefresh(_clearAllCache),
                        child: Text(l10n.cacheClearAll),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
