import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'local_store.dart';

/// Chiavi API e credenziali. Usa il portachiavi di sistema (libsecret su
/// Linux, Keystore su Android, Credential Manager su Windows); se non è
/// disponibile ripiega sul database locale, segnalandolo all'utente.
class Secrets {
  static const intervalsApiKey = 'intervals_api_key';
  static const intervalsAthleteId = 'intervals_athlete_id';
  static const anthropicApiKey = 'anthropic_api_key';
  static const anthropicModel = 'anthropic_model';
  static const supabaseUrl = 'supabase_url';
  static const supabaseKey = 'supabase_publishable_key';

  final LocalStore _fallback;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  bool usingFallback = false;
  final Map<String, String> _cache = {};

  Secrets(this._fallback);

  static const _keys = [
    intervalsApiKey,
    intervalsAthleteId,
    anthropicApiKey,
    anthropicModel,
    supabaseUrl,
    supabaseKey,
  ];

  Future<void> load() async {
    try {
      for (final k in _keys) {
        final v = await _secure.read(key: k);
        if (v != null) _cache[k] = v;
      }
    } catch (e) {
      debugPrint('Portachiavi non disponibile, uso il DB locale: $e');
      usingFallback = true;
    }
    for (final k in _keys) {
      final v = _fallback.getKv('secret:$k');
      if (v != null) _cache.putIfAbsent(k, () => v);
    }
  }

  String? operator [](String key) => _cache[key];

  Future<void> set(String key, String? value) async {
    final v = (value == null || value.trim().isEmpty) ? null : value.trim();
    if (v == null) {
      _cache.remove(key);
    } else {
      _cache[key] = v;
    }
    if (!usingFallback) {
      try {
        // Un portachiavi bloccato può restare in attesa (es. richiesta di
        // sblocco): oltre il limite si ripiega sul database locale.
        const limit = Duration(seconds: 5);
        if (v == null) {
          await _secure.delete(key: key).timeout(limit);
        } else {
          await _secure.write(key: key, value: v).timeout(limit);
        }
        _fallback.setKv('secret:$key', null);
        return;
      } catch (e) {
        debugPrint('Scrittura nel portachiavi fallita: $e');
        usingFallback = true;
      }
    }
    _fallback.setKv('secret:$key', v);
  }
}
