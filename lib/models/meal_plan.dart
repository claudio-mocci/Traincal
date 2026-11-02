import 'food.dart';
import 'recipe.dart';

/// Un pasto assegnato a un giorno: ricetta + numero di porzioni (scalate
/// sul fabbisogno di quel giorno).
class MealEntry {
  final MealSlot slot;
  final String recipeId;
  final double servings;

  const MealEntry(this.slot, this.recipeId, this.servings);

  Map<String, dynamic> toJson() => {
    'slot': slot.name,
    'recipeId': recipeId,
    'servings': servings,
  };

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
    MealSlot.values.byName(j['slot'] as String),
    j['recipeId'] as String,
    (j['servings'] as num).toDouble(),
  );
}

/// Alimento aggiunto per chiudere il gap di macro di una giornata.
class ExtraFood {
  final String foodId;
  final double grams;

  const ExtraFood(this.foodId, this.grams);

  Map<String, dynamic> toJson() => {'foodId': foodId, 'grams': grams};

  factory ExtraFood.fromJson(Map<String, dynamic> j) =>
      ExtraFood(j['foodId'] as String, (j['grams'] as num).toDouble());
}

class DayMealPlan {
  final DateTime date;
  final Macros target;
  final List<MealEntry> meals;
  final List<ExtraFood> extras;

  const DayMealPlan({
    required this.date,
    required this.target,
    required this.meals,
    this.extras = const [],
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'target': target.toJson(),
    'meals': meals.map((e) => e.toJson()).toList(),
    'extras': extras.map((e) => e.toJson()).toList(),
  };

  factory DayMealPlan.fromJson(Map<String, dynamic> j) => DayMealPlan(
    date: DateTime.parse(j['date'] as String),
    target: Macros.fromJson(j['target'] as Map<String, dynamic>),
    meals: (j['meals'] as List)
        .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    extras: (j['extras'] as List? ?? const [])
        .map((e) => ExtraFood.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Una sessione di cucina: si prepara una ricetta per più giorni.
class PrepSession {
  final DateTime date;
  final String recipeId;
  final double totalServings;
  final List<DateTime> coversDays;

  const PrepSession({
    required this.date,
    required this.recipeId,
    required this.totalServings,
    required this.coversDays,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'recipeId': recipeId,
    'totalServings': totalServings,
    'coversDays': coversDays.map((d) => d.toIso8601String()).toList(),
  };

  factory PrepSession.fromJson(Map<String, dynamic> j) => PrepSession(
    date: DateTime.parse(j['date'] as String),
    recipeId: j['recipeId'] as String,
    totalServings: (j['totalServings'] as num).toDouble(),
    coversDays: (j['coversDays'] as List)
        .map((d) => DateTime.parse(d as String))
        .toList(),
  );
}

class WeekMealPlan {
  /// Lunedì della settimana; usato anche come id del documento.
  final DateTime weekStart;
  final List<DayMealPlan> days;
  final List<PrepSession> prepSessions;
  final DateTime generatedAt;

  const WeekMealPlan({
    required this.weekStart,
    required this.days,
    required this.prepSessions,
    required this.generatedAt,
  });

  String get id => weekStart.toIso8601String().substring(0, 10);

  Map<String, dynamic> toJson() => {
    'weekStart': weekStart.toIso8601String(),
    'days': days.map((e) => e.toJson()).toList(),
    'prepSessions': prepSessions.map((e) => e.toJson()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory WeekMealPlan.fromJson(Map<String, dynamic> j) => WeekMealPlan(
    weekStart: DateTime.parse(j['weekStart'] as String),
    days: (j['days'] as List)
        .map((e) => DayMealPlan.fromJson(e as Map<String, dynamic>))
        .toList(),
    prepSessions: (j['prepSessions'] as List? ?? const [])
        .map((e) => PrepSession.fromJson(e as Map<String, dynamic>))
        .toList(),
    generatedAt: DateTime.parse(j['generatedAt'] as String),
  );
}
