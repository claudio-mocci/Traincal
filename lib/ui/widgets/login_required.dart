import 'package:flutter/material.dart';

import '../screens/settings_screen.dart';
import 'common.dart';

/// Messaggio per le funzioni legate all'account (allenamenti, menu), con il
/// pulsante per accedere.
class LoginRequired extends StatelessWidget {
  final String text;

  const LoginRequired(this.text, {super.key});

  @override
  Widget build(BuildContext context) => EmptyHint(
    icon: Icons.lock_outline_rounded,
    text: text,
    action: FilledButton.icon(
      icon: const Icon(Icons.login_rounded),
      label: const Text('Accedi'),
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
    ),
  );
}
