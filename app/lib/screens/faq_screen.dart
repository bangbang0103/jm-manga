import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final items = _faqItems(l10n)
        .where(
          (item) =>
              item.question.toLowerCase().contains(_query.toLowerCase()) ||
              item.answer.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.faqTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.faqSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _query = ''),
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      l10n.faqEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(
                            item.question,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Text(
                              item.answer,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              l10n.faqLogHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_FaqItem> _faqItems(AppLocalizations l10n) {
    return [
      _FaqItem(l10n.faqModesQuestion, l10n.faqModesAnswer),
      _FaqItem(l10n.faqModesDiffQuestion, l10n.faqModesDiffAnswer),
      _FaqItem(l10n.faqNoAccountQuestion, l10n.faqNoAccountAnswer),
      _FaqItem(l10n.faqFavoriteHowQuestion, l10n.faqFavoriteHowAnswer),
      _FaqItem(l10n.faqFavoriteOrderQuestion, l10n.faqFavoriteOrderAnswer),
      _FaqItem(l10n.faqReaderSlowQuestion, l10n.faqReaderSlowAnswer),
      _FaqItem(l10n.faqCdnQuestion, l10n.faqCdnAnswer),
      _FaqItem(l10n.faqProxyQuestion, l10n.faqProxyAnswer),
      _FaqItem(l10n.faqErrorsQuestion, l10n.faqErrorsAnswer),
      _FaqItem(l10n.faqLogLevelQuestion, l10n.faqLogLevelAnswer),
      _FaqItem(l10n.faqCacheLogsQuestion, l10n.faqCacheLogsAnswer),
    ];
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}
