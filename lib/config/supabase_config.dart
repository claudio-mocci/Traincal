/// Progetto Supabase per la sincronizzazione, incluso nell'app: così
/// all'utente resta solo il login.
///
/// La publishable key è pensata per stare nelle app client: l'accesso ai dati
/// è protetto dalle regole RLS di `supabase/schema.sql` (ogni utente vede
/// solo i propri record). Non inserire mai qui la secret / service_role key.
///
/// Si possono sovrascrivere in fase di build:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...`
///
/// Se restano vuoti, URL e key si inseriscono a mano nella schermata
/// Connessioni.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ttmyldknmnxcuhyfcggm.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_jAqyzVJicElnQeznTIsLlQ_8kHSwRu4',
  );

  static bool get isBuiltIn => url.isNotEmpty && publishableKey.isNotEmpty;
}
