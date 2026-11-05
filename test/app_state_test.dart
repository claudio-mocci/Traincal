import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:traincal/data/local_store.dart';
import 'package:traincal/data/secrets.dart';
import 'package:traincal/models/meal_plan.dart';
import 'package:traincal/models/recipe.dart';
import 'package:traincal/services/meal_planner.dart';
import 'package:traincal/state/app_state.dart';

import 'test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> newState({
    String? user = 'utente-1',
    LocalStore? store,
  }) async {
    final s = AppState();
    await s.init(
      testStore: store ?? LocalStore.inMemory(),
      db: testDb,
      testUserId: user,
    );
    return s;
  }

  MealEntry lunchOf(AppState s, int day) => s.weekMealPlan!.days[day].meals
      .firstWhere((m) => m.slot == MealSlot.lunch);

  test('porzioni a mano: blocco, ribilanciamento e preparazione', () async {
    final s = await newState();
    s.generateMealPlan(seed: 3);
    final day = s.weekMealPlan!.days[1];
    final lunch = lunchOf(s, 1);
    double prepTotal(String id) => s.weekMealPlan!.prepSessions
        .where((p) => p.recipeId == id)
        .fold(0.0, (a, p) => a + p.totalServings);
    final before = prepTotal(lunch.recipeId);

    s.setMealServings(day.date, MealSlot.lunch, lunch.servings + 1);
    expect(lunchOf(s, 1).servings, lunch.servings + 1);
    expect(lunchOf(s, 1).locked, isTrue);
    expect(prepTotal(lunch.recipeId), closeTo(before + 1, 0.001));
    // Gli altri giorni non cambiano.
    expect(lunchOf(s, 0).locked, isFalse);

    s.setMealServings(day.date, MealSlot.lunch, null);
    expect(lunchOf(s, 1).locked, isFalse);
    expect(lunchOf(s, 1).servings, lunch.servings);
  });

  test('ricetta modificata con porzione fissa: il menu si aggiorna', () async {
    final s = await newState();
    s.generateMealPlan(seed: 5);
    final b = s.weekMealPlan!.days[0].meals.firstWhere(
      (m) => m.slot == MealSlot.breakfast,
    );
    final recipe = s.recipesById[b.recipeId]!;
    s.saveRecipe(recipe.copyWith(fixedServings: 2));
    for (final d in s.weekMealPlan!.days) {
      for (final m in d.meals.where((m) => m.recipeId == recipe.id)) {
        expect(m.servings, 2);
      }
    }
  });

  test('fissare ed escludere si escludono a vicenda', () async {
    final s = await newState();
    final id = s.recipes.firstWhere((r) => r.type == MealType.snack).id;
    s.setRecipeExcluded(id, true);
    s.setRecipePinned(id, true);
    expect(s.mealPrepPrefs.pinnedRecipeIds, contains(id));
    expect(s.mealPrepPrefs.excludedRecipeIds, isNot(contains(id)));
    s.setRecipeExcluded(id, true);
    expect(s.mealPrepPrefs.pinnedRecipeIds, isNot(contains(id)));

    s.setRecipePinned(id, true);
    final prefs = MealPrepPrefs.fromJson(s.mealPrepPrefs.toJson());
    expect(prefs.pinnedRecipeIds, {id});
    s.generateMealPlan(seed: 1);
    final used = s.weekMealPlan!.days
        .expand((d) => d.meals)
        .map((m) => m.recipeId);
    expect(used, contains(id));
  });

  StoredRecord remoteKey(String key, {int offset = 0}) => StoredRecord(
    Collections.credentials,
    'intervals',
    {'apiKey': key, 'athleteId': '0'},
    DateTime.now().millisecondsSinceEpoch + offset,
    false,
  );

  group('API key di intervals.icu legata al login', () {
    test('senza login niente chiave, allenamenti e menu', () async {
      final s = await newState(user: null);
      expect(s.loggedIn, isFalse);
      expect(
        () => s.saveIntervalsSettings('k', '0'),
        throwsA(isA<StateError>()),
      );
      s.generateMealPlan(seed: 1);
      expect(s.weekMealPlan, isNull);
      expect(s.workouts, isEmpty);
      expect(s.intervalsConfigured, isFalse);
    });

    test(
      'salvata solo in locale finché non la si mette nell\'account',
      () async {
        final s = await newState();
        await s.saveIntervalsSettings('chiave-1', 'i123');
        expect(s.intervalsConfigured, isTrue);
        expect(s.store.get(Collections.credentials, 'intervals'), isNull);
        expect(s.intervalsKeyInAccount, isFalse);
        expect(
          s.store.dirtyRecords().map((r) => r.collection),
          isNot(contains(Collections.credentials)),
        );

        await s.setIntervalsKeyInAccount(true);
        expect(s.intervalsKeyInAccount, isTrue);
        expect(s.store.get(Collections.credentials, 'intervals'), {
          'apiKey': 'chiave-1',
          'athleteId': 'i123',
        });
        // Una volta nell'account, la chiave aggiornata segue.
        await s.saveIntervalsSettings('chiave-2', 'i123');
        expect(
          s.store.get(Collections.credentials, 'intervals')!['apiKey'],
          'chiave-2',
        );
        // Tolta dall'account, resta su questo dispositivo.
        await s.setIntervalsKeyInAccount(false);
        expect(s.intervalsKeyInAccount, isFalse);
        expect(s.secrets[Secrets.intervalsApiKey], 'chiave-2');
      },
    );

    test('una chiave locale non viene mai caricata da sola', () async {
      final s = await newState();
      await s.saveIntervalsSettings('locale', '0');
      await s.applySyncedCredentials();
      expect(s.store.get(Collections.credentials, 'intervals'), isNull);
    });

    test('al login arriva la chiave salvata nell\'account', () async {
      final s = await newState();
      expect(s.intervalsConfigured, isFalse);
      s.store.applyRemote(remoteKey('dal-pc'));
      await s.applySyncedCredentials();
      expect(s.secrets[Secrets.intervalsApiKey], 'dal-pc');
      expect(s.intervalsConfigured, isTrue);
    });

    test('al logout spariscono chiave, allenamenti e menu', () async {
      final s = await newState();
      await s.saveIntervalsSettings('chiave', '0');
      s.store.applyRemote(remoteKey('chiave'));
      s.generateMealPlan(seed: 2);
      s.store.put(Collections.workoutCache, 'e1', {'id': 'e1'});
      expect(s.weekMealPlan, isNotNull);

      await s.debugSetUser(null);
      expect(s.loggedIn, isFalse);
      expect(s.secrets[Secrets.intervalsApiKey], isNull);
      expect(s.weekMealPlan, isNull);
      expect(s.store.all(Collections.mealPlans), isEmpty);
      expect(s.store.all(Collections.workoutCache), isEmpty);
      expect(s.store.all(Collections.credentials), isEmpty);
      // La cancellazione locale non si propaga al server.
      expect(
        s.store.dirtyRecords().where(
          (r) => r.deleted && r.collection == Collections.mealPlans,
        ),
        isEmpty,
      );
    });

    test(
      'con un altro utente la chiave del precedente viene scartata',
      () async {
        final s = await newState(user: 'utente-1');
        await s.saveIntervalsSettings('di-utente-1', '0');
        await s.debugSetUser('utente-2');
        expect(s.secrets[Secrets.intervalsApiKey], isNull);
      },
    );

    test('chiave preesistente senza proprietario: adottata al login', () async {
      // Chiave inserita prima di questa regola (nessun proprietario).
      final s = await newState(user: null);
      await s.secrets.set(Secrets.intervalsApiKey, 'vecchia');
      expect(s.intervalsConfigured, isFalse, reason: 'senza login non vale');
      await s.debugSetUser('utente-1');
      expect(s.intervalsConfigured, isTrue);
      // Il proprietario ora è utente-1: un altro utente non la eredita.
      await s.debugSetUser('utente-2');
      expect(s.intervalsConfigured, isFalse);
    });
  });

  group('pasti liberi, eliminati e giorni bloccati', () {
    MealEntry? meal(AppState s, int day, MealSlot slot) => s
        .weekMealPlan!
        .days[day]
        .meals
        .where((m) => m.slot == slot)
        .firstOrNull;

    double prepServings(AppState s, String id) => s.weekMealPlan!.prepSessions
        .where((p) => p.recipeId == id)
        .fold(0.0, (a, p) => a + p.totalServings);

    double eatenServings(AppState s, String id) => s.weekMealPlan!.days
        .expand((d) => d.meals)
        .where((m) => m.recipeId == id)
        .fold(0.0, (a, m) => a + m.servings);

    test('scelti prima di generare: per settimana e sincronizzati', () async {
      final s = await newState();
      s.setMealStatus(4, [MealSlot.lunch, MealSlot.dinner], MealStatus.free);
      s.setMealStatus(5, [MealSlot.afternoonSnack], MealStatus.removed);
      expect(s.freeMealsFor(s.selectedWeek), {
        4: {MealSlot.lunch, MealSlot.dinner},
      });
      expect(s.removedMealsFor(s.selectedWeek), {
        5: {MealSlot.afternoonSnack},
      });
      expect(
        s.store.dirtyRecords().map((r) => r.collection),
        contains(Collections.prefs),
      );
      expect(
        s.freeMealsFor(s.selectedWeek.add(const Duration(days: 7))),
        isEmpty,
      );
      s.generateMealPlan(seed: 4);
      expect(s.weekMealPlan!.days[4].freeSlots, [
        MealSlot.lunch,
        MealSlot.dinner,
      ]);
      expect(s.weekMealPlan!.days[5].removedSlots, [MealSlot.afternoonSnack]);
    });

    test('libero e ripristinato sul menu esistente', () async {
      final s = await newState();
      s.generateMealPlan(seed: 4);
      final dinner = meal(s, 0, MealSlot.dinner)!.recipeId;

      s.setMealStatus(0, [MealSlot.dinner], MealStatus.free);
      expect(meal(s, 0, MealSlot.dinner), isNull);
      expect(s.weekMealPlan!.days[0].freeSlots, [MealSlot.dinner]);
      expect(prepServings(s, dinner), closeTo(eatenServings(s, dinner), 1e-9));

      // Ripristino: torna la ricetta dello stesso pasto del giorno vicino.
      s.setMealStatus(0, [MealSlot.dinner], MealStatus.planned);
      expect(s.weekMealPlan!.days[0].freeSlots, isEmpty);
      final restored = meal(s, 0, MealSlot.dinner)!.recipeId;
      expect(restored, meal(s, 1, MealSlot.dinner)!.recipeId);
      expect(
        prepServings(s, restored),
        closeTo(eatenServings(s, restored), 1e-9),
      );
      expect(s.freeMealsFor(s.selectedWeek), isEmpty);
    });

    test('eliminato: le calorie passano agli altri pasti', () async {
      final s = await newState();
      s.generateMealPlan(seed: 6);
      final before = s.weekMealPlan!.days[2];
      final p = s.planner;
      s.setMealStatus(2, [MealSlot.afternoonSnack], MealStatus.removed);
      final after = s.weekMealPlan!.days[2];
      expect(after.removedSlots, [MealSlot.afternoonSnack]);
      expect(after.meals.length, before.meals.length - 1);
      // Stesso obiettivo coperto con un pasto in meno.
      expect(MealPlanner.plannedTarget(after).kcal, after.target.kcal);
      final total = p.dayTotal(after);
      expect(
        (total.kcal - after.target.kcal).abs() / after.target.kcal,
        lessThan(0.10),
      );
      final grew = after.meals.any(
        (m) =>
            m.servings >
            before.meals.firstWhere((b) => b.slot == m.slot).servings,
      );
      expect(grew, isTrue);

      s.setMealStatus(2, [MealSlot.afternoonSnack], MealStatus.planned);
      expect(meal(s, 2, MealSlot.afternoonSnack), isNotNull);
      expect(s.weekMealPlan!.days[2].removedSlots, isEmpty);
    });

    test('i giorni bloccati restano uguali quando si rigenera', () async {
      final s = await newState();
      s.setMealStatus(1, [MealSlot.dinner], MealStatus.free);
      s.generateMealPlan(seed: 1);
      s.setDayLocked(0, true);
      s.setDayLocked(1, true);
      final locked0 = jsonEncode(s.weekMealPlan!.days[0].toJson());
      final locked1 = jsonEncode(s.weekMealPlan!.days[1].toJson());
      String rest(AppState s) => s.weekMealPlan!.days
          .skip(2)
          .map((d) => d.meals.map((m) => m.recipeId).join())
          .join();
      final others = rest(s);

      s.generateMealPlan(seed: 99);
      final plan = s.weekMealPlan!;
      expect(jsonEncode(plan.days[0].toJson()), locked0);
      expect(jsonEncode(plan.days[1].toJson()), locked1);
      expect(rest(s), isNot(others));
      // La preparazione conta anche i giorni bloccati.
      for (final m in plan.days.first.meals) {
        expect(
          prepServings(s, m.recipeId) > 0 ||
              s.planRecipesById[m.recipeId]?.type != MealType.main,
          isTrue,
        );
      }
      for (final id in plan.prepSessions.map((p) => p.recipeId).toSet()) {
        expect(prepServings(s, id), closeTo(eatenServings(s, id), 1e-9));
      }
      s.setDayLocked(0, false);
      expect(s.weekMealPlan!.days[0].locked, isFalse);
    });

    test('giorni bloccati con lo stile a componenti', () async {
      final s = await newState();
      s.saveMealPrepPrefs(
        s.mealPrepPrefs.copyWith(style: MealPrepStyle.components),
      );
      s.generateMealPlan(seed: 2);
      s.setDayLocked(0, true);
      final lunch = meal(s, 0, MealSlot.lunch)!.recipeId;
      s.generateMealPlan(seed: 50);
      final plan = s.weekMealPlan!;
      expect(meal(s, 0, MealSlot.lunch)!.recipeId, lunch);
      // La combinazione del giorno bloccato resta consultabile.
      expect(plan.combos[lunch], isNotNull);
      expect(s.planRecipesById[lunch], isNotNull);
      for (final c in plan.combos[lunch]!) {
        expect(s.planRecipesById[c], isNotNull);
      }
    });

    test('i pasti bloccati mantengono la ricetta quando si rigenera', () async {
      final s = await newState();
      s.generateMealPlan(seed: 1);
      final lunch = meal(s, 2, MealSlot.lunch)!.recipeId;
      final dinner = meal(s, 2, MealSlot.dinner)!.recipeId;
      s.setMealLocked(2, MealSlot.lunch, true);
      // Porzioni a mano sulla cena: il blocco del pranzo resta.
      s.setMealServings(s.weekMealPlan!.days[2].date, MealSlot.dinner, 2);
      expect(meal(s, 2, MealSlot.lunch)!.recipeLocked, isTrue);

      final dinners = <String>{};
      for (final seed in [10, 20, 30]) {
        s.generateMealPlan(seed: seed);
        expect(meal(s, 2, MealSlot.lunch)!.recipeId, lunch);
        expect(meal(s, 2, MealSlot.lunch)!.recipeLocked, isTrue);
        dinners.add(meal(s, 2, MealSlot.dinner)!.recipeId);
      }
      expect(dinners.any((d) => d != dinner), isTrue);
      // La preparazione conta il pasto bloccato.
      expect(prepServings(s, lunch), closeTo(eatenServings(s, lunch), 1e-9));

      s.setMealLocked(2, MealSlot.lunch, false);
      expect(meal(s, 2, MealSlot.lunch)!.recipeLocked, isFalse);
    });

    test('pasto bloccato con porzioni a mano: restano entrambe', () async {
      final s = await newState();
      s.generateMealPlan(seed: 3);
      final date = s.weekMealPlan!.days[1].date;
      s.setMealServings(date, MealSlot.breakfast, 1.75);
      s.setMealLocked(1, MealSlot.breakfast, true);
      final id = meal(s, 1, MealSlot.breakfast)!.recipeId;
      s.generateMealPlan(seed: 77);
      final m = meal(s, 1, MealSlot.breakfast)!;
      expect(m.recipeId, id);
      expect(m.servings, 1.75);
      expect(m.locked, isTrue);
    });

    test('pasto bloccato con lo stile a componenti', () async {
      final s = await newState();
      s.saveMealPrepPrefs(
        s.mealPrepPrefs.copyWith(style: MealPrepStyle.components),
      );
      s.generateMealPlan(seed: 4);
      final dinner = meal(s, 3, MealSlot.dinner)!.recipeId;
      s.setMealLocked(3, MealSlot.dinner, true);
      s.generateMealPlan(seed: 40);
      expect(meal(s, 3, MealSlot.dinner)!.recipeId, dinner);
      expect(s.weekMealPlan!.combos[dinner], isNotNull);
      expect(s.planRecipesById[dinner], isNotNull);
    });

    test('porzioni e sostituzione non perdono eliminati e blocchi', () async {
      final s = await newState();
      s.generateMealPlan(seed: 5);
      s.setMealStatus(0, [MealSlot.afternoonSnack], MealStatus.removed);
      s.setDayLocked(0, true);
      final date = s.weekMealPlan!.days[0].date;
      s.setMealServings(date, MealSlot.lunch, 1.5);
      var d = s.weekMealPlan!.days[0];
      expect(d.removedSlots, [MealSlot.afternoonSnack]);
      expect(d.locked, isTrue);

      final from = meal(s, 0, MealSlot.breakfast)!.recipeId;
      final to = s.recipes
          .firstWhere((r) => r.type == MealType.breakfast && r.id != from)
          .id;
      s.swapRecipeInPlan(from, to);
      d = s.weekMealPlan!.days[0];
      expect(d.removedSlots, [MealSlot.afternoonSnack]);
      expect(d.locked, isTrue);
      expect(meal(s, 0, MealSlot.breakfast)!.recipeId, to);
    });
  });
}
