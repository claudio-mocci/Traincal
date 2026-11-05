import 'package:flutter_test/flutter_test.dart';
import 'package:traincal/data/local_store.dart';
import 'package:traincal/data/secrets.dart';
import 'package:traincal/models/meal_plan.dart';
import 'package:traincal/models/recipe.dart';
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
}
