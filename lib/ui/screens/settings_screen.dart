import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/supabase_config.dart';
import '../../data/secrets.dart';
import '../../services/claude_client.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _icuKey;
  late final TextEditingController _icuAthlete;
  late final TextEditingController _claudeKey;
  late final TextEditingController _claudeModel;
  late final TextEditingController _sbUrl;
  late final TextEditingController _sbKey;
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _shownKey;

  @override
  void initState() {
    super.initState();
    final sec = context.read<AppState>().secrets;
    _icuKey = TextEditingController(text: sec[Secrets.intervalsApiKey]);
    _icuAthlete = TextEditingController(
      text: sec[Secrets.intervalsAthleteId] ?? '0',
    );
    _claudeKey = TextEditingController(text: sec[Secrets.anthropicApiKey]);
    _claudeModel = TextEditingController(
      text: sec[Secrets.anthropicModel] ?? ClaudeClient.defaultModel,
    );
    _sbUrl = TextEditingController(text: sec[Secrets.supabaseUrl]);
    _sbKey = TextEditingController(text: sec[Secrets.supabaseKey]);
  }

  @override
  void dispose() {
    for (final c in [
      _icuKey,
      _icuAthlete,
      _claudeKey,
      _claudeModel,
      _sbUrl,
      _sbKey,
      _email,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final theme = Theme.of(context);
    final user = s.cloud.user;
    final key = s.secrets[Secrets.intervalsApiKey] ?? '';
    // Allinea i campi alla chiave attuale (può arrivare dall'account o
    // sparire al logout con la schermata aperta), dopo il frame.
    final wantKey = s.loggedIn ? key : '';
    if (_shownKey != wantKey) {
      _shownKey = wantKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _icuKey.text = wantKey;
        _icuAthlete.text = s.loggedIn
            ? s.secrets[Secrets.intervalsAthleteId] ?? '0'
            : '0';
      });
    }
    Widget secret(TextEditingController c, String label, {String? help}) =>
        TextField(
          controller: c,
          obscureText: true,
          decoration: InputDecoration(labelText: label, helperText: help),
        );
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: theme.textTheme.titleMedium),
    );
    Widget note(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Connessioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (s.secrets.usingFallback)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: theme.colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Portachiavi di sistema non disponibile: le chiavi sono salvate '
                  'nel database locale non cifrato. Su Linux installa e avvia '
                  'gnome-keyring o KWallet.',
                ),
              ),
            ),

          // --- Account ----------------------------------------------------
          title('Account'),
          if (!SupabaseConfig.isBuiltIn) ...[
            const Text(
              'Crea un progetto gratuito su supabase.com ed esegui lo script '
              'supabase/schema.sql nel SQL editor.',
            ),
            TextField(
              controller: _sbUrl,
              decoration: const InputDecoration(
                labelText: 'Project URL',
                hintText: 'https://xxxx.supabase.co',
              ),
            ),
            secret(_sbKey, 'Publishable (anon) key'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await guarded(
                  context,
                  () => s.saveSupabaseSettings(_sbUrl.text, _sbKey.text),
                );
                if (context.mounted) setState(() {});
              },
              child: const Text('Salva'),
            ),
            const SizedBox(height: 16),
          ],
          if (user != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle_rounded, size: 36),
                title: Text(user.email ?? 'Account'),
                subtitle: Text(
                  s.lastCloudSync == null
                      ? 'Mai sincronizzato'
                      : 'Ultima sync: ${timeFmt.format(s.lastCloudSync!)}',
                ),
                trailing: TextButton(
                  onPressed: () => _confirmSignOut(context, s),
                  child: const Text('Esci'),
                ),
              ),
            )
          else if (s.cloud.isConfigured) ...[
            const Text(
              'Accedi per collegare intervals.icu, vedere gli allenamenti, '
              'generare il menu e sincronizzare i dati tra i dispositivi.',
            ),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => guarded(
                    context,
                    () => s.cloudSignIn(_email.text.trim(), _password.text),
                  ),
                  child: const Text('Accedi'),
                ),
                OutlinedButton(
                  onPressed: () => guarded(
                    context,
                    () => s.cloudSignIn(
                      _email.text.trim(),
                      _password.text,
                      signUp: true,
                    ),
                  ),
                  child: const Text('Registrati'),
                ),
              ],
            ),
          ],
          const Divider(height: 40),

          // --- intervals.icu ----------------------------------------------
          title('intervals.icu'),
          if (!s.loggedIn)
            note(
              Icons.lock_outline_rounded,
              'La API key è legata al tuo account: accedi per collegare '
              'intervals.icu.',
            )
          else ...[
            secret(
              _icuKey,
              'API key',
              help: 'intervals.icu › Settings › Developer Settings',
            ),
            TextField(
              controller: _icuAthlete,
              decoration: const InputDecoration(
                labelText: 'ID atleta',
                helperText: '"0" = il proprietario della API key; es. i12345',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final ok = await guarded(context, () async {
                  await s.saveIntervalsSettings(_icuKey.text, _icuAthlete.text);
                  return s.testIntervals();
                });
                if (ok != null && context.mounted) {
                  showInfo(context, ok);
                  s.syncAll();
                }
              },
              child: const Text('Salva e verifica'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Salva la chiave nel mio account'),
              subtitle: Text(
                s.intervalsKeyInAccount
                    ? 'Gli altri dispositivi la ricevono quando accedi.'
                    : 'Ora è solo su questo dispositivo. Attivalo per non '
                          'doverla reinserire altrove.',
              ),
              value: s.intervalsKeyInAccount,
              onChanged: key.isEmpty
                  ? null
                  : (v) =>
                        guarded(context, () => s.setIntervalsKeyInAccount(v)),
            ),
          ],
          const Divider(height: 40),

          // --- Claude -----------------------------------------------------
          title('Claude (generazione ricette)'),
          secret(
            _claudeKey,
            'Anthropic API key',
            help: 'platform.claude.com › API keys. Uso a consumo.',
          ),
          TextField(
            controller: _claudeModel,
            decoration: const InputDecoration(
              labelText: 'Modello',
              helperText: 'Default: claude-opus-5-5',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await s.saveClaudeSettings(_claudeKey.text, _claudeModel.text);
              if (context.mounted) {
                showInfo(context, 'Impostazioni Claude salvate');
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Uscire dall\'account?'),
        content: const Text(
          'Da questo dispositivo verranno rimossi la API key di intervals.icu, '
          'gli allenamenti e i menu. I dati salvati nell\'account restano e '
          'tornano al prossimo accesso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await guarded(context, s.cloudSignOut);
    }
  }
}
