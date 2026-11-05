import 'dart:math';

import '../models/food.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';

class ShoppingItem {
  final Food food;
  final double grams;

  const ShoppingItem(this.food, this.grams);

  /// Quantità leggibile: pezzi per gli alimenti a unità, confezioni per
  /// quelli confezionati, altrimenti grammi arrotondati.
  String get quantityLabel {
    final f = food;
    if (f.unitGrams != null && f.unitName != null) {
      final n = (grams / f.unitGrams!).ceil();
      return '$n × ${f.unitName} (~${_fmtGrams(grams)})';
    }
    if (f.packageGrams != null) {
      final n = max(1, (grams / f.packageGrams!).ceil());
      return '${_fmtGrams(grams)} · $n conf. da ${_fmtGrams(f.packageGrams!)}';
    }
    return _fmtGrams(grams);
  }

  static String _fmtGrams(double g) {
    if (g >= 1000) {
      final kg = (g / 100).ceil() / 10;
      return '${kg.toStringAsFixed(kg == kg.roundToDouble() ? 0 : 1)} kg';
    }
    return '${((g / 10).ceil() * 10)} g';
  }
}

class ShoppingList {
  final Map<FoodCategory, List<ShoppingItem>> byCategory;

  const ShoppingList(this.byCategory);

  bool get isEmpty => byCategory.isEmpty;

  /// Testo semplice da copiare in note o messaggi.
  String toPlainText() {
    final b = StringBuffer('Lista della spesa\n');
    for (final e in byCategory.entries) {
      b.writeln('\n${e.key.label}');
      for (final i in e.value) {
        b.writeln('- ${i.food.name}: ${i.quantityLabel}');
      }
    }
    return b.toString();
  }

  static Map<String, double> ingredientTotals(
    Iterable<({String recipeId, double servings})> portions,
    Map<String, Recipe> recipes,
  ) {
    final totals = <String, double>{};
    for (final p in portions) {
      final r = recipes[p.recipeId];
      if (r == null) continue;
      for (final i in r.ingredients) {
        totals[i.foodId] = (totals[i.foodId] ?? 0) + i.grams * p.servings;
      }
    }
    return totals;
  }

  factory ShoppingList.fromPlan(
    WeekMealPlan plan,
    Map<String, Recipe> recipes,
    Map<String, Food> foods,
  ) {
    final totals = ingredientTotals(
      plan.days
          .expand((d) => d.meals)
          .map((m) => (recipeId: m.recipeId, servings: m.servings)),
      recipes,
    );
    for (final e in plan.days.expand((d) => d.extras)) {
      totals[e.foodId] = (totals[e.foodId] ?? 0) + e.grams;
    }

    final grouped = <FoodCategory, List<ShoppingItem>>{};
    totals.forEach((id, g) {
      final f = foods[id];
      if (f == null || g <= 0) return;
      grouped.putIfAbsent(f.category, () => []).add(ShoppingItem(f, g));
    });
    for (final l in grouped.values) {
      l.sort((a, b) => a.food.name.compareTo(b.food.name));
    }
    final ordered = {
      for (final c in FoodCategory.values)
        if (grouped.containsKey(c)) c: grouped[c]!,
    };
    return ShoppingList(ordered);
  }
}
