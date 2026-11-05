import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/food_db.dart';
import '../config/supabase_config.dart';
import '../data/local_store.dart';
import '../data/secrets.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/nutrition_plan.dart';
import '../models/profile.dart';
import '../models/recipe.dart';
import '../models/workout.dart';
import '../services/claude_client.dart';
import '../services/energy_calculator.dart';
import '../services/intervals_client.dart';
import '../services/meal_planner.dart';
import '../services/shopping_list.dart';
import '../services/supabase_sync.dart';

DateTime mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

class MealPrepPrefs {
  final int prepSessions;
  final MealPrepStyle style;
  final int mainVariety;
  final int breakfastVariety;
  final int snackVariety;
  final Set<String> excludedRecipeIds;

  /// Colazioni e spuntini fissi, sempre presenti nella rotazione.
  final Set<String> pinnedRecipeIds;

  const MealPrepPrefs({
    this.prepSessions = 2,
    this.style = MealPrepStyle.recipes,
    this.mainVariety = 3,
    this.breakfastVariety = 2,
    this.snackVariety = 2,
    this.excludedRecipeIds = const {},
    this.pinnedRecipeIds = const {},
  });

  MealPrepPrefs copyWith({
    int? prepSessions,
    MealPrepStyle? style,
    int? mainVariety,
    int? breakfastVariety,
    int? snackVariety,
    Set<String>? excludedRecipeIds,
    Set<String>? pinnedRecipeIds,
  }) => MealPrepPrefs(
    prepSessions: prepSessions ?? this.prepSessions,
    style: style ?? this.style,
    mainVariety: mainVariety ?? this.mainVariety,
    breakfastVariety: breakfastVariety ?? this.breakfastVariety,
    snackVariety: snackVariety ?? this.snackVariety,
    excludedRecipeIds: excludedRecipeIds ?? this.excludedRecipeIds,
    pinnedRecipeIds: pinnedRecipeIds ?? this.pinnedRecipeIds,
  );

  Map<String, dynamic> toJson() => {
    'prepSessions': prepSessions,
    'style': style.name,
    'mainVariety': mainVariety,
    'breakfastVariety': breakfastVariety,
    'snackVariety': snackVariety,
    'excludedRecipeIds': excludedRecipeIds.toList(),
    'pinnedRecipeIds': pinnedRecipeIds.toList(),
  };

  factory MealPrepPrefs.fromJson(Map<String, dynamic> j) => MealPrepPrefs(
    prepSessions: (j['prepSessions'] as num?)?.toInt() ?? 2,
    style:
        MealPrepStyle.values.asNameMap()[j['style']] ?? MealPrepStyle.recipes,
    mainVariety: (j['mainVariety'] as num?)?.toInt() ?? 3,
    breakfastVariety: (j['breakfastVariety'] as num?)?.toInt() ?? 2,
    snackVariety: (j['snackVariety'] as num?)?.toInt() ?? 2,
    excludedRecipeIds: ((j['excludedRecipeIds'] as List?) ?? const [])
        .cast<String>()
        .toSet(),
    pinnedRecipeIds: ((j['pinnedRecipeIds'] as List?) ?? const [])
        .cast<String>()
        .toSet(),
  );
}

class AppState extends ChangeNotifier {
  late final LocalStore store;
  late final Secrets secrets;
  late final SupabaseSync cloud;
  static const _uuid = Uuid();

  bool ready = false;
  bool syncing = false;
  String? lastError;
  DateTime? lastIntervalsSync;
  DateTime? lastCloudSync;
  Timer? _timer;

  UserProfile profile = const UserProfile();
  List<NutritionPlan> plans = [];
  FoodDb _db = const FoodDb([], []);
  Map<String, Food> foods = {};
  List<Recipe> _recipes = [];
  Map<String, Recipe> _recipesById = {};
  MealPrepPrefs mealPrepPrefs = const MealPrepPrefs();
  final Map<String, Workout> _workouts = {};
  final Map<String, WeekMealPlan> _mealPlans = {};
  List<String> mealPlanWarnings = [];

  DateTime selectedWeek = mondayOf(DateTime.now());

  // --- Inizializzazione ---------------------------------------------------

  /// [testUserId] simula un utente collegato nei test (senza Supabase).
  Future<void> init({
    LocalStore? testStore,
    FoodDb? db,
    String? testUserId,
  }) async {
    _db = db ?? await FoodDb.load();
    _testMode = testStore != null;
    _testUserId = testUserId;
    if (testStore != null) {
      store = testStore;
    } else {
      final dir = await getApplicationSupportDirectory();
      await Directory(dir.path).create(recursive: true);
      store = LocalStore.open(p.join(dir.path, 'traincal.db'));
    }
    secrets = Secrets(store);
    cloud = SupabaseSync(store);
    if (testStore == null) await secrets.load();
    _loadFromStore();

    if (testStore != null) {
      await _onUserChanged(testUserId, initial: true);
    } else {
      try {
        await cloud.configure(supabaseUrl, supabaseKey);
      } catch (e) {
        lastError = 'Supabase: $e';
      }
      cloud.onUserChanged = (u) => _onUserChanged(u?.id);
      await _onUserChanged(cloud.user?.id, initial: true);
    }
    ready = true;
    notifyListeners();

    if (testStore == null) {
      unawaited(syncAll());
      _timer = Timer.periodic(const Duration(minutes: 15), (_) => syncAll());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadFromStore() {
    final pj = store.get(Collections.profile, 'me');
    profile = pj == null ? const UserProfile() : UserProfile.fromJson(pj);

    plans = store.all(Collections.plans).map(NutritionPlan.fromJson).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    foods = {for (final f in _db.foods) f.id: f};
    for (final j in store.all(Collections.foods)) {
      final f = Food.fromJson(j);
      foods[f.id] = f;
    }

    final custom = store.all(Collections.recipes).map(Recipe.fromJson).toList();
    final customIds = custom.map((r) => r.id).toSet();
    recipes = [
      ..._db.recipes.where((r) => !customIds.contains(r.id)),
      ...custom,
    ]..sort((a, b) => a.name.compareTo(b.name));

    final mp = store.get(Collections.prefs, 'mealprep');
    mealPrepPrefs = mp == null
        ? const MealPrepPrefs()
        : MealPrepPrefs.fromJson(mp);

    _workouts
      ..clear()
      ..addEntries(
        store
            .all(Collections.workoutCache)
            .map(Workout.fromJson)
            .map((w) => MapEntry(w.id, w)),
      );

    _mealPlans
      ..clear()
      ..addEntries(
        store
            .all(Collections.mealPlans)
            .map(WeekMealPlan.fromJson)
            .map((m) => MapEntry(m.id, m)),
      );

    final s = store.getKv('last_intervals_sync');
    lastIntervalsSync = s == null ? null : DateTime.tryParse(s);
  }

  // --- Getter derivati ----------------------------------------------------

  NutritionPlan? get activePlan => plans.where((p) => p.active).firstOrNull;

  List<Recipe> get recipes => _recipes;

  set recipes(List<Recipe> v) {
    _recipes = v;
    _recipesById = {for (final r in v) r.id: r};
  }

  Map<String, Recipe> get recipesById => _recipesById;

  List<DateTime> get weekDays =>
      List.generate(7, (i) => selectedWeek.add(Duration(days: i)));

  /// Gli allenamenti vengono da intervals.icu, la cui API key è legata
  /// all'account: senza login non ce ne sono.
  List<Workout> get workouts => loggedIn
      ? (_workouts.values.toList()..sort((a, b) => a.date.compareTo(b.date)))
      : const [];

  List<Workout> workoutsBetween(DateTime from, DateTime to) => workouts
      .where((w) => !w.day.isBefore(from) && !w.day.isAfter(to))
      .toList();

  List<DayEnergy> get weekEnergy => EnergyCalculator.computeDays(
    days: weekDays,
    workouts: workoutsBetween(weekDays.first, weekDays.last),
    profile: profile,
    plan: activePlan,
  );

  WeekMealPlan? get weekMealPlan => loggedIn
      ? _mealPlans[selectedWeek.toIso8601String().substring(0, 10)]
      : null;

  /// Ricettario più le ricette generate per il piano della settimana
  /// (combinazioni di componenti), per visualizzare menu e preparazione.
  Map<String, Recipe> get planRecipesById {
    final extra = weekMealPlan?.generatedRecipes ?? const [];
    if (extra.isEmpty) return recipesById;
    return {...recipesById, for (final r in extra) r.id: r};
  }

  ShoppingList? get shoppingList {
    final plan = weekMealPlan;
    if (plan == null) return null;
    return ShoppingList.fromPlan(plan, planRecipesById, foods);
  }

  MealPlanner get planner => MealPlanner(
    foods: foods,
    recipes: recipes,
    extraRecipes: weekMealPlan?.generatedRecipes ?? const [],
  );

  bool get intervalsConfigured =>
      loggedIn && (secrets[Secrets.intervalsApiKey] ?? '').isNotEmpty;

  // --- Account ------------------------------------------------------------

  bool _testMode = false;
  String? _testUserId;
  String? _currentUser;
  static const _keyOwnerKv = 'intervals_key_owner';

  /// Utente collegato (Supabase); null se non si è fatto il login.
  String? get userId => _testMode ? _testUserId : cloud.user?.id;

  bool get loggedIn => userId != null;

  /// Applica le regole legate all'account quando cambia l'utente: senza
  /// login spariscono API key, allenamenti e menu; con un altro utente la
  /// chiave del precedente viene scartata.
  Future<void> _onUserChanged(String? id, {bool initial = false}) async {
    if (!initial && id == _currentUser) return;
    _currentUser = id;
    // L'interfaccia segue subito il nuovo stato; la pulizia (portachiavi,
    // database locale) può richiedere qualche istante.
    notifyListeners();
    if (id == null) {
      await _clearAccountData();
    } else {
      final owner = store.getKv(_keyOwnerKv);
      final hasKey = (secrets[Secrets.intervalsApiKey] ?? '').isNotEmpty;
      if (owner == null && hasKey) {
        // Chiave inserita prima di questa regola: la assegna all'utente.
        store.setKv(_keyOwnerKv, id);
      } else if (owner != null && owner != id) {
        await _clearIntervalsKey();
      }
    }
    notifyListeners();
    if (!initial && id != null && !_testMode) unawaited(syncAll());
  }

  Future<void> _clearIntervalsKey() async {
    await secrets.set(Secrets.intervalsApiKey, null);
    await secrets.set(Secrets.intervalsAthleteId, null);
    store.setKv(_keyOwnerKv, null);
  }

  /// Rimuove da questo dispositivo i dati legati all'account: API key,
  /// allenamenti in cache e menu (che restano sul server, se sincronizzati).
  Future<void> _clearAccountData() async {
    await _clearIntervalsKey();
    store.purge(Collections.credentials);
    store.purge(Collections.workoutCache);
    store.purge(Collections.mealPlans);
    store.setKv('last_intervals_sync', null);
    _workouts.clear();
    _mealPlans.clear();
    mealPlanWarnings = [];
    lastIntervalsSync = null;
  }

  @visibleForTesting
  Future<void> debugSetUser(String? id) async {
    _testUserId = id;
    await _onUserChanged(id);
  }

  bool get claudeConfigured =>
      (secrets[Secrets.anthropicApiKey] ?? '').isNotEmpty;

  IntervalsClient _intervals() {
    final key = secrets[Secrets.intervalsApiKey];
    if (key == null) {
      throw IntervalsException('configura la API key nelle impostazioni');
    }
    return IntervalsClient(
      apiKey: key,
      athleteId: secrets[Secrets.intervalsAthleteId] ?? '0',
    );
  }

  void selectWeek(DateTime anyDay) {
    selectedWeek = mondayOf(anyDay);
    mealPlanWarnings = [];
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  // --- Sincronizzazione ---------------------------------------------------

  Future<void> syncAll() async {
    if (syncing) return;
    syncing = true;
    lastError = null;
    notifyListeners();
    final errors = <String>[];
    // Prima Supabase: se la API key di intervals.icu è salvata nell'account,
    // un dispositivo appena collegato la riceve e scarica gli allenamenti
    // nello stesso giro.
    if (cloud.user != null) {
      try {
        final changed = await cloud.sync();
        if (changed > 0) _loadFromStore();
        await applySyncedCredentials();
        lastCloudSync = DateTime.now();
      } catch (e) {
        errors.add('Supabase: $e');
      }
    }
    if (intervalsConfigured) {
      try {
        await _syncIntervals();
      } catch (e) {
        errors.add(e.toString());
      }
    }
    lastError = errors.isEmpty ? null : errors.join('\n');
    syncing = false;
    notifyListeners();
  }

  static const _intervalsCredentials = 'intervals';

  /// Se l'utente ha salvato la API key di intervals.icu nel suo account,
  /// la porta su questo dispositivo. Non carica mai nulla sul server: il
  /// salvataggio nell'account è sempre esplicito
  /// ([setIntervalsKeyInAccount]).
  @visibleForTesting
  Future<void> applySyncedCredentials() async {
    final id = userId;
    if (id == null) return;
    final rec = store.get(Collections.credentials, _intervalsCredentials);
    final key = rec?['apiKey'] as String? ?? '';
    if (key.isEmpty) return;
    final athlete = rec?['athleteId'] as String? ?? '0';
    if (key != secrets[Secrets.intervalsApiKey]) {
      await secrets.set(Secrets.intervalsApiKey, key);
    }
    if (athlete != (secrets[Secrets.intervalsAthleteId] ?? '0')) {
      await secrets.set(Secrets.intervalsAthleteId, athlete);
    }
    store.setKv(_keyOwnerKv, id);
  }

  /// La API key di questo dispositivo è salvata anche nell'account.
  bool get intervalsKeyInAccount =>
      (store.get(Collections.credentials, _intervalsCredentials)?['apiKey']
                  as String? ??
              '')
          .isNotEmpty;

  /// Salva (o toglie) esplicitamente la API key nell'account, così gli altri
  /// dispositivi la ricevono al login. Togliendola dall'account resta su
  /// questo dispositivo.
  Future<void> setIntervalsKeyInAccount(bool save) async {
    if (!loggedIn) throw StateError('Accedi al tuo account');
    final key = save ? secrets[Secrets.intervalsApiKey] ?? '' : '';
    if (save && key.isEmpty) {
      throw StateError('Prima salva una API key di intervals.icu');
    }
    _putIntervalsCredentials(key, secrets[Secrets.intervalsAthleteId] ?? '0');
    _changed();
  }

  void _putIntervalsCredentials(String apiKey, String athleteId) => store.put(
    Collections.credentials,
    _intervalsCredentials,
    {'apiKey': apiKey, 'athleteId': athleteId},
  );

  Future<void> _syncIntervals() async {
    final client = _intervals();
    try {
      final today = DateTime.now();
      // Finestra: 4 settimane indietro, 6 avanti, più la settimana scelta.
      var from = mondayOf(today).subtract(const Duration(days: 28));
      var to = mondayOf(today).add(const Duration(days: 48));
      if (selectedWeek.isBefore(from)) from = selectedWeek;
      final weekEnd = selectedWeek.add(const Duration(days: 6));
      if (weekEnd.isAfter(to)) to = weekEnd;

      final results = await Future.wait([
        client.plannedWorkouts(from, to),
        client.activities(from, to),
      ]);
      _workouts.removeWhere(
        (_, w) => !w.day.isBefore(from) && !w.day.isAfter(to),
      );
      for (final w in [...results[0], ...results[1]]) {
        _workouts[w.id] = w;
      }
      store.replaceAll(Collections.workoutCache, {
        for (final w in _workouts.values) w.id: w.toJson(),
      });

      if (profile.syncWeightFromIntervals) {
        final wellness = await client.wellness(
          today.subtract(const Duration(days: 30)),
          today,
        );
        final latest = wellness
            .where((w) => w.weight != null && w.weight! > 0)
            .fold<WellnessDay?>(
              null,
              (a, b) => a == null || b.date.isAfter(a.date) ? b : a,
            );
        if (latest != null && latest.weight != profile.weightKg) {
          saveProfile(profile.copyWith(weightKg: latest.weight));
        }
      }
      lastIntervalsSync = DateTime.now();
      store.setKv('last_intervals_sync', lastIntervalsSync!.toIso8601String());
    } finally {
      client.close();
    }
  }

  Future<String> testIntervals() async {
    final client = _intervals();
    try {
      final a = await client.athlete();
      return 'Connesso come ${a['name'] ?? a['id']}';
    } finally {
      client.close();
    }
  }

  Future<void> saveWorkout(WorkoutDraft d) async {
    final client = _intervals();
    try {
      final w = d.eventId == null
          ? await client.createWorkout(d)
          : await client.updateWorkout(d);
      _workouts[w.id] = w;
      store.replaceAll(Collections.workoutCache, {
        for (final w in _workouts.values) w.id: w.toJson(),
      });
      notifyListeners();
    } finally {
      client.close();
    }
  }

  Future<void> deleteWorkout(Workout w) async {
    if (w.eventId == null) return;
    final client = _intervals();
    try {
      await client.deleteWorkout(w.eventId!);
      _workouts.remove(w.id);
      store.replaceAll(Collections.workoutCache, {
        for (final w in _workouts.values) w.id: w.toJson(),
      });
      notifyListeners();
    } finally {
      client.close();
    }
  }

  /// Scrive i target dei giorni della settimana come note su intervals.icu.
  Future<int> publishWeekTargets() async {
    final client = _intervals();
    try {
      var n = 0;
      for (final d in weekEnergy) {
        final fueling = d.workouts
            .where((w) => w.fuelingCarbsPerHour > 0)
            .map(
              (w) =>
                  '${w.workout.name}: ${w.fuelingCarbsPerHour} g/h di carboidrati durante la seduta',
            )
            .join('\n');
        await client.upsertNutritionNote(d.date, d.target, extra: fueling);
        n++;
      }
      return n;
    } finally {
      client.close();
    }
  }

  // --- Profilo e piani ----------------------------------------------------

  void _changed() {
    notifyListeners();
    if (cloud.user != null) {
      // Push in background, senza bloccare l'interfaccia.
      unawaited(
        cloud.sync().then(
          (_) => lastCloudSync = DateTime.now(),
          onError: (e) => debugPrint('Sync Supabase fallita: $e'),
        ),
      );
    }
  }

  void saveProfile(UserProfile p) {
    profile = p;
    store.put(Collections.profile, 'me', p.toJson());
    _changed();
  }

  NutritionPlan newPlan(Goal goal) => NutritionPlan(
    id: _uuid.v4(),
    name: goal.label,
    goal: goal,
    startDate: DateTime.now(),
    ratePerWeek: goal.defaultRate,
    proteinPerKg: goal.defaultProteinPerKg,
  );

  void savePlan(NutritionPlan plan) {
    store.put(Collections.plans, plan.id, plan.toJson());
    plans = [...plans.where((p) => p.id != plan.id), plan]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    if (plan.active) activatePlan(plan.id);
    _changed();
  }

  void activatePlan(String id) {
    plans = [
      for (final p in plans)
        if (p.active != (p.id == id))
          () {
            final updated = p.copyWith(active: p.id == id);
            store.put(Collections.plans, p.id, updated.toJson());
            return updated;
          }()
        else
          p,
    ];
    _changed();
  }

  void deletePlan(String id) {
    store.delete(Collections.plans, id);
    plans = plans.where((p) => p.id != id).toList();
    _changed();
  }

  // --- Ricette e alimenti -------------------------------------------------

  void saveFood(Food f) {
    store.put(Collections.foods, f.id, f.toJson());
    foods = {...foods, f.id: f};
    _changed();
  }

  void saveRecipe(Recipe r) {
    store.put(Collections.recipes, r.id, r.toJson());
    recipes = [...recipes.where((x) => x.id != r.id), r]
      ..sort((a, b) => a.name.compareTo(b.name));
    _rebalanceDaysUsing(r.id);
    _changed();
  }

  /// Dopo la modifica di una ricetta (ingredienti o porzione fissa), le
  /// giornate del menu che la usano si ribilanciano.
  void _rebalanceDaysUsing(String recipeId) {
    final plan = weekMealPlan;
    if (plan == null) return;
    if (!plan.days.any((d) => d.meals.any((m) => m.recipeId == recipeId))) {
      return;
    }
    final p = planner;
    _savePlanDays(plan, [
      for (final d in plan.days)
        d.meals.any((m) => m.recipeId == recipeId) ? p.rebalanceDay(d) : d,
    ]);
  }

  void deleteRecipe(Recipe r) {
    store.delete(Collections.recipes, r.id);
    _loadFromStore();
    _changed();
  }

  String newRecipeId() => 'r_${_uuid.v4().substring(0, 8)}';
  String newFoodId() => 'f_${_uuid.v4().substring(0, 8)}';

  void setRecipeExcluded(String id, bool excluded) {
    final ids = {...mealPrepPrefs.excludedRecipeIds};
    excluded ? ids.add(id) : ids.remove(id);
    saveMealPrepPrefs(
      mealPrepPrefs.copyWith(
        excludedRecipeIds: ids,
        pinnedRecipeIds: excluded
            ? ({...mealPrepPrefs.pinnedRecipeIds}..remove(id))
            : null,
      ),
    );
  }

  /// Fissa una colazione o uno spuntino: il generatore la usa sempre.
  /// Una ricetta fissata non può essere esclusa, e viceversa.
  void setRecipePinned(String id, bool pinned) {
    final ids = {...mealPrepPrefs.pinnedRecipeIds};
    final excluded = {...mealPrepPrefs.excludedRecipeIds};
    if (pinned) {
      ids.add(id);
      excluded.remove(id);
    } else {
      ids.remove(id);
    }
    saveMealPrepPrefs(
      mealPrepPrefs.copyWith(pinnedRecipeIds: ids, excludedRecipeIds: excluded),
    );
  }

  void saveMealPrepPrefs(MealPrepPrefs prefs) {
    mealPrepPrefs = prefs;
    store.put(Collections.prefs, 'mealprep', prefs.toJson());
    _changed();
  }

  Future<GeneratedRecipes> generateRecipes(RecipeRequest req) async {
    final key = secrets[Secrets.anthropicApiKey];
    if (key == null) {
      throw ClaudeException('configura la API key di Anthropic');
    }
    final client = ClaudeClient(
      apiKey: key,
      model: secrets[Secrets.anthropicModel],
    );
    try {
      return await client.generateRecipes(
        req,
        foods,
        when: selectedWeek.add(const Duration(days: 3)),
      );
    } finally {
      client.close();
    }
  }

  void saveGenerated(GeneratedRecipes g, Iterable<Recipe> selected) {
    final used = selected
        .expand((r) => r.ingredients)
        .map((i) => i.foodId)
        .toSet();
    for (final f in g.newFoods.where((f) => used.contains(f.id))) {
      saveFood(f);
    }
    for (final r in selected) {
      saveRecipe(r);
    }
  }

  // --- Meal prep ----------------------------------------------------------

  void generateMealPlan({int? seed}) {
    if (!loggedIn) return;
    final result = planner.generate(
      weekStart: selectedWeek,
      days: weekEnergy,
      mealsPerDay: profile.mealsPerDay,
      options: MealPlanOptions(
        prepSessions: mealPrepPrefs.prepSessions,
        style: mealPrepPrefs.style,
        mainVariety: mealPrepPrefs.mainVariety,
        breakfastVariety: mealPrepPrefs.breakfastVariety,
        snackVariety: mealPrepPrefs.snackVariety,
        excludedRecipeIds: mealPrepPrefs.excludedRecipeIds,
        pinnedRecipeIds: mealPrepPrefs.pinnedRecipeIds,
        freeMeals: freeMealsFor(selectedWeek),
        removedMeals: removedMealsFor(selectedWeek),
        lockedDays: {
          for (final (i, d) in (weekMealPlan?.days ?? const []).indexed)
            if (d.locked) i: d,
        },
        lockedMeals: {
          for (final (i, d) in (weekMealPlan?.days ?? const []).indexed)
            if (!d.locked && d.meals.any((m) => m.recipeLocked))
              i: [
                for (final m in d.meals)
                  if (m.recipeLocked) m,
              ],
        },
        previous: weekMealPlan,
        seed: seed ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _mealPlans[result.plan.id] = result.plan;
    mealPlanWarnings = result.warnings;
    store.put(Collections.mealPlans, result.plan.id, result.plan.toJson());
    _changed();
  }

  // --- Pasti liberi, eliminati e giorni bloccati ---------------------------

  // Preferenze per settimana: { "2026-11-02": ["4:lunch", "4:dinner"] }.
  static const _freeMealsId = 'freemeals';
  static const _removedMealsId = 'removedmeals';

  static String _weekId(DateTime week) =>
      mondayOf(week).toIso8601String().substring(0, 10);

  Map<int, Set<MealSlot>> _slotsFor(String prefId, DateTime week) {
    final all = store.get(Collections.prefs, prefId) ?? const {};
    final list = (all[_weekId(week)] as List?) ?? const [];
    final out = <int, Set<MealSlot>>{};
    for (final e in list.cast<String>()) {
      final [day, slot] = e.split(':');
      final s = MealSlot.values.asNameMap()[slot];
      if (s != null) out.putIfAbsent(int.parse(day), () => {}).add(s);
    }
    return out;
  }

  void _setSlots(String prefId, int day, Iterable<MealSlot> slots, bool on) {
    final all = {...?store.get(Collections.prefs, prefId)};
    final id = _weekId(selectedWeek);
    final set = {...((all[id] as List?) ?? const []).cast<String>()};
    for (final slot in slots) {
      final key = '$day:${slot.name}';
      on ? set.add(key) : set.remove(key);
    }
    if (set.isEmpty) {
      all.remove(id);
    } else {
      all[id] = (set.toList()..sort());
    }
    store.put(Collections.prefs, prefId, all);
  }

  /// Pasti liberi della settimana: indice del giorno (0 = lunedì) → pasti.
  Map<int, Set<MealSlot>> freeMealsFor(DateTime week) =>
      _slotsFor(_freeMealsId, week);

  /// Pasti eliminati della settimana: indice del giorno → pasti.
  Map<int, Set<MealSlot>> removedMealsFor(DateTime week) =>
      _slotsFor(_removedMealsId, week);

  MealStatus mealStatus(int day, MealSlot slot) {
    if (freeMealsFor(selectedWeek)[day]?.contains(slot) ?? false) {
      return MealStatus.free;
    }
    if (removedMealsFor(selectedWeek)[day]?.contains(slot) ?? false) {
      return MealStatus.removed;
    }
    return MealStatus.planned;
  }

  /// Imposta lo stato dei pasti di un giorno della settimana selezionata.
  /// La scelta vale per le prossime generazioni e, se il menu esiste già,
  /// si applica subito: un pasto libero o eliminato sparisce (gli eliminati
  /// ridistribuiscono le calorie), uno ripristinato riceve una ricetta.
  void setMealStatus(int day, Iterable<MealSlot> slots, MealStatus status) {
    _setSlots(_freeMealsId, day, slots, status == MealStatus.free);
    _setSlots(_removedMealsId, day, slots, status == MealStatus.removed);
    final plan = weekMealPlan;
    if (plan != null && day < plan.days.length) {
      final days = [...plan.days];
      var d = days[day];
      for (final slot in slots) {
        d = _applyStatus(plan, d, slot, status);
      }
      days[day] = planner.rebalanceDay(d);
      _savePlanDays(plan, days);
    }
    _changed();
  }

  DayMealPlan _applyStatus(
    WeekMealPlan plan,
    DayMealPlan d,
    MealSlot slot,
    MealStatus status,
  ) {
    final free = [...d.freeSlots]..remove(slot);
    final removed = [...d.removedSlots]..remove(slot);
    var meals = [
      for (final m in d.meals)
        if (m.slot != slot) m,
    ];
    switch (status) {
      case MealStatus.free:
        free.add(slot);
      case MealStatus.removed:
        removed.add(slot);
      case MealStatus.planned:
        final existing = d.meals.where((m) => m.slot == slot).firstOrNull;
        final recipeId = existing?.recipeId ?? _restoreRecipe(plan, d, slot);
        if (recipeId != null) meals = [...meals, MealEntry(slot, recipeId, 1)];
    }
    int order(MealSlot s) => s.index;
    return d.copyWith(
      meals: meals..sort((a, b) => order(a.slot).compareTo(order(b.slot))),
      freeSlots: free..sort((a, b) => order(a).compareTo(order(b))),
      removedSlots: removed..sort((a, b) => order(a).compareTo(order(b))),
    );
  }

  /// Ricetta per un pasto ripristinato: quella dello stesso pasto nel giorno
  /// più vicino (così la preparazione non cambia), altrimenti una dello
  /// stesso tipo già nel menu, altrimenti la prima adatta del ricettario.
  String? _restoreRecipe(WeekMealPlan plan, DayMealPlan day, MealSlot slot) {
    final index = plan.days.indexOf(day);
    final byDistance = [...plan.days.indexed]
      ..sort((a, b) => (a.$1 - index).abs().compareTo((b.$1 - index).abs()));
    for (final (_, d) in byDistance) {
      final m = d.meals.where((m) => m.slot == slot).firstOrNull;
      if (m != null) return m.recipeId;
    }
    final all = planRecipesById;
    for (final m in plan.days.expand((d) => d.meals)) {
      if (all[m.recipeId]?.type == slot.type) return m.recipeId;
    }
    final excluded = mealPrepPrefs.excludedRecipeIds;
    return recipes
        .where((r) => r.type == slot.type && !excluded.contains(r.id))
        .firstOrNull
        ?.id;
  }

  /// Blocca o sblocca un giorno del menu: i giorni bloccati restano identici
  /// quando si rigenera.
  /// Blocca o sblocca un singolo pasto: rigenerando mantiene la ricetta.
  void setMealLocked(int day, MealSlot slot, bool locked) {
    final plan = weekMealPlan;
    if (plan == null || day >= plan.days.length) return;
    final days = [...plan.days];
    days[day] = days[day].copyWith(
      meals: [
        for (final m in days[day].meals)
          m.slot == slot ? m.copyWith(recipeLocked: locked) : m,
      ],
    );
    _savePlanDays(plan, days);
    _changed();
  }

  void setDayLocked(int day, bool locked) {
    final plan = weekMealPlan;
    if (plan == null || day >= plan.days.length) return;
    final days = [...plan.days];
    days[day] = days[day].copyWith(locked: locked);
    _savePlanDays(plan, days);
    _changed();
  }

  /// Imposta a mano le porzioni di un pasto del menu ([servings] null le
  /// riporta automatiche) e ribilancia gli altri pasti della giornata.
  void setMealServings(DateTime date, MealSlot slot, double? servings) {
    final plan = weekMealPlan;
    if (plan == null) return;
    final p = planner;
    final days = [
      for (final d in plan.days)
        if (d.date != date)
          d
        else
          p.rebalanceDay(
            d.copyWith(
              meals: [
                for (final m in d.meals)
                  m.slot != slot
                      ? m
                      : m.copyWith(
                          servings: servings ?? m.servings,
                          locked: servings != null,
                        ),
              ],
            ),
          ),
    ];
    _savePlanDays(plan, days);
    _changed();
  }

  /// Salva le giornate modificate e ricalcola le sessioni di preparazione
  /// (senza notificare: ci pensa il chiamante).
  void _savePlanDays(WeekMealPlan plan, List<DayMealPlan> days) {
    final updated = plan.copyWith(
      days: days,
      generatedAt: DateTime.now(),
      prepSessions: MealPlanner.buildPrepSessions(
        days,
        MealPlanner.blocksOf(plan),
        plan.combos,
      ),
    );
    _mealPlans[updated.id] = updated;
    store.put(Collections.mealPlans, updated.id, updated.toJson());
  }

  /// Sostituisce una ricetta in tutto il piano della settimana, mantenendo
  /// le kcal dei pasti, e ricalcola le sessioni di preparazione.
  void swapRecipeInPlan(String fromId, String toId) {
    final plan = weekMealPlan;
    if (plan == null) return;
    final all = planRecipesById;
    final ratio =
        all[fromId]!.macrosPerServing(foods).kcal /
        all[toId]!.macrosPerServing(foods).kcal;
    double adj(double s) => ((s * ratio) / 0.25).round() * 0.25;
    final days = [
      for (final d in plan.days)
        d.copyWith(
          meals: [
            for (final m in d.meals)
              m.recipeId == fromId
                  ? m.copyWith(
                      recipeId: toId,
                      servings:
                          all[toId]!.fixedServings ??
                          adj(m.servings).clamp(0.5, 3).toDouble(),
                    )
                  : m,
          ],
        ),
    ];
    _savePlanDays(plan, days);
    _changed();
  }

  // --- Impostazioni -------------------------------------------------------

  /// Salva la API key su questo dispositivo, legata all'utente collegato.
  /// Se l'utente l'aveva già salvata nell'account, aggiorna anche quella.
  Future<void> saveIntervalsSettings(String apiKey, String athleteId) async {
    final id = userId;
    if (id == null) throw StateError('Accedi per collegare intervals.icu');
    final inAccount = intervalsKeyInAccount;
    await secrets.set(Secrets.intervalsApiKey, apiKey);
    await secrets.set(
      Secrets.intervalsAthleteId,
      athleteId.isEmpty ? '0' : athleteId,
    );
    store.setKv(_keyOwnerKv, id);
    if (inAccount) {
      _putIntervalsCredentials(
        secrets[Secrets.intervalsApiKey] ?? '',
        secrets[Secrets.intervalsAthleteId] ?? '0',
      );
    }
    _changed();
  }

  Future<void> saveClaudeSettings(String apiKey, String model) async {
    await secrets.set(Secrets.anthropicApiKey, apiKey);
    await secrets.set(Secrets.anthropicModel, model);
    notifyListeners();
  }

  Future<void> saveSupabaseSettings(String url, String key) async {
    await secrets.set(Secrets.supabaseUrl, url);
    await secrets.set(Secrets.supabaseKey, key);
    await cloud.configure(supabaseUrl, supabaseKey);
    notifyListeners();
  }

  /// Progetto Supabase: quello incluso nell'app se presente, altrimenti
  /// quello inserito a mano nelle impostazioni.
  String? get supabaseUrl => SupabaseConfig.isBuiltIn
      ? SupabaseConfig.url
      : secrets[Secrets.supabaseUrl];

  String? get supabaseKey => SupabaseConfig.isBuiltIn
      ? SupabaseConfig.publishableKey
      : secrets[Secrets.supabaseKey];

  Future<void> cloudSignIn(
    String email,
    String password, {
    bool signUp = false,
  }) async {
    if (signUp) {
      await cloud.signUp(email, password);
    }
    if (cloud.user == null) await cloud.signIn(email, password);
    // I record locali non ancora caricati sono "dirty": il primo sync li
    // invia, mentre quelli remoti più recenti vincono (last-write-wins).
    await syncAll();
  }

  /// Esce dall'account: prima invia le modifiche in sospeso, poi rimuove
  /// da questo dispositivo API key, allenamenti e menu.
  Future<void> cloudSignOut() async {
    try {
      await cloud.sync().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Sync prima del logout fallita: $e');
    }
    try {
      await cloud.signOut();
    } finally {
      await _onUserChanged(null);
    }
  }
}
