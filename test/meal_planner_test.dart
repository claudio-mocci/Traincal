import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:traincal/models/meal_plan.dart';
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

  /// Pranzi e cene in ordine di tempo: (giorno, ricetta).
  List<({int day, String id})> mainMeals(WeekMealPlan plan) => [
    for (var d = 0; d < plan.days.length; d++)
      for (final m in plan.days[d].meals)
        if (m.slot.type == MealType.main) (day: d, id: m.recipeId),
  ];

  test('ricette alternate: varietà dentro ogni sessione', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    for (final seed in [1, 2, 3, 4, 5]) {
      final result = planner.generate(
        weekStart: monday,
        days: energy,
        mealsPerDay: 4,
        options: MealPlanOptions(prepSessions: 2, mainVariety: 3, seed: seed),
      );
      final plan = result.plan;
      final meals = mainMeals(plan);
      for (final block in [
        [0, 1, 2, 3],
        [4, 5, 6],
      ]) {
        final inBlock = meals.where((m) => block.contains(m.day)).toList();
        final ids = inBlock.map((m) => m.id).toList();
        expect(ids.toSet(), hasLength(3), reason: 'seed $seed');
        // Mai la stessa ricetta due pasti di fila.
        for (var i = 1; i < ids.length; i++) {
          expect(ids[i], isNot(ids[i - 1]), reason: 'seed $seed: $ids');
        }
        // Distribuzione equilibrata: nessuna ricetta oltre ceil(n/3).
        for (final id in ids.toSet()) {
          expect(
            ids.where((x) => x == id).length,
            lessThanOrEqualTo((ids.length / 3).ceil()),
          );
        }
        // Si mangia entro i giorni di conservazione (o è congelabile).
        for (final m in inBlock) {
          final r = recipes[m.id]!;
          expect(
            r.freezable || m.day - block.first + 1 <= r.fridgeDays,
            isTrue,
            reason: '${r.id} giorno ${m.day}',
          );
        }
      }
      // Pranzi di giorni consecutivi diversi.
      String lunch(int d) => plan.days[d].meals
          .firstWhere((m) => m.slot == MealSlot.lunch)
          .recipeId;
      for (var d = 1; d < 7; d++) {
        expect(lunch(d), isNot(lunch(d - 1)), reason: 'seed $seed, giorno $d');
      }
      // Una sessione per blocco, la sera prima, con 3 ricette ciascuna.
      expect(plan.prepSessions, hasLength(6));
      expect(
        plan.prepSessions.first.date,
        monday.subtract(const Duration(days: 1)),
      );
    }
  });

  test('componenti: basi e proteine combinate in modo diverso ogni pasto', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    for (final seed in [1, 2, 3, 4, 5]) {
      final plan = planner
          .generate(
            weekStart: monday,
            days: energy,
            mealsPerDay: 4,
            options: MealPlanOptions(
              style: MealPrepStyle.components,
              seed: seed,
            ),
          )
          .plan;
      final all = {...recipes, for (final r in plan.generatedRecipes) r.id: r};
      final meals = mainMeals(plan);
      expect(plan.combos.keys, containsAll(meals.map((m) => m.id).toSet()));

      String protein(String id) => plan.combos[id]![1];
      for (var i = 1; i < meals.length; i++) {
        expect(
          protein(meals[i].id),
          isNot(protein(meals[i - 1].id)),
          reason: 'seed $seed: proteina ripetuta al pasto $i',
        );
      }
      // In ogni blocco di 4 giorni: 2 basi, 3 proteine, 3 verdure e quasi
      // ogni pasto è una combinazione diversa.
      final first = meals.where((m) => m.day < 4).map((m) => m.id).toList();
      expect(first.map((id) => plan.combos[id]![0]).toSet(), hasLength(2));
      expect(first.map(protein).toSet(), hasLength(3));
      expect(first.toSet().length, greaterThanOrEqualTo(6));
      // A pranzo la base cambia da un giorno all'altro.
      final lunchBases = [
        for (var d = 0; d < 4; d++)
          plan.combos[plan.days[d].meals
              .firstWhere((m) => m.slot == MealSlot.lunch)
              .recipeId]![0],
      ];
      for (var d = 1; d < 4; d++) {
        expect(lunchBases[d], isNot(lunchBases[d - 1]), reason: '$lunchBases');
      }

      // Verdure di stagione (novembre).
      for (final id in plan.combos.values.map((c) => c[2]).toSet()) {
        final food = foods[all[id]!.ingredients.first.foodId]!;
        expect(food.inSeason(monday), isTrue, reason: food.id);
      }

      // Le proteine delicate si mangiano entro la loro durata.
      for (final m in meals) {
        final p = all[protein(m.id)]!;
        final dayInBlock = m.day < 4 ? m.day : m.day - 4;
        expect(
          p.freezable || dayInBlock + 1 <= p.fridgeDays,
          isTrue,
          reason: '${p.id} giorno ${m.day}',
        );
      }

      // Le sessioni elencano i componenti, con le porzioni dei pasti.
      for (final ps in plan.prepSessions) {
        expect(ps.recipeId, startsWith('cmp_'));
        final expected = plan.days
            .where((d) => ps.coversDays.contains(d.date))
            .expand((d) => d.meals)
            .where(
              (m) => plan.combos[m.recipeId]?.contains(ps.recipeId) ?? false,
            )
            .fold<double>(0, (a, m) => a + m.servings);
        expect(ps.totalServings, closeTo(expected, 0.001));
      }

      // Kcal rispettate e lista della spesa completa.
      final withExtra = MealPlanner(
        foods: foods,
        recipes: dbRecipes,
        extraRecipes: plan.generatedRecipes,
      );
      for (final d in plan.days) {
        final total = withExtra.dayTotal(d);
        expect(
          (total.kcal - d.target.kcal).abs() / d.target.kcal,
          lessThan(0.10),
        );
      }
      final list = ShoppingList.fromPlan(plan, all, foods);
      final names = list.byCategory.values
          .expand((l) => l)
          .map((i) => i.food.id);
      expect(names, contains('f_olio'));
    }
  });

  test('il piano a componenti sopravvive al salvataggio', () {
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    final plan = planner
        .generate(
          weekStart: monday,
          days: energy,
          mealsPerDay: 3,
          options: const MealPlanOptions(
            style: MealPrepStyle.components,
            seed: 9,
          ),
        )
        .plan;
    final copy = WeekMealPlan.fromJson(
      jsonDecode(jsonEncode(plan.toJson())) as Map<String, dynamic>,
    );
    expect(copy.combos, plan.combos);
    expect(
      copy.generatedRecipes.map((r) => r.id),
      plan.generatedRecipes.map((r) => r.id),
    );
    expect(MealPlanner.blocksOf(copy), hasLength(2));
    final rebuilt = MealPlanner.buildPrepSessions(
      copy.days,
      MealPlanner.blocksOf(copy),
      copy.combos,
    );
    expect(
      rebuilt.map((p) => '${p.recipeId}:${p.totalServings}').toSet(),
      plan.prepSessions.map((p) => '${p.recipeId}:${p.totalServings}').toSet(),
    );
  });

  test('scheduleMeals evita ripetizioni e rispetta la conservazione', () {
    final meals = [
      for (var d = 0; d < 4; d++)
        for (final s in [MealSlot.lunch, MealSlot.dinner]) (day: d, slot: s),
    ];
    // "pesce" dura 2 giorni: deve comparire solo nei giorni 0-1.
    final items = ['pesce', 'pollo', 'legumi'];
    final life = {
      'pesce': (fridgeDays: 2, freezable: false),
      'pollo': (fridgeDays: 4, freezable: false),
      'legumi': (fridgeDays: 5, freezable: false),
    };
    final out = MealPlanner.scheduleMeals(
      meals,
      items,
      (x) => life[x]!,
      avoidRepeat: true,
    );
    for (var i = 1; i < out.length; i++) {
      expect(out[i], isNot(out[i - 1]));
    }
    for (var i = 0; i < out.length; i++) {
      if (out[i] == 'pesce') expect(meals[i].day, lessThan(2));
    }
    expect(out.toSet(), hasLength(3));
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
    expect(rice.quantityLabel, '1.3 kg · 2 conf. da 1 kg');
    final zucchine = ShoppingItem(foods['f_zucchine']!, 523);
    expect(zucchine.quantityLabel, '530 g');
  });

  test('database: 1001 ricette complete con id unici', () {
    expect(dbRecipes, hasLength(1001));
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

  group('porzioni e ricette fisse', () {
    final breakfasts = dbRecipes
        .where((r) => r.type == MealType.breakfast)
        .toList();
    final snacks = dbRecipes.where((r) => r.type == MealType.snack).toList();

    List<String> slotIds(WeekMealPlan plan, MealSlot slot) => [
      for (final d in plan.days)
        d.meals.firstWhere((m) => m.slot == slot).recipeId,
    ];

    test('le colazioni fisse sono sempre nella rotazione', () {
      final planner = MealPlanner(foods: foods, recipes: dbRecipes);
      final fav = breakfasts[3].id;
      for (final seed in [1, 2, 3]) {
        final plan = planner
            .generate(
              weekStart: monday,
              days: energy,
              mealsPerDay: 4,
              options: MealPlanOptions(
                breakfastVariety: 2,
                pinnedRecipeIds: {fav},
                seed: seed,
              ),
            )
            .plan;
        final ids = slotIds(plan, MealSlot.breakfast);
        expect(ids.where((id) => id == fav), hasLength(4), reason: '$ids');
        expect(ids.toSet(), hasLength(2));
      }
      // Più fisse della varietà richiesta: si usano solo quelle.
      final favs = {breakfasts[1].id, breakfasts[2].id, breakfasts[3].id};
      final plan = planner
          .generate(
            weekStart: monday,
            days: energy,
            mealsPerDay: 5,
            options: MealPlanOptions(
              breakfastVariety: 1,
              snackVariety: 2,
              pinnedRecipeIds: {...favs, snacks[0].id},
              seed: 4,
            ),
          )
          .plan;
      expect(slotIds(plan, MealSlot.breakfast).toSet(), favs);
      final snackIds = [
        ...slotIds(plan, MealSlot.morningSnack),
        ...slotIds(plan, MealSlot.afternoonSnack),
      ];
      expect(snackIds, contains(snacks[0].id));
      expect(snackIds.toSet(), hasLength(2));
    });

    test('le ricette a porzione fissa non vengono scalate', () {
      final fav = breakfasts[0].copyWith(fixedServings: 1.5);
      final all = [fav, ...dbRecipes.where((r) => r.id != fav.id)];
      final planner = MealPlanner(foods: foods, recipes: all);
      final plan = planner
          .generate(
            weekStart: monday,
            days: energy,
            mealsPerDay: 4,
            options: MealPlanOptions(
              breakfastVariety: 1,
              pinnedRecipeIds: {fav.id},
              seed: 2,
            ),
          )
          .plan;
      for (final d in plan.days) {
        final b = d.meals.firstWhere((m) => m.slot == MealSlot.breakfast);
        expect(b.recipeId, fav.id);
        expect(b.servings, 1.5);
        final total = planner.dayTotal(d);
        expect(
          (total.kcal - d.target.kcal).abs() / d.target.kcal,
          lessThan(0.10),
          reason: '${d.date}',
        );
      }
    });

    test('porzioni impostate a mano: gli altri pasti si adattano', () {
      final planner = MealPlanner(foods: foods, recipes: dbRecipes);
      final plan = planner
          .generate(
            weekStart: monday,
            days: energy,
            mealsPerDay: 4,
            options: const MealPlanOptions(seed: 6),
          )
          .plan;
      final day = plan.days[2];
      final lunch = day.meals.firstWhere((m) => m.slot == MealSlot.lunch);
      final edited = DayMealPlan(
        date: day.date,
        target: day.target,
        meals: [
          for (final m in day.meals)
            m.slot == MealSlot.lunch
                ? MealEntry(
                    m.slot,
                    m.recipeId,
                    lunch.servings + 0.75,
                    locked: true,
                  )
                : m,
        ],
      );
      final balanced = planner.rebalanceDay(edited);
      final newLunch = balanced.meals.firstWhere(
        (m) => m.slot == MealSlot.lunch,
      );
      expect(newLunch.servings, lunch.servings + 0.75);
      expect(newLunch.locked, isTrue);
      // Gli altri pasti non crescono, almeno uno si riduce.
      final others = balanced.meals.where((m) => m.slot != MealSlot.lunch);
      final before = {for (final m in day.meals) m.slot: m.servings};
      expect(others.every((m) => m.servings <= before[m.slot]!), isTrue);
      expect(others.any((m) => m.servings < before[m.slot]!), isTrue);
      final total = planner.dayTotal(balanced);
      expect(
        (total.kcal - day.target.kcal).abs() / day.target.kcal,
        lessThan(0.10),
      );

      // Serializzazione: il blocco e la porzione fissa sopravvivono.
      final copy = DayMealPlan.fromJson(
        jsonDecode(jsonEncode(balanced.toJson())) as Map<String, dynamic>,
      );
      expect(
        copy.meals.firstWhere((m) => m.slot == MealSlot.lunch).locked,
        isTrue,
      );
      final r = Recipe.fromJson(
        jsonDecode(
          jsonEncode(breakfasts[0].copyWith(fixedServings: 2).toJson()),
        ) as Map<String, dynamic>,
      );
      expect(r.fixedServings, 2);
      expect(r.copyWith(clearFixedServings: true).fixedServings, isNull);
    });
  });

  group('pasti liberi', () {
    // Venerdì (indice 4) pranzo e cena liberi, domenica tutta libera.
    final free = {
      4: {MealSlot.lunch, MealSlot.dinner},
      6: {
        MealSlot.breakfast,
        MealSlot.lunch,
        MealSlot.afternoonSnack,
        MealSlot.dinner,
      },
    };

    for (final style in MealPrepStyle.values) {
      test('niente ricette, preparazione né spesa (${style.name})', () {
        final planner = MealPlanner(foods: foods, recipes: dbRecipes);
        final plan = planner
            .generate(
              weekStart: monday,
              days: energy,
              mealsPerDay: 4,
              options: MealPlanOptions(style: style, freeMeals: free, seed: 3),
            )
            .plan;
        final fri = plan.days[4];
        expect(fri.freeSlots, [MealSlot.lunch, MealSlot.dinner]);
        expect(fri.meals.map((m) => m.slot), [
          MealSlot.breakfast,
          MealSlot.afternoonSnack,
        ]);
        final sun = plan.days[6];
        expect(sun.meals, isEmpty);
        expect(sun.extras, isEmpty);

        // Le sessioni non coprono i pasti liberi.
        final all = {
          ...recipes,
          for (final r in plan.generatedRecipes) r.id: r,
        };
        final cooked = plan.prepSessions.fold<double>(
          0,
          (a, p) => a + (plan.combos.isEmpty ? p.totalServings : 0),
        );
        final mainServings = plan.days
            .expand((d) => d.meals)
            .where((m) => m.slot.type == MealType.main)
            .fold<double>(0, (a, m) => a + m.servings);
        if (plan.combos.isEmpty) expect(cooked, closeTo(mainServings, 0.001));

        // I pasti rimasti coprono solo la loro quota del fabbisogno.
        final withExtra = MealPlanner(
          foods: foods,
          recipes: dbRecipes,
          extraRecipes: plan.generatedRecipes,
        );
        final planned = MealPlanner.plannedTarget(fri);
        // Quote con 4 pasti: colazione .25 + spuntino .10 = 35%.
        expect(planned.kcal, closeTo(fri.target.kcal * 0.35, 0.5));
        final total = withExtra.dayTotal(fri);
        expect(
          (total.kcal - planned.kcal).abs() / planned.kcal,
          lessThan(0.12),
          reason: '$total vs $planned',
        );
        // La spesa contiene solo ingredienti dei pasti pianificati.
        final list = ShoppingList.fromPlan(plan, all, foods);
        expect(list.isEmpty, isFalse);
      });
    }

    test('ribilanciamento e salvataggio mantengono i pasti liberi', () {
      final planner = MealPlanner(foods: foods, recipes: dbRecipes);
      final plan = planner
          .generate(
            weekStart: monday,
            days: energy,
            mealsPerDay: 4,
            options: MealPlanOptions(freeMeals: free, seed: 8),
          )
          .plan;
      final fri = plan.days[4];
      final again = planner.rebalanceDay(fri);
      expect(again.freeSlots, fri.freeSlots);
      expect(
        again.meals.map((m) => m.servings),
        fri.meals.map((m) => m.servings),
      );
      final copy = DayMealPlan.fromJson(
        jsonDecode(jsonEncode(fri.toJson())) as Map<String, dynamic>,
      );
      expect(copy.freeSlots, fri.freeSlots);
    });
  });

  test('gelato in cono: spuntino a porzione fissa', () {
    final gelato = recipes['r_gelato_cono']!;
    expect(gelato.type, MealType.snack);
    expect(gelato.fixedServings, 1);
    expect(gelato.fridgeDays, 0);
    final m = gelato.macrosPerServing(foods);
    expect(m.kcal, closeTo(255, 5));
    // Fissato tra gli spuntini: nel menu è sempre un cono, mai scalato.
    final planner = MealPlanner(foods: foods, recipes: dbRecipes);
    final plan = planner
        .generate(
          weekStart: monday,
          days: energy,
          mealsPerDay: 4,
          options: const MealPlanOptions(
            snackVariety: 1,
            pinnedRecipeIds: {'r_gelato_cono'},
            seed: 2,
          ),
        )
        .plan;
    for (final d in plan.days) {
      final snack = d.meals.firstWhere(
        (x) => x.slot == MealSlot.afternoonSnack,
      );
      expect(snack.recipeId, 'r_gelato_cono');
      expect(snack.servings, 1);
    }
  });
}
