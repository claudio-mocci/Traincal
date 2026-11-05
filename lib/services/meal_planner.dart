import 'dart:math';

import '../data/components.dart';
import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import 'energy_calculator.dart';

class MealPlanOptions {
  /// Quante sessioni di cucina nella settimana (1-3); ognuna copre un blocco
  /// di giorni consecutivi.
  final int prepSessions;

  final MealPrepStyle style;

  /// Ricette diverse cucinate in ogni sessione (stile [MealPrepStyle.recipes]),
  /// alternate tra pranzi e cene del blocco.
  final int mainVariety;
  final int breakfastVariety;
  final int snackVariety;
  final Set<String> excludedRecipeIds;
  final int seed;

  /// Peso della stagionalità nella scelta delle ricette: 0 la ignora, 0.6
  /// rende rare le ricette con ingredienti fuori stagione.
  final double seasonWeight;

  const MealPlanOptions({
    this.prepSessions = 2,
    this.style = MealPrepStyle.recipes,
    this.mainVariety = 3,
    this.breakfastVariety = 2,
    this.snackVariety = 2,
    this.excludedRecipeIds = const {},
    this.seed = 0,
    this.seasonWeight = 0.6,
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

  MealPlanner({
    required this.foods,
    required this.recipes,
    List<Recipe> extraRecipes = const [],
  }) : _byId = {
         for (final r in recipes) r.id: r,
         for (final r in extraRecipes) r.id: r,
       };

  /// Ricettario più le ricette generate per il piano (combinazioni e
  /// componenti), usate solo per la consultazione.
  final Map<String, Recipe> _byId;
  final Map<String, Macros> _macros = {};

  /// Combinazioni e componenti creati dall'ultima generazione.
  final Map<String, Recipe> _generated = {};

  Recipe? _lookup(String id) => _byId[id] ?? _generated[id];

  Macros _perServing(Recipe r) =>
      _macros.putIfAbsent(r.id, () => r.macrosPerServing(foods));

  /// Quota (0-1) di ingredienti stagionali fuori stagione nei giorni
  /// indicati, meno un piccolo bonus (fino a 0.15) per le ricette che usano
  /// prodotti di stagione.
  double seasonPenalty(Recipe r, List<DateTime> days) {
    final g = r.seasonGrams(foods, days);
    final seasonal = g.inSeason + g.outOfSeason;
    if (seasonal == 0) return 0;
    return g.outOfSeason / seasonal - 0.15 * min(1, g.inSeason / 200);
  }

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
        .where((r) => _perServing(r).kcal > 50)
        .toList();

    // Ripartizione media dei macro della settimana: guida la scelta delle
    // ricette con un profilo simile.
    final avg = days
        .map((d) => d.target)
        .fold(Macros.zero, (a, b) => a + b)
        .scale(1 / max(1, days.length));

    final dayDates = days.map((d) => d.date).toList();

    // Vicinanza al profilo di macro della settimana, stagionalità degli
    // ingredienti nei giorni in cui la ricetta verrà mangiata e un po' di
    // casualità per variare.
    double fitScore(Recipe r, List<DateTime> when) {
      final m = _perServing(r);
      double frac(double g, double kcalPerG, double total) =>
          total == 0 ? 0 : g * kcalPerG / total;
      final dp = frac(m.protein, 4, m.kcal) - frac(avg.protein, 4, avg.kcal);
      final dc = frac(m.carbs, 4, m.kcal) - frac(avg.carbs, 4, avg.kcal);
      return dp.abs() +
          dc.abs() +
          options.seasonWeight * seasonPenalty(r, when) +
          rnd.nextDouble() * 0.12;
    }

    List<Recipe> pick(
      MealType type,
      int count, {
      required List<DateTime> when,
      Set<String> avoidProteins = const {},
      Set<String> avoidIds = const {},
      int minFridgeDays = 0,
    }) {
      final candidates = available.where((r) => r.type == type).toList();
      final scored =
          candidates.map((r) => (r: r, s: fitScore(r, when))).toList()
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

    final assignments = List.generate(days.length, (_) => <MealSlot, Recipe>{});
    final generated = <String, Recipe>{};
    final combos = <String, List<String>>{};

    // Pasti principali: per ogni blocco di meal prep, più ricette (o
    // componenti) distribuite sui pasti senza ripetizioni ravvicinate.
    final mainSlots = shares.keys
        .where((s) => s.type == MealType.main)
        .toList();
    final blocks = splitBlocks(days.length, options.prepSessions);
    final usedMainIds = <String>{};
    var previousProteins = <String>{};
    for (final block in blocks) {
      final meals = [
        for (final d in block)
          for (final slot in mainSlots) (day: d - block.first, slot: slot),
      ];
      final when = [for (final d in block) dayDates[d]];

      if (options.style == MealPrepStyle.components) {
        final picked = _pickComponents(
          block.length,
          when,
          previousProteins,
          rnd,
        );
        if (picked == null) {
          warnings.add('Componenti insufficienti nel database alimenti.');
          break;
        }
        final protein = scheduleMeals(
          meals,
          picked.proteins,
          _componentLife,
          avoidRepeat: true,
        );
        final proteinIds = [for (final p in protein) p.id];
        final base = scheduleMeals(
          meals,
          picked.bases,
          _componentLife,
          companions: proteinIds,
        );
        final veg = scheduleMeals(
          meals,
          picked.vegetables,
          _componentLife,
          companions: proteinIds,
        );
        for (var i = 0; i < meals.length; i++) {
          final combo = _combo(base[i], protein[i], veg[i]);
          generated[combo.id] = combo;
          combos[combo.id] = [base[i].id, protein[i].id, veg[i].id];
          for (final c in [base[i], protein[i], veg[i]]) {
            generated.putIfAbsent(c.id, c.toRecipe);
          }
          assignments[block[meals[i].day]][meals[i].slot] = combo;
        }
        previousProteins = {for (final p in picked.proteins) p.mainProtein};
        continue;
      }

      // Almeno metà delle ricette deve durare tutto il blocco; le altre
      // possono essere più delicate e finire nei primi giorni.
      final k = options.mainVariety.clamp(1, meals.length);
      final lasting = pick(
        MealType.main,
        (k + 1) ~/ 2,
        when: when,
        avoidIds: usedMainIds,
        avoidProteins: previousProteins,
        minFridgeDays: block.length,
      );
      final others = pick(
        MealType.main,
        k - lasting.length,
        when: when,
        avoidIds: {...usedMainIds, ...lasting.map((r) => r.id)},
        avoidProteins: {
          ...previousProteins,
          ...lasting.map((r) => r.mainProtein),
        },
      );
      final chosen = [...lasting, ...others.where((r) => !lasting.contains(r))];
      if (chosen.isEmpty) {
        warnings.add('Nessuna ricetta per pranzo/cena disponibile.');
        break;
      }
      final schedule = scheduleMeals(
        meals,
        chosen,
        (r) => (fridgeDays: r.fridgeDays, freezable: r.freezable),
        avoidRepeat: true,
      );
      for (var i = 0; i < meals.length; i++) {
        final r = schedule[i];
        assignments[block[meals[i].day]][meals[i].slot] = r;
        final eatenAfter = meals[i].day + 1;
        if (eatenAfter > r.fridgeDays) {
          final w = r.freezable
              ? '"${r.name}" si conserva ${r.fridgeDays} giorni: congela le '
                    'porzioni da mangiare dopo.'
              : '"${r.name}" viene mangiata $eatenAfter giorni dopo la '
                    'preparazione ma si conserva ${r.fridgeDays} giorni.';
          if (!warnings.contains(w)) warnings.add(w);
        }
      }
      usedMainIds.addAll(chosen.map((r) => r.id));
      previousProteins = {for (final r in chosen) r.mainProtein};
    }
    _generated
      ..clear()
      ..addAll(generated);

    // Colazioni e spuntini: poche ricette che si alternano.
    void rotate(MealType type, int variety) {
      final slots = shares.keys.where((s) => s.type == type).toList();
      if (slots.isEmpty) return;
      final chosen = pick(type, max(variety, slots.length), when: dayDates);
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

    final prepSessions = buildPrepSessions(dayPlans, [
      for (final b in blocks) [for (final d in b) dayDates[d]],
    ], combos);

    return MealPlanResult(
      WeekMealPlan(
        weekStart: weekStart,
        days: dayPlans,
        prepSessions: prepSessions,
        generatedAt: DateTime.now(),
        generatedRecipes: generated.values.toList(),
        combos: combos,
      ),
      warnings,
    );
  }

  static ({int fridgeDays, bool freezable}) _componentLife(MealComponent c) =>
      (fridgeDays: c.fridgeDays, freezable: c.freezable);

  /// Assegna un elemento a ogni pasto (in ordine di tempo) cercando la
  /// massima varietà: penalizza l'elemento del pasto precedente (vietato se
  /// [avoidRepeat]), quello dello stesso pasto del giorno prima e quelli
  /// già usati spesso. Gli elementi che a quel punto del blocco non si
  /// conservano più vengono scartati finché c'è un'alternativa.
  /// [items] va in ordine di preferenza: a parità vince il primo.
  ///
  /// Con [companions] (l'elemento già scelto per ogni pasto, es. la
  /// proteina) si penalizzano gli abbinamenti già usati, così le
  /// combinazioni cambiano da un pasto all'altro.
  static List<T> scheduleMeals<T>(
    List<({int day, MealSlot slot})> meals,
    List<T> items,
    ({int fridgeDays, bool freezable}) Function(T) life, {
    bool avoidRepeat = false,
    List<Object>? companions,
  }) {
    assert(items.isNotEmpty);
    final usage = List.filled(items.length, 0);
    final result = <T>[];
    final bySlotDay = <(MealSlot, int), int>{};
    final pairs = <(Object, int), int>{};
    int? previous;
    for (var k = 0; k < meals.length; k++) {
      final m = meals[k];
      final companion = companions?[k];
      var best = -1;
      var bestScore = double.infinity;
      for (var i = 0; i < items.length; i++) {
        final l = life(items[i]);
        final keeps = l.freezable || m.day + 1 <= l.fridgeDays;
        var score = usage[i] * 10.0 + i * 0.1;
        if (!keeps) score += 1000;
        if (previous == i) score += avoidRepeat ? 500 : 4;
        if (bySlotDay[(m.slot, m.day - 1)] == i) score += 7;
        if (companion != null) score += (pairs[(companion, i)] ?? 0) * 12.0;
        if (score < bestScore) {
          bestScore = score;
          best = i;
        }
      }
      usage[best]++;
      previous = best;
      bySlotDay[(m.slot, m.day)] = best;
      if (companion != null) {
        pairs[(companion, best)] = (pairs[(companion, best)] ?? 0) + 1;
      }
      result.add(items[best]);
    }
    return result;
  }

  /// Sceglie basi, proteine e verdure per un blocco di [blockDays] giorni:
  /// verdure di stagione, fonti proteiche diverse tra loro e (se possibile)
  /// rispetto al blocco precedente, al massimo una proteina delicata (che non
  /// dura tutto il blocco), messa per prima così finisce nei primi giorni.
  ({
    List<MealComponent> bases,
    List<MealComponent> proteins,
    List<MealComponent> vegetables,
  })?
  _pickComponents(
    int blockDays,
    List<DateTime> when,
    Set<String> previousProteins,
    Random rnd,
  ) {
    bool available(MealComponent c) {
      final f = foods[c.foodId];
      if (f == null || !foods.containsKey(MealComponent.oilFoodId)) {
        return false;
      }
      return when.where(f.inSeason).length * 2 >= when.length;
    }

    List<MealComponent> shuffled(ComponentKind k) =>
        mealComponents.where((c) => c.kind == k && available(c)).toList()
          ..shuffle(rnd);

    final bases = shuffled(ComponentKind.base).take(blockDays >= 3 ? 2 : 1);

    final proteins = <MealComponent>[];
    final wanted = min(3, max(2, blockDays));
    var delicate = 0;
    final candidates = shuffled(ComponentKind.protein)
      ..sort(
        (a, b) =>
            (previousProteins.contains(a.mainProtein) ? 1 : 0) -
            (previousProteins.contains(b.mainProtein) ? 1 : 0),
      );
    for (final c in candidates) {
      if (proteins.length >= wanted) break;
      if (proteins.any((p) => p.mainProtein == c.mainProtein)) continue;
      final short = !c.freezable && c.fridgeDays < blockDays;
      if (short && delicate >= 1) continue;
      if (short) delicate++;
      proteins.add(c);
    }
    proteins.sort((a, b) => _lifeOf(a).compareTo(_lifeOf(b)));

    final vegetables = shuffled(ComponentKind.vegetable)
        .take(blockDays >= 3 ? 3 : 2)
        .toList();

    if (bases.isEmpty || proteins.isEmpty || vegetables.isEmpty) return null;
    return (bases: bases.toList(), proteins: proteins, vegetables: vegetables);
  }

  static int _lifeOf(MealComponent c) => c.freezable ? 99 : c.fridgeDays;

  /// Il piatto composto da base, proteina e verdura.
  Recipe _combo(MealComponent base, MealComponent protein, MealComponent veg) {
    final grams = <String, double>{};
    for (final c in [base, protein, veg]) {
      final r = c.toRecipe();
      for (final i in r.ingredients) {
        grams[i.foodId] = (grams[i.foodId] ?? 0) + i.grams;
      }
    }
    String name(MealComponent c) => c.label;
    final title = name(protein);
    return Recipe(
      id: 'cmb_${base.id.substring(4)}_${protein.id.substring(4)}_${veg.id.substring(4)}',
      name:
          '${title[0].toUpperCase()}${title.substring(1)} con ${name(base)} e '
          '${name(veg)}',
      type: MealType.main,
      ingredients: [for (final e in grams.entries) Ingredient(e.key, e.value)],
      instructions:
          'Componi il piatto con le preparazioni della sessione di meal prep: '
          '${name(base)}, ${name(protein)} e ${name(veg)}. Scalda base e '
          'proteina; le verdure si possono mangiare anche fredde.',
      mainProtein: protein.mainProtein,
      fridgeDays: [
        base.fridgeDays,
        protein.fridgeDays,
        veg.fridgeDays,
      ].reduce(min),
      freezable: false,
      prepMinutes: 5,
      tags: const ['combinazione'],
      source: RecipeSource.builtin,
    );
  }

  /// Sessioni di cucina, una per blocco (la sera prima del primo giorno):
  /// per ogni ricetta, o per ogni componente delle combinazioni, le porzioni
  /// totali da preparare per i pranzi e le cene del blocco.
  static List<PrepSession> buildPrepSessions(
    List<DayMealPlan> days,
    List<List<DateTime>> blocks,
    Map<String, List<String>> combos,
  ) {
    final sessions = <PrepSession>[];
    for (final block in blocks) {
      if (block.isEmpty) continue;
      final servings = <String, double>{};
      for (final d in days.where((d) => block.contains(d.date))) {
        for (final m in d.meals.where((m) => m.slot.type == MealType.main)) {
          for (final id in combos[m.recipeId] ?? [m.recipeId]) {
            servings[id] = (servings[id] ?? 0) + m.servings;
          }
        }
      }
      final prepDate = block.first.subtract(const Duration(days: 1));
      servings.forEach(
        (id, total) => sessions.add(
          PrepSession(
            date: prepDate,
            recipeId: id,
            totalServings: total,
            coversDays: block,
          ),
        ),
      );
    }
    return sessions;
  }

  /// I blocchi di giorni di un piano esistente, ricavati dalle sessioni.
  static List<List<DateTime>> blocksOf(WeekMealPlan plan) {
    final byDate = <DateTime, List<DateTime>>{};
    for (final s in plan.prepSessions) {
      byDate.putIfAbsent(s.date, () => s.coversDays);
    }
    return (byDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => e.value)
        .toList();
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
        t = t + _perServing(_lookup(m.recipeId)!).scale(m.servings);
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
          final servings = _round(want / _perServing(r).kcal, 0.25);
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
      final r = _lookup(m.recipeId);
      if (r != null) t = t + _perServing(r).scale(m.servings);
    }
    for (final e in d.extras) {
      final f = foods[e.foodId];
      if (f != null) t = t + f.forGrams(e.grams);
    }
    return t;
  }
}
