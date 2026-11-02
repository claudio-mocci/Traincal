import 'dart:math';

import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import 'energy_calculator.dart';

class MealPlanOptions {
  /// Quante sessioni di cucina nella settimana (1-3). Ogni sessione prepara
  /// una ricetta per i pranzi e una per le cene del suo blocco di giorni.
  final int prepSessions;
  final int breakfastVariety;
  final int snackVariety;
  final Set<String> excludedRecipeIds;
  final int seed;

  const MealPlanOptions({
    this.prepSessions = 2,
    this.breakfastVariety = 2,
    this.snackVariety = 2,
    this.excludedRecipeIds = const {},
    this.seed = 0,
  });
}

class MealPlanResult {
  final WeekMealPlan plan;
  final List<String> warnings;

  const MealPlanResult(this.plan, this.warnings);
}

/// Genera un piano pasti settimanale orientato al meal prep.
class MealPlanner {
  final Map<String, Food> foods;
  final List<Recipe> recipes;

  MealPlanner({required this.foods, required this.recipes});

  static Map<MealSlot, double> slotShares(int mealsPerDay) =>
      switch (mealsPerDay) {
        <= 3 => {
          MealSlot.breakfast: .25,
          MealSlot.lunch: .40,
          MealSlot.dinner: .35,
        },
        4 => {
          MealSlot.breakfast: .25,
          MealSlot.lunch: .35,
          MealSlot.afternoonSnack: .10,
          MealSlot.dinner: .30,
        },
        _ => {
          MealSlot.breakfast: .20,
          MealSlot.morningSnack: .10,
          MealSlot.lunch: .30,
          MealSlot.afternoonSnack: .10,
          MealSlot.dinner: .30,
        },
      };

  /// Divide [n] giorni in [parts] blocchi contigui (i primi più lunghi).
  static List<List<int>> splitBlocks(int n, int parts) {
    parts = parts.clamp(1, n);
    final blocks = <List<int>>[];
    var start = 0;
    for (var i = 0; i < parts; i++) {
      final len =
          (n - start) ~/ (parts - i) +
          (((n - start) % (parts - i)) > 0 ? 1 : 0);
      blocks.add([for (var d = start; d < start + len; d++) d]);
      start += len;
    }
    return blocks;
  }

  MealPlanResult generate({
    required DateTime weekStart,
    required List<DayEnergy> days,
    required int mealsPerDay,
    MealPlanOptions options = const MealPlanOptions(),
  }) {
    final rnd = Random(options.seed);
    final warnings = <String>[];
    final shares = slotShares(mealsPerDay);
    final available = recipes
        .where((r) => !options.excludedRecipeIds.contains(r.id))
        .where((r) => r.macrosPerServing(foods).kcal > 50)
        .toList();

    // Ripartizione media dei macro della settimana: guida la scelta delle
    // ricette con un profilo simile.
    final avg = days
        .map((d) => d.target)
        .fold(Macros.zero, (a, b) => a + b)
        .scale(1 / max(1, days.length));

    double fitScore(Recipe r) {
      final m = r.macrosPerServing(foods);
      double frac(double g, double kcalPerG, double total) =>
          total == 0 ? 0 : g * kcalPerG / total;
      final dp = frac(m.protein, 4, m.kcal) - frac(avg.protein, 4, avg.kcal);
      final dc = frac(m.carbs, 4, m.kcal) - frac(avg.carbs, 4, avg.kcal);
      return dp.abs() + dc.abs() + rnd.nextDouble() * 0.12;
    }

    List<Recipe> pick(
      MealType type,
      int count, {
      Set<String> avoidProteins = const {},
      Set<String> avoidIds = const {},
      int minFridgeDays = 0,
    }) {
      final candidates = available.where((r) => r.type == type).toList();
      final scored = candidates.map((r) => (r: r, s: fitScore(r))).toList()
        ..sort((a, b) => a.s.compareTo(b.s));
      final chosen = <Recipe>[];
      final usedProteins = {...avoidProteins};

      bool keeps(Recipe r) => r.fridgeDays >= minFridgeDays || r.freezable;

      // Tre passate con vincoli via via più laschi.
      for (final strict in [3, 2, 1]) {
        for (final c in scored) {
          if (chosen.length >= count) break;
          final r = c.r;
          if (chosen.contains(r)) continue;
          if (strict >= 2 && avoidIds.contains(r.id)) continue;
          if (strict >= 2 && !keeps(r)) continue;
          if (strict >= 3 && usedProteins.contains(r.mainProtein)) continue;
          chosen.add(r);
          usedProteins.add(r.mainProtein);
        }
      }
      return chosen;
    }

    final dayDates = days.map((d) => d.date).toList();
    final assignments = List.generate(days.length, (_) => <MealSlot, Recipe>{});
    final prepSessions = <PrepSession>[];

    // Pasti principali: una coppia pranzo/cena per blocco di meal prep.
    final mainSlots = shares.keys
        .where((s) => s.type == MealType.main)
        .toList();
    final blocks = splitBlocks(days.length, options.prepSessions);
    final usedMainIds = <String>{};
    for (final block in blocks) {
      final chosen = pick(
        MealType.main,
        mainSlots.length,
        avoidIds: usedMainIds,
        minFridgeDays: block.length,
      );
      if (chosen.isEmpty) {
        warnings.add('Nessuna ricetta per pranzo/cena disponibile.');
        break;
      }
      for (var i = 0; i < mainSlots.length; i++) {
        final recipe = chosen[i % chosen.length];
        usedMainIds.add(recipe.id);
        for (final d in block) {
          assignments[d][mainSlots[i]] = recipe;
        }
        if (recipe.fridgeDays < block.length) {
          warnings.add(
            recipe.freezable
                ? '"${recipe.name}" si conserva ${recipe.fridgeDays} giorni: '
                      'congela le porzioni oltre il giorno ${recipe.fridgeDays}.'
                : '"${recipe.name}" si conserva solo ${recipe.fridgeDays} giorni '
                      'ma copre ${block.length} giorni: valuta una sessione in più.',
          );
        }
      }
    }

    // Colazioni e spuntini: poche ricette che si alternano.
    void rotate(MealType type, int variety) {
      final slots = shares.keys.where((s) => s.type == type).toList();
      if (slots.isEmpty) return;
      final chosen = pick(type, max(variety, slots.length));
      if (chosen.isEmpty) {
        warnings.add('Nessuna ricetta di tipo "${type.label}" disponibile.');
        return;
      }
      for (var d = 0; d < days.length; d++) {
        for (var s = 0; s < slots.length; s++) {
          assignments[d][slots[s]] = chosen[(d + s) % chosen.length];
        }
      }
    }

    rotate(MealType.breakfast, options.breakfastVariety);
    rotate(MealType.snack, options.snackVariety);

    // Porzioni scalate sul fabbisogno del giorno + integrazioni.
    final dayPlans = <DayMealPlan>[];
    for (var d = 0; d < days.length; d++) {
      dayPlans.add(_buildDay(days[d], assignments[d], shares));
    }

    // Sessioni di preparazione: il giorno prima dell'inizio del blocco.
    for (final block in blocks) {
      final byRecipe = <String, double>{};
      for (final d in block) {
        for (final m in dayPlans[d].meals) {
          if (m.slot.type != MealType.main) continue;
          byRecipe[m.recipeId] = (byRecipe[m.recipeId] ?? 0) + m.servings;
        }
      }
      final prepDate = dayDates[block.first].subtract(const Duration(days: 1));
      byRecipe.forEach(
        (id, servings) => prepSessions.add(
          PrepSession(
            date: prepDate,
            recipeId: id,
            totalServings: servings,
            coversDays: [for (final d in block) dayDates[d]],
          ),
        ),
      );
    }

    return MealPlanResult(
      WeekMealPlan(
        weekStart: weekStart,
        days: dayPlans,
        prepSessions: prepSessions,
        generatedAt: DateTime.now(),
      ),
      warnings,
    );
  }

  static double _round(double v, double step) => (v / step).round() * step;

  DayMealPlan _buildDay(
    DayEnergy day,
    Map<MealSlot, Recipe> assigned,
    Map<MealSlot, double> shares,
  ) {
    final target = day.target;
    final orderedSlots = MealSlot.values
        .where((s) => assigned.containsKey(s))
        .toList();
    final extras = <ExtraFood>[];

    Macros total(List<MealEntry> ms) {
      var t = Macros.zero;
      for (final m in ms) {
        final r = recipes.firstWhere((r) => r.id == m.recipeId);
        t = t + r.macrosPerServing(foods).scale(m.servings);
      }
      for (final e in extras) {
        t = t + foods[e.foodId]!.forGrams(e.grams);
      }
      return t;
    }

    final shareSum = orderedSlots.fold<double>(0, (s, x) => s + shares[x]!);
    List<MealEntry> scaleTo(double kcal) => [
      for (final slot in orderedSlots)
        () {
          final r = assigned[slot]!;
          final want = kcal * shares[slot]! / shareSum;
          final servings = _round(want / r.macrosPerServing(foods).kcal, 0.25);
          return MealEntry(slot, r.id, servings.clamp(0.5, 3.0).toDouble());
        }(),
    ];

    double kcalOf(String id, double g) => foods[id]!.forGrams(g).kcal;

    // 1) Porzioni scalate sulle kcal del giorno.
    var meals = scaleTo(target.kcal);
    var gap = target - total(meals);

    // 2) Proteine scarse: yogurt greco, facendo spazio nelle porzioni.
    if (gap.protein > 12 && foods.containsKey('f_yogurt_greco')) {
      final g = _round(min(gap.protein / 0.10, 300), 25);
      if (g > 0) {
        extras.add(ExtraFood('f_yogurt_greco', g));
        meals = scaleTo(target.kcal - kcalOf('f_yogurt_greco', g));
        gap = target - total(meals);
      }
    }

    // 3) Kcal mancanti (porzioni già al massimo): carboidrati se mancano,
    // altrimenti grassi. Mai oltre le kcal da coprire.
    for (var step = 0; step < 3 && gap.kcal > 80; step++) {
      final String id;
      double grams;
      if (gap.carbs > 20 &&
          !extras.any((e) => e.foodId == 'f_banana') &&
          foods.containsKey('f_banana')) {
        id = 'f_banana';
        grams = min(gap.carbs / 0.20, 240);
      } else if (gap.carbs > 20 && foods.containsKey('f_pane_int')) {
        id = 'f_pane_int';
        grams = gap.carbs / 0.44;
      } else if (gap.fat > 8 && foods.containsKey('f_noci')) {
        id = 'f_noci';
        grams = min(gap.fat / 0.65, 30);
      } else {
        break;
      }
      final perGram = kcalOf(id, 1);
      grams = _round(min(grams, gap.kcal / perGram), 10);
      if (grams <= 0) break;
      final i = extras.indexWhere((e) => e.foodId == id);
      if (i >= 0) {
        extras[i] = ExtraFood(id, extras[i].grams + grams);
      } else {
        extras.add(ExtraFood(id, grams));
      }
      gap = target - total(meals);
    }

    return DayMealPlan(
      date: day.date,
      target: target,
      meals: meals,
      extras: extras,
    );
  }

  /// Totale macro effettivo di una giornata del piano.
  Macros dayTotal(DayMealPlan d) {
    var t = Macros.zero;
    for (final m in d.meals) {
      final r = recipes.where((r) => r.id == m.recipeId).firstOrNull;
      if (r != null) t = t + r.macrosPerServing(foods).scale(m.servings);
    }
    for (final e in d.extras) {
      final f = foods[e.foodId];
      if (f != null) t = t + f.forGrams(e.grams);
    }
    return t;
  }
}
