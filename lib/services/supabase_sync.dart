import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local_store.dart';

/// Sincronizzazione bidirezionale con la tabella `sync_records` di Supabase
/// (schema in supabase/schema.sql).
///
/// - pull: legge i record con `server_updated_at` oltre il cursore salvato e
///   li applica se più recenti (last-write-wins su `updated_at`);
/// - push: carica i record locali "dirty". Un trigger lato server ignora gli
///   aggiornamenti con `updated_at` più vecchio di quello già presente.
class SupabaseSync {
  static const _cursorKey = 'supabase_pull_cursor';
  static const _table = 'sync_records';

  final LocalStore store;
  bool _initialized = false;
  String? _configuredUrl;
  StreamSubscription<AuthState>? _authSub;

  /// Chiamata quando cambia l'utente: login, logout, sessione scaduta o
  /// revocata.
  void Function(User? user)? onUserChanged;

  SupabaseSync(this.store);

  bool get isConfigured => _initialized;

  SupabaseClient get _client => Supabase.instance.client;

  User? get user => _initialized ? _client.auth.currentUser : null;

  Future<void> configure(String? url, String? key) async {
    if (url == null || key == null) {
      if (_initialized) {
        await _authSub?.cancel();
        await Supabase.instance.dispose();
        _initialized = false;
      }
      return;
    }
    if (_initialized && _configuredUrl == url) return;
    if (_initialized) {
      await _authSub?.cancel();
      await Supabase.instance.dispose();
    }
    await Supabase.initialize(url: url, publishableKey: key);
    _initialized = true;
    _configuredUrl = url;
    _authSub = _client.auth.onAuthStateChange.listen(
      (s) => onUserChanged?.call(s.session?.user),
      onError: (Object e) => debugPrint('Auth Supabase: $e'),
    );
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    // Nuovo account o nuovo dispositivo: rilegge tutto dal server.
    store.setKv(_cursorKey, null);
  }

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  /// Esce dall'account. La sessione locale viene rimossa subito; l'avviso
  /// al server può fallire (rete assente, risposta inattesa) senza impedire
  /// l'uscita.
  Future<void> signOut() async {
    store.setKv(_cursorKey, null);
    try {
      await _client.auth.signOut().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Logout sul server non riuscito (uscita locale ok): $e');
    }
  }

  /// Esegue pull + push. Ritorna il numero di record locali modificati.
  Future<int> sync() async {
    if (!_initialized || user == null) return 0;
    final changed = await _pull();
    await _push();
    return changed;
  }

  Future<int> _pull() async {
    var cursor = store.getKv(_cursorKey) ?? '1970-01-01T00:00:00Z';
    var changed = 0;
    while (true) {
      final rows = await _client
          .from(_table)
          .select('collection,id,data,updated_at,deleted,server_updated_at')
          .gt('server_updated_at', cursor)
          .order('server_updated_at')
          .limit(500);
      if (rows.isEmpty) break;
      for (final r in rows) {
        final applied = store.applyRemote(
          StoredRecord(
            r['collection'] as String,
            r['id'] as String,
            Map<String, dynamic>.from(r['data'] as Map),
            (r['updated_at'] as num).toInt(),
            r['deleted'] as bool? ?? false,
          ),
        );
        if (applied) changed++;
        cursor = r['server_updated_at'] as String;
      }
      store.setKv(_cursorKey, cursor);
      if (rows.length < 500) break;
    }
    return changed;
  }

  Future<void> _push() async {
    final dirty = store.dirtyRecords();
    if (dirty.isEmpty) return;
    const batch = 200;
    for (var i = 0; i < dirty.length; i += batch) {
      final chunk = dirty.sublist(i, (i + batch).clamp(0, dirty.length));
      await _client
          .from(_table)
          .upsert(
            chunk
                .map(
                  (r) => {
                    'collection': r.collection,
                    'id': r.id,
                    'data': r.data,
                    'updated_at': r.updatedAt,
                    'deleted': r.deleted,
                  },
                )
                .toList(),
            onConflict: 'user_id,collection,id',
          );
      for (final r in chunk) {
        store.markClean(r.collection, r.id, r.updatedAt);
      }
    }
    debugPrint('Supabase: caricati ${dirty.length} record');
  }
}
