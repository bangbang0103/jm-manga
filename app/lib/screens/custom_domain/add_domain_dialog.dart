import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/custom_domain_utils.dart';

class AddDomainDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String addLabel;

  const AddDomainDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.addLabel,
  });

  @override
  State<AddDomainDialog> createState() => _AddDomainDialogState();
}

class _AddDomainDialogState extends State<AddDomainDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final result = CustomDomainUtils.parse(value);
    if (result.uri == null) {
      setState(() => _error = result.error ?? 'Invalid domain');
      return;
    }
    Navigator.of(context).pop(result.uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.addLabel,
          hintText: widget.hint,
          errorText: _error,
          filled: true,
          fillColor: scheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.error, width: 1.5),
          ),
          prefixIcon: Icon(
            Icons.add_link_outlined,
            color: scheme.onSurfaceVariant,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.customDomainAddHint),
        ),
      ],
    );
  }
}
