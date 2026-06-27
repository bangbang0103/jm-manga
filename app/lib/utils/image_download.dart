import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/repository_provider.dart';
import 'error_mapper.dart';
import 'top_toast.dart';

String? _filenameFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final path = uri.path;
    final name = path.split('/').last;
    if (name.isNotEmpty) return name;
  } catch (_) {
    // ignore
  }
  return null;
}

Future<void> downloadAndShareImage(
  BuildContext context,
  WidgetRef ref, {
  required String url,
  String? fallbackName,
}) async {
  final l10n = AppLocalizations.of(context)!;
  if (context.mounted) {
    TopToast.show(context, l10n.imageDownloadStarted);
  }

  try {
    final repo = ref.read(apiRepositoryProvider);
    final bytes = await repo.downloadImage(url);
    if (bytes.isEmpty) {
      throw StateError('empty image bytes');
    }

    final tempDir = await getTemporaryDirectory();
    final filename = _filenameFromUrl(url) ?? fallbackName ?? 'image.jpg';
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    if (!context.mounted) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  } catch (e) {
    if (context.mounted) {
      TopToast.show(
        context,
        mapErrorToUserMessage(e, l10n),
        type: TopToastType.error,
      );
    }
  }
}

void showImageDownloadSheet(
  BuildContext context,
  WidgetRef ref, {
  required String url,
  String? fallbackName,
}) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.imageDownload),
            onTap: () {
              Navigator.of(context).pop();
              downloadAndShareImage(
                context,
                ref,
                url: url,
                fallbackName: fallbackName,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text(l10n.actionCancel),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}
