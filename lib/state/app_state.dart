import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/food_db.dart';
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
  final int breakfastVariety;
  final int snackVariety;
  final Set<String> excludedRecipeIds;

  const MealPrepPrefs({
    this.prepSessions = 2,
    this.breakfastVariety = 2,
    this.snackVariety = 2,
    this.excludedRecipeIds = const {},
  });

  MealPrepPrefs copyWith({
    int? prepSessions,
    int? breakfastVariety,
    int? snackVariety,
    Set<String>? excludedRecipeIds,
  }) => MealPrepPrefs(
    prepSessions: prepSessions ?? this.prepSessions,
    breakfastVariety: breakfastVariety ?? this.breakfastVariety,
    snackVariety: snackVariety ?? this.snackVariety,
    excludedRecipeIds: excludedRecipeIds ?? this.excludedRecipeIds,
  );

  Map<String, dynamic> toJson() => {
    'prepSessions': prepSessions,
    'breakfastVariety': breakfastVariety,
    'snackVariety': snackVariety,
    'excludedRecipeIds': excludedRecipeIds.toList(),
  };

  factory MealPrepPrefs.fromJson(Map<String, dynamic> j) => MealPrepPrefs(
    prepSessions: (j['prepSessions'] as num?)?.toInt() ?? 2,
    breakfastVariety: (j['breakfastVariety'] as num?)?.toInt() ?? 2,
    snackVariety: (j['snackVariety'] as num?)?.toInt() ?? 2,
    excludedRecipeIds: ((j['excludedRecipeIds'] as List?) ?? const [])
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

  Future<void> init({LocalStore? testStore, FoodDb? db}) async {
    _db = db ?? await FoodDb.load();
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
    ready = true;
    notifyListeners();

    if (testStore == null) {
      try {
        await cloud.configure(
          secrets[Secrets.supabaseUrl],
          secrets[Secrets.supabaseKey],
        );
      } catch (e) {
        lastError = 'Supabase: $e';
      }
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

  List<Workout> get workouts =>
      _workouts.values.toList()..sort((a, b) => a.date.compareTo(b.date));

  List<Workout> workoutsBetween(DateTime from, DateTime to) => workouts
      .where((w) => !w.day.isBefore(from) && !w.day.isAfter(to))
      .toList();

  List<DayEnergy> get weekEnergy => EnergyCalculator.computeDays(
    days: weekDays,
    workouts: workoutsBetween(weekDays.first, weekDays.last),
    profile: profile,
    plan: activePlan,
  );

  WeekMealPlan? get weekMealPlan =>
      _mealPlans[selectedWeek.toIso8601String().substring(0, 10)];

  ShoppingList? get shoppingList {
    final plan = weekMealPlan;
    if (plan == null) return null;
    return ShoppingList.fromPlan(plan, recipesById, foods);
  }

  MealPlanner get planner => MealPlanner(foods: foods, recipes: recipes);

  bool get intervalsConfigured =>
      (secrets[Secrets.intervalsApiKey] ?? '').isNotEmpty;

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
    if (intervalsConfigured) {
      try {
        await _syncIntervals();
      } catch (e) {
        errors.add(e.toString());
      }
    }
    if (cloud.user != null) {
      try {
        final changed = await cloud.sync();
        if (changed > 0) _loadFromStore();
        lastCloudSync = DateTime.now();
      } catch (e) {
        errors.add('Supabase: $e');
      }
    }
    lastError = errors.isEmpty ? null : errors.join('\n');
    syncing = false;
    notifyListeners();
  }

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
    _changed();
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
    saveMealPrepPrefs(mealPrepPrefs.copyWith(excludedRecipeIds: ids));
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
    final result = planner.generate(
      weekStart: selectedWeek,
      days: weekEnergy,
      mealsPerDay: profile.mealsPerDay,
      options: MealPlanOptions(
        prepSessions: mealPrepPrefs.prepSessions,
        breakfastVariety: mealPrepPrefs.breakfastVariety,
        snackVariety: mealPrepPrefs.snackVariety,
        excludedRecipeIds: mealPrepPrefs.excludedRecipeIds,
        seed: seed ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _mealPlans[result.plan.id] = result.plan;
    mealPlanWarnings = result.warnings;
    store.put(Collections.mealPlans, result.plan.id, result.plan.toJson());
    _changed();
  }

  /// Sostituisce una ricetta in tutto il piano della settimana.
  void swapRecipeInPlan(String fromId, String toId) {
    final plan = weekMealPlan;
    if (plan == null) return;
    final from = recipesById[fromId]!;
    final to = recipesById[toId]!;
    final ratio =
        from.macrosPerServing(foods).kcal / to.macrosPerServing(foods).kcal;
    double adj(double s) => ((s * ratio) / 0.25).round() * 0.25;
    final updated = WeekMealPlan(
      weekStart: plan.weekStart,
      generatedAt: DateTime.now(),
      days: [
        for (final d in plan.days)
          DayMealPlan(
            date: d.date,
            target: d.target,
            extras: d.extras,
            meals: [
              for (final m in d.meals)
                m.recipeId == fromId
                    ? MealEntry(m.slot, toId, adj(m.servings).clamp(0.5, 3))
                    : m,
            ],
          ),
      ],
      prepSessions: [
        for (final s in plan.prepSessions)
          s.recipeId == fromId
              ? PrepSession(
                  date: s.date,
                  recipeId: toId,
                  totalServings: adj(s.totalServings),
                  coversDays: s.coversDays,
                )
              : s,
      ],
    );
    _mealPlans[updated.id] = updated;
    store.put(Collections.mealPlans, updated.id, updated.toJson());
    _changed();
  }

  // --- Impostazioni -------------------------------------------------------

  Future<void> saveIntervalsSettings(String apiKey, String athleteId) async {
    await secrets.set(Secrets.intervalsApiKey, apiKey);
    await secrets.set(
      Secrets.intervalsAthleteId,
      athleteId.isEmpty ? '0' : athleteId,
    );
    notifyListeners();
  }

  Future<void> saveClaudeSettings(String apiKey, String model) async {
    await secrets.set(Secrets.anthropicApiKey, apiKey);
    await secrets.set(Secrets.anthropicModel, model);
    notifyListeners();
  }

  Future<void> saveSupabaseSettings(String url, String key) async {
    await secrets.set(Secrets.supabaseUrl, url);
    await secrets.set(Secrets.supabaseKey, key);
    await cloud.configure(
      secrets[Secrets.supabaseUrl],
      secrets[Secrets.supabaseKey],
    );
    notifyListeners();
  }

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

  Future<void> cloudSignOut() async {
    await cloud.signOut();
    notifyListeners();
  }
}
