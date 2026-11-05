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
    final user = s.cloud.user;
    Widget secret(TextEditingController c, String label, {String? help}) =>
        TextField(
          controller: c,
          obscureText: true,
          decoration: InputDecoration(labelText: label, helperText: help),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Connessioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (s.secrets.usingFallback)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Portachiavi di sistema non disponibile: le chiavi sono salvate '
                  'nel database locale non cifrato. Su Linux installa e avvia '
                  'gnome-keyring o KWallet.',
                ),
              ),
            ),
          Text('intervals.icu', style: Theme.of(context).textTheme.titleMedium),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () async {
                  await s.saveIntervalsSettings(_icuKey.text, _icuAthlete.text);
                  if (!context.mounted) return;
                  final msg = await guarded(context, s.testIntervals);
                  if (msg != null && context.mounted) {
                    showInfo(context, msg);
                    s.syncAll();
                  }
                },
                child: const Text('Salva e verifica'),
              ),
            ],
          ),
          const Divider(height: 40),
          Text(
            'Claude (generazione ricette)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
          const Divider(height: 40),
          Text(
            'Sincronizzazione (Supabase)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (SupabaseConfig.isBuiltIn)
            const Text(
              'Sincronizza profilo, piani, ricette e menu tra i dispositivi. '
              'Accedi con lo stesso account su ognuno.',
            )
          else ...[
            const Text(
              'Sincronizza profilo, piani, ricette e menu tra i dispositivi. '
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
          ],
          if (s.cloud.isConfigured) ...[
            const SizedBox(height: 16),
            if (user != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_done),
                title: Text('Connesso come ${user.email}'),
                subtitle: Text(
                  s.lastCloudSync == null
                      ? 'Mai sincronizzato'
                      : 'Ultima sync: ${timeFmt.format(s.lastCloudSync!)}',
                ),
                trailing: TextButton(
                  onPressed: s.cloudSignOut,
                  child: const Text('Esci'),
                ),
              ),
            ] else ...[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 8),
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
          ],
        ],
      ),
    );
  }
}
