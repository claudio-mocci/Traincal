import 'package:flutter_test/flutter_test.dart';
import 'package:traincal/data/local_store.dart';
import 'package:traincal/models/meal_plan.dart';
import 'package:traincal/models/recipe.dart';
import 'package:traincal/state/app_state.dart';

import 'test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> newState() async {
    final s = AppState();
    await s.init(testStore: LocalStore.inMemory(), db: testDb);
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
}
