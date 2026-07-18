import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/app_logger.dart';

class NewAccount {
  final String username;
  final String password;

  NewAccount({required this.username, required this.password});
}

class AddAccountDialog extends StatefulWidget {
  final Future<void> Function(String username, String password)? onLogin;

  const AddAccountDialog({super.key, this.onLogin});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  late final _usernameController = TextEditingController();
  late final _passwordController = TextEditingController();
  bool _loading = false;
  String? _usernameError;
  String? _passwordError;
  String? _loginError;

  String _mapLoginError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) return l10n.loginErrorUnauthorized;
      if (status != null) return l10n.loginErrorServer;
      return l10n.loginErrorNetwork;
    }
    return l10n.loginErrorServer;
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _usernameError = username.isEmpty ? l10n.fieldUsernameRequired : null;
      _passwordError = password.isEmpty ? l10n.fieldPasswordRequired : null;
      _loginError = null;
    });

    if (username.isEmpty || password.isEmpty) return;

    if (widget.onLogin != null) {
      setState(() => _loading = true);
      try {
        await widget.onLogin!(username, password);
        if (mounted) {
          Navigator.of(
            context,
          ).pop(NewAccount(username: username, password: password));
        }
      } catch (e, st) {
        globalLogger.e('JM login failed', error: e, stackTrace: st);
        if (mounted) {
          setState(() {
            _loading = false;
            _loginError = _mapLoginError(context, e);
          });
        }
      }
    } else {
      Navigator.of(
        context,
      ).pop(NewAccount(username: username, password: password));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoginMode = widget.onLogin != null;
    final actionLabel = isLoginMode ? l10n.actionLogin : l10n.actionAdd;
    final loadingLabel = isLoginMode ? l10n.actionLoginLoading : null;

    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(l10n.dialogAddAccountTitle),
          ),
          if (isLoginMode) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: l10n.loginMergeFavoritesHint,
              child: Icon(
                Icons.help_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: l10n.fieldUsername,
              errorText: _usernameError,
            ),
            enabled: !_loading,
            onChanged: (_) {
              if (_usernameError != null) {
                setState(() => _usernameError = null);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: l10n.fieldPassword,
              errorText: _passwordError,
            ),
            obscureText: true,
            enabled: !_loading,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          if (_loginError != null) ...[
            const SizedBox(height: 12),
            Text(
              _loginError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _handleSubmit,
          child: _loading && loadingLabel != null
              ? Text(loadingLabel)
              : Text(actionLabel),
        ),
      ],
    );
  }
}
