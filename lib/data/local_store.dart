import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

/// Collezioni replicate su Supabase. Gli allenamenti no: la fonte è
/// intervals.icu e restano solo in cache locale.
class Collections {
  static const profile = 'profile';
  static const plans = 'plans';
  static const foods = 'foods';
  static const recipes = 'recipes';
  static const mealPlans = 'meal_plans';
  static const prefs = 'prefs';
  static const workoutCache = 'workout_cache';

  /// Credenziali dei servizi (API key di intervals.icu), così basta
  /// impostarle su un dispositivo. Protette dalle regole RLS di Supabase.
  static const credentials = 'credentials';

  static const synced = {
    profile,
    plans,
    foods,
    recipes,
    mealPlans,
    prefs,
    credentials,
  };
}

class StoredRecord {
  final String collection;
  final String id;
  final Map<String, dynamic> data;
  final int updatedAt;
  final bool deleted;

  const StoredRecord(
    this.collection,
    this.id,
    this.data,
    this.updatedAt,
    this.deleted,
  );
}

/// Archivio a documenti su SQLite: ogni record è JSON con timestamp di
/// modifica, flag di cancellazione logica e flag "dirty" per la sync.
class LocalStore {
  final Database _db;

  LocalStore._(this._db) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS records (
        collection TEXT NOT NULL,
        id TEXT NOT NULL,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0,
        dirty INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (collection, id)
      )''');
    _db.execute(
      'CREATE TABLE IF NOT EXISTS kv (key TEXT PRIMARY KEY, value TEXT)',
    );
  }

  factory LocalStore.open(String path) => LocalStore._(sqlite3.open(path));

  factory LocalStore.inMemory() => LocalStore._(sqlite3.openInMemory());

  static int now() => DateTime.now().millisecondsSinceEpoch;

  List<Map<String, dynamic>> all(String collection) => _db
      .select(
        'SELECT data FROM records WHERE collection = ? AND deleted = 0 '
        'ORDER BY id',
        [collection],
      )
      .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
      .toList();

  Map<String, dynamic>? get(String collection, String id) {
    final rows = _db.select(
      'SELECT data FROM records WHERE collection = ? AND id = ? AND deleted = 0',
      [collection, id],
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  void put(String collection, String id, Map<String, dynamic> data) {
    _db.execute(
      'INSERT INTO records (collection, id, data, updated_at, deleted, dirty) '
      'VALUES (?, ?, ?, ?, 0, ?) '
      'ON CONFLICT(collection, id) DO UPDATE SET data = excluded.data, '
      'updated_at = excluded.updated_at, deleted = 0, dirty = excluded.dirty',
      [
        collection,
        id,
        jsonEncode(data),
        now(),
        Collections.synced.contains(collection) ? 1 : 0,
      ],
    );
  }

  void delete(String collection, String id) {
    _db.execute(
      'UPDATE records SET deleted = 1, updated_at = ?, dirty = ? '
      'WHERE collection = ? AND id = ?',
      [now(), Collections.synced.contains(collection) ? 1 : 0, collection, id],
    );
  }

  /// Sostituisce l'intera collezione (usato per la cache degli allenamenti).
  void replaceAll(String collection, Map<String, Map<String, dynamic>> docs) {
    _db.execute('BEGIN');
    try {
      _db.execute('DELETE FROM records WHERE collection = ?', [collection]);
      final stmt = _db.prepare(
        'INSERT INTO records (collection, id, data, updated_at) VALUES (?, ?, ?, ?)',
      );
      final t = now();
      docs.forEach((id, d) => stmt.execute([collection, id, jsonEncode(d), t]));
      stmt.close();
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  // --- Sync ---------------------------------------------------------------

  List<StoredRecord> dirtyRecords() => _db
      .select('SELECT * FROM records WHERE dirty = 1')
      .map(
        (r) => StoredRecord(
          r['collection'] as String,
          r['id'] as String,
          jsonDecode(r['data'] as String) as Map<String, dynamic>,
          r['updated_at'] as int,
          (r['deleted'] as int) == 1,
        ),
      )
      .toList();

  void markClean(String collection, String id, int updatedAt) {
    _db.execute(
      'UPDATE records SET dirty = 0 WHERE collection = ? AND id = ? AND updated_at = ?',
      [collection, id, updatedAt],
    );
  }

  /// Applica un record remoto se è più recente di quello locale.
  /// Ritorna true se il dato locale è cambiato.
  bool applyRemote(StoredRecord r) {
    final rows = _db.select(
      'SELECT updated_at FROM records WHERE collection = ? AND id = ?',
      [r.collection, r.id],
    );
    if (rows.isNotEmpty && (rows.first['updated_at'] as int) >= r.updatedAt) {
      return false;
    }
    _db.execute(
      'INSERT INTO records (collection, id, data, updated_at, deleted, dirty) '
      'VALUES (?, ?, ?, ?, ?, 0) '
      'ON CONFLICT(collection, id) DO UPDATE SET data = excluded.data, '
      'updated_at = excluded.updated_at, deleted = excluded.deleted, dirty = 0',
      [r.collection, r.id, jsonEncode(r.data), r.updatedAt, r.deleted ? 1 : 0],
    );
    return true;
  }

  // --- Chiave/valore locale (non sincronizzato) ---------------------------

  String? getKv(String key) {
    final rows = _db.select('SELECT value FROM kv WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  void setKv(String key, String? value) {
    if (value == null) {
      _db.execute('DELETE FROM kv WHERE key = ?', [key]);
    } else {
      _db.execute(
        'INSERT INTO kv (key, value) VALUES (?, ?) '
        'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
        [key, value],
      );
    }
  }

  void close() => _db.close();
}
