import 'package:flutter_test/flutter_test.dart';
import 'package:traincal/models/profile.dart';
import 'package:traincal/models/recipe.dart';
import 'package:traincal/models/workout.dart';
import 'package:traincal/services/energy_calculator.dart';
import 'package:traincal/services/meal_planner.dart';
import 'package:traincal/services/shopping_list.dart';

import 'test_db.dart';

void main() {
  final dbRecipes = testDb.recipes;
  final foods = {for (final f in testDb.foods) f.id: f};
  final recipes = {for (final r in dbRecipes) r.id: r};
  final monday = DateTime(2026, 11, 2);
  const profile = UserProfile(weightKg: 72, heightCm: 178, birthYear: 1988);

  List<DayEnergy> energyFor(DateTime monday) {
    final week = List.generate(7, (i) => monday.add(Duration(days: i)));
    return EnergyCalculator.computeDays(
      days: week,
      workouts: [
        Workout(
          id: 'e1',
          completed: false,
          eventId: 1,
          date: week[1],
          icuType: 'Run',
          name: 'Ripetute',
          movingTimeSec: 3600,
          trainingLoad: 80,
          distanceM: 12000,
        ),
        Workout(
          id: 'e2',
          completed: false,
          eventId: 2,
          date: week[5],
          icuType: 'Ride',
          name: 'Lungo',
          movingTimeSec: 4 * 3600,
          joules: 2800000,
        ),
      ],
      profile: profile,
      plan: null,
      today: monday,
    );
  }

  final energy = energyFor(monday);

  test('tutti gli ingredienti delle ricette esistono nel database', () {
    for (final r in dbRecipes) {
      for (final i in r.ingredients) {
        expect(
          foods.containsKey(i.foodId),
          isTrue,
          reason: '${r.id} usa ${i.foodId}',
        );
      }
    }
  });

  test('splitBlocks divide i giorni in blocchi contigui', () {
    expect(MealPlanner.splitBlocks(7, 2), [
      [0, 1, 2, 3],
      [4, 5, 6],
    ]);
    expect(MealPlanner.splitBlocks(7, 3).map((b) => b.length), [3, 2, 2]);
    expect(MealPlanner.splitBlocks(7, 1).single, hasLength(7));
  });

  test('il piano copre la settimana entro il 10% delle kcal', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    for (final meals in [3, 4, 5]) {
      final result = planner.generate(
        weekStart: monday,
        days: energy,
        mealsPerDay: meals,
        options: const MealPlanOptions(seed: 42),
      );
      final plan = result.plan;
      expect(plan.days, hasLength(7));
      for (final d in plan.days) {
        expect(d.meals, hasLength(meals));
        final total = planner.dayTotal(d);
        expect(
          (total.kcal - d.target.kcal).abs() / d.target.kcal,
          lessThan(0.10),
          reason: '$meals pasti, ${d.date}: $total vs ${d.target}',
        );
        expect(total.protein, greaterThan(d.target.protein * 0.85));
      }
      // Il giorno del lungo in bici ha più kcal del riposo.
      expect(
        planner.dayTotal(plan.days[5]).kcal,
        greaterThan(planner.dayTotal(plan.days[0]).kcal + 800),
      );
    }
  });

  test('meal prep: stessa ricetta nel blocco, ricette diverse tra blocchi', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    final plan = planner
        .generate(
          weekStart: monday,
          days: energy,
          mealsPerDay: 4,
          options: const MealPlanOptions(prepSessions: 2, seed: 7),
        )
        .plan;
    String lunch(int d) =>
        plan.days[d].meals.firstWhere((m) => m.slot == MealSlot.lunch).recipeId;
    expect({lunch(0), lunch(1), lunch(2), lunch(3)}, hasLength(1));
    expect({lunch(4), lunch(5), lunch(6)}, hasLength(1));
    expect(lunch(0), isNot(lunch(4)));
    // 2 sessioni × (pranzo + cena)
    expect(plan.prepSessions, hasLength(4));
    expect(
      plan.prepSessions.first.date,
      monday.subtract(const Duration(days: 1)),
    );
  });

  test('stesso seed, stesso piano', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    List<String> ids(int seed) => planner
        .generate(
          weekStart: monday,
          days: energy,
          mealsPerDay: 4,
          options: MealPlanOptions(seed: seed),
        )
        .plan
        .days
        .expand((d) => d.meals.map((m) => m.recipeId))
        .toList();
    expect(ids(3), ids(3));
  });

  test('le ricette escluse non compaiono', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    final excluded = dbRecipes
        .where((r) => r.mainProtein == 'pesce')
        .map((r) => r.id)
        .toSet();
    final plan = planner
        .generate(
          weekStart: monday,
          days: energy,
          mealsPerDay: 4,
          options: MealPlanOptions(excludedRecipeIds: excluded, seed: 1),
        )
        .plan;
    final used = plan.days.expand((d) => d.meals).map((m) => m.recipeId);
    expect(used.where(excluded.contains), isEmpty);
  });

  test('lista della spesa: somma corretta e raggruppata per reparto', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    final plan = planner
        .generate(
          weekStart: monday,
          days: energy,
          mealsPerDay: 4,
          options: const MealPlanOptions(seed: 5),
        )
        .plan;
    final list = ShoppingList.fromPlan(plan, recipes, foods);
    expect(list.isEmpty, isFalse);

    final expected = <String, double>{};
    for (final d in plan.days) {
      for (final m in d.meals) {
        for (final i in recipes[m.recipeId]!.ingredients) {
          expected[i.foodId] = (expected[i.foodId] ?? 0) + i.grams * m.servings;
        }
      }
      for (final e in d.extras) {
        expected[e.foodId] = (expected[e.foodId] ?? 0) + e.grams;
      }
    }
    final items = list.byCategory.values.expand((l) => l);
    expect(items.length, expected.length);
    for (final item in items) {
      expect(item.grams, closeTo(expected[item.food.id]!, 0.001));
      expect(list.byCategory[item.food.category], contains(item));
    }
    expect(list.toPlainText(), contains('Lista della spesa'));
  });

  test('etichette quantità: pezzi e confezioni', () {
    final eggs = ShoppingItem(foods['f_uova']!, 400);
    expect(eggs.quantityLabel, startsWith('8 × uovo'));
    final rice = ShoppingItem(foods['f_riso']!, 1250);
    expect(rice.quantityLabel, '1.3 kg → 2 conf. da 1 kg');
    final zucchine = ShoppingItem(foods['f_zucchine']!, 523);
    expect(zucchine.quantityLabel, '530 g');
  });

  test('database: 1000 ricette complete con id unici', () {
    expect(dbRecipes, hasLength(1000));
    expect(recipes, hasLength(dbRecipes.length));
    for (final t in MealType.values) {
      expect(dbRecipes.where((r) => r.type == t), isNotEmpty);
    }
    for (final r in dbRecipes) {
      expect(r.instructions, isNotEmpty, reason: r.id);
      expect(r.ingredients, isNotEmpty, reason: r.id);
      expect(r.mainProtein, isNotEmpty, reason: r.id);
      expect(r.macrosPerServing(foods).kcal, greaterThan(50), reason: r.id);
    }
  });

  test('stagionalità: grammi di stagione e fuori stagione', () {
    const r = Recipe(
      id: 'x',
      name: 'Test',
      type: MealType.main,
      ingredients: [
        Ingredient('f_zucca', 200),
        Ingredient('f_zucchine', 100),
        Ingredient('f_riso', 80),
      ],
    );
    final nov = [DateTime(2026, 11, 10)];
    final g = r.seasonGrams(foods, nov);
    expect(g.inSeason, 200);
    expect(g.outOfSeason, 100);
    expect(r.isInSeason(foods, nov), isFalse);
    expect(r.isInSeason(foods, [DateTime(2026, 9, 10)]), isTrue);
  });

  test('il menu privilegia ingredienti di stagione', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    for (final start in [DateTime(2026, 1, 12), DateTime(2026, 7, 6), monday]) {
      final days = energyFor(start);
      final dates = days.map((d) => d.date).toList();
      for (final seed in [1, 2, 3]) {
        final plan = planner
            .generate(
              weekStart: start,
              days: days,
              mealsPerDay: 5,
              options: MealPlanOptions(seed: seed),
            )
            .plan;
        final used = {
          for (final d in plan.days)
            for (final m in d.meals) m.recipeId,
        };
        for (final id in used) {
          expect(
            recipes[id]!.isInSeason(foods, dates),
            isTrue,
            reason: '$id nella settimana del $start',
          );
        }
      }
    }
  });
}
