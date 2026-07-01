import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_manga/l10n/app_localizations.dart';

import 'tag_chip.dart';

class SearchFilterSheet extends StatefulWidget {
  final List<String> currentExcludes;
  final List<String> globalExcludes;
  final List<String> allowedGlobal;
  final ValueChanged<String> onExcludeAdded;
  final ValueChanged<String> onExcludeRemoved;
  final void Function(String tag, bool allowed) onGlobalAllowedChanged;

  const SearchFilterSheet({
    super.key,
    required this.currentExcludes,
    required this.globalExcludes,
    required this.allowedGlobal,
    required this.onExcludeAdded,
    required this.onExcludeRemoved,
    required this.onGlobalAllowedChanged,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  final _controller = TextEditingController();
  late List<String> _currentExcludes;
  late List<String> _allowedGlobal;

  @override
  void initState() {
    super.initState();
    _currentExcludes = widget.currentExcludes;
    _allowedGlobal = widget.allowedGlobal;
  }

  @override
  void didUpdateWidget(SearchFilterSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentExcludes != widget.currentExcludes) {
      _currentExcludes = widget.currentExcludes;
    }
    if (oldWidget.allowedGlobal != widget.allowedGlobal) {
      _allowedGlobal = widget.allowedGlobal;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addExclude() {
    final tag = _controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (tag.isEmpty) return;
    if (tag.startsWith('+') || tag.startsWith('-')) {
      // 避免用户把符号也输进来；只取有效 tag 名。
      // 这里简单丢弃前缀，让面板只处理 tag 本身。
      final clean = tag.substring(1).trim();
      if (clean.isEmpty) return;
      setState(() {
        _currentExcludes = {..._currentExcludes, clean}.toList();
      });
      widget.onExcludeAdded(clean);
    } else {
      setState(() {
        _currentExcludes = {..._currentExcludes, tag}.toList();
      });
      widget.onExcludeAdded(tag);
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.searchFilterTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 本次排除
                    Text(
                      l10n.searchFilterCurrentExcludes,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: l10n.excludedTagsHint,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addExclude,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addExclude(),
                    ),
                    const SizedBox(height: 12),
                    _buildExcludeChips(context),
                    const SizedBox(height: 24),
                    // 全局黑名单
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.searchFilterGlobalExcludes,
                          style: theme.textTheme.titleSmall,
                        ),
                        TextButton(
                          onPressed: () {
                            context.pop();
                            context.push('/settings/excluded-tags');
                          },
                          child: Text(l10n.searchFilterManageGlobal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildGlobalList(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcludeChips(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final excludes = _currentExcludes;

    if (excludes.isEmpty) {
      return Text(
        l10n.searchFilterNoCurrentExcludes,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: excludes.map((tag) {
        return TagChip(
          label: '-$tag',
          variant: TagChipVariant.error,
          onDelete: () {
            setState(() {
              _currentExcludes = _currentExcludes
                  .where((current) => current != tag)
                  .toList();
            });
            widget.onExcludeRemoved(tag);
          },
        );
      }).toList(),
    );
  }

  Widget _buildGlobalList(BuildContext context) {
    final theme = Theme.of(context);
    final global = widget.globalExcludes;

    if (global.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.excludedTagsEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: global.map((tag) {
        final allowed = _allowedGlobal.contains(tag);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tag),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.searchFilterAllowThisTime,
                style: theme.textTheme.bodySmall,
              ),
              Switch(
                value: allowed,
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      _allowedGlobal = {..._allowedGlobal, tag}.toList();
                    } else {
                      _allowedGlobal = _allowedGlobal
                          .where((current) => current != tag)
                          .toList();
                    }
                  });
                  widget.onGlobalAllowedChanged(tag, value);
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
