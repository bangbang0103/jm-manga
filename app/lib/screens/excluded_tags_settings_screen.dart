import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/config_provider.dart';
import '../utils/top_toast.dart';
import '../widgets/tag_chip.dart';

class ExcludedTagsSettingsScreen extends ConsumerStatefulWidget {
  const ExcludedTagsSettingsScreen({super.key});

  @override
  ConsumerState<ExcludedTagsSettingsScreen> createState() =>
      _ExcludedTagsSettingsScreenState();
}

class _ExcludedTagsSettingsScreenState
    extends ConsumerState<ExcludedTagsSettingsScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addTag() async {
    final tag = ConfigNotifier.normalizeTag(_controller.text);
    if (tag.isEmpty) return;

    final current = ref.read(configProvider).excludedTags;
    if (current.contains(tag)) {
      _controller.clear();
      return;
    }

    final updated = [...current, tag];
    await ref.read(configProvider.notifier).setExcludedTags(updated);
    _controller.clear();

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      TopToast.show(
        context,
        l10n.excludedTagsAdded(tag),
        type: TopToastType.success,
      );
    }
  }

  Future<void> _removeTag(String tag) async {
    final current = ref.read(configProvider).excludedTags;
    final updated = current.where((t) => t != tag).toList();
    await ref.read(configProvider.notifier).setExcludedTags(updated);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      TopToast.show(
        context,
        l10n.excludedTagsRemoved(tag),
        type: TopToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final excludedTags = ref.watch(configProvider).excludedTags;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.excludedTagsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: l10n.excludedTagsHint,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTag(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: excludedTags.isEmpty
                  ? Center(
                      child: Text(
                        l10n.excludedTagsEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: excludedTags.map((tag) {
                          return TagChip(
                            label: tag,
                            variant: TagChipVariant.error,
                            onDelete: () => _removeTag(tag),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
