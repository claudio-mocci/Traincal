import 'food.dart';
import 'recipe.dart';

/// Un pasto assegnato a un giorno: ricetta + numero di porzioni (scalate
/// sul fabbisogno di quel giorno).
class MealEntry {
  final MealSlot slot;
  final String recipeId;
  final double servings;

  /// Porzioni impostate a mano: il ribilanciamento della giornata non le
  /// tocca.
  final bool locked;

  /// Pasto bloccato: rigenerando il menu mantiene la sua ricetta.
  final bool recipeLocked;

  const MealEntry(
    this.slot,
    this.recipeId,
    this.servings, {
    this.locked = false,
    this.recipeLocked = false,
  });

  MealEntry copyWith({
    String? recipeId,
    double? servings,
    bool? locked,
    bool? recipeLocked,
  }) => MealEntry(
    slot,
    recipeId ?? this.recipeId,
    servings ?? this.servings,
    locked: locked ?? this.locked,
    recipeLocked: recipeLocked ?? this.recipeLocked,
  );

  Map<String, dynamic> toJson() => {
    'slot': slot.name,
    'recipeId': recipeId,
    'servings': servings,
    if (locked) 'locked': true,
    if (recipeLocked) 'recipeLocked': true,
  };

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
    MealSlot.values.byName(j['slot'] as String),
    j['recipeId'] as String,
    (j['servings'] as num).toDouble(),
    locked: j['locked'] as bool? ?? false,
    recipeLocked: j['recipeLocked'] as bool? ?? false,
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

/// Stato di un pasto nella pianificazione della settimana.
enum MealStatus {
  /// Preparato con il meal prep.
  planned,

  /// Fuori dal meal prep (es. cena fuori): tiene la sua quota di calorie.
  free,

  /// Eliminato: la sua quota si ridistribuisce sugli altri pasti del giorno.
  removed,
}

class DayMealPlan {
  final DateTime date;

  /// Fabbisogno dell'intera giornata, pasti liberi compresi.
  final Macros target;
  final List<MealEntry> meals;
  final List<ExtraFood> extras;

  /// Pasti fuori dal meal prep (es. cena fuori): mantengono la loro quota del
  /// fabbisogno, ma senza ricetta, preparazione né spesa.
  final List<MealSlot> freeSlots;

  /// Pasti eliminati: la loro quota passa agli altri pasti del giorno.
  final List<MealSlot> removedSlots;

  /// Giorno bloccato: la rigenerazione del menu non lo modifica.
  final bool locked;

  const DayMealPlan({
    required this.date,
    required this.target,
    required this.meals,
    this.extras = const [],
    this.freeSlots = const [],
    this.removedSlots = const [],
    this.locked = false,
  });

  /// Numero di pasti della giornata, contando liberi ed eliminati.
  int get slotCount => meals.length + freeSlots.length + removedSlots.length;

  MealStatus statusOf(MealSlot slot) => freeSlots.contains(slot)
      ? MealStatus.free
      : removedSlots.contains(slot)
      ? MealStatus.removed
      : MealStatus.planned;

  DayMealPlan copyWith({
    Macros? target,
    List<MealEntry>? meals,
    List<ExtraFood>? extras,
    List<MealSlot>? freeSlots,
    List<MealSlot>? removedSlots,
    bool? locked,
  }) => DayMealPlan(
    date: date,
    target: target ?? this.target,
    meals: meals ?? this.meals,
    extras: extras ?? this.extras,
    freeSlots: freeSlots ?? this.freeSlots,
    removedSlots: removedSlots ?? this.removedSlots,
    locked: locked ?? this.locked,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'target': target.toJson(),
    'meals': meals.map((e) => e.toJson()).toList(),
    'extras': extras.map((e) => e.toJson()).toList(),
    if (freeSlots.isNotEmpty)
      'freeSlots': freeSlots.map((s) => s.name).toList(),
    if (removedSlots.isNotEmpty)
      'removedSlots': removedSlots.map((s) => s.name).toList(),
    if (locked) 'locked': true,
  };

  factory DayMealPlan.fromJson(Map<String, dynamic> j) {
    List<MealSlot> slots(String key) => ((j[key] as List?) ?? const [])
        .map((s) => MealSlot.values.byName(s as String))
        .toList();
    return DayMealPlan(
      date: DateTime.parse(j['date'] as String),
      target: Macros.fromJson(j['target'] as Map<String, dynamic>),
      meals: (j['meals'] as List)
          .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      extras: (j['extras'] as List? ?? const [])
          .map((e) => ExtraFood.fromJson(e as Map<String, dynamic>))
          .toList(),
      freeSlots: slots('freeSlots'),
      removedSlots: slots('removedSlots'),
      locked: j['locked'] as bool? ?? false,
    );
  }
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

/// Come si organizzano pranzi e cene della settimana.
enum MealPrepStyle {
  /// Più ricette per sessione di cucina, alternate tra i pasti.
  recipes,

  /// Basi, proteine e verdure cucinate a parte e combinate ogni pasto.
  components,
}

extension MealPrepStyleLabel on MealPrepStyle {
  String get label => switch (this) {
    MealPrepStyle.recipes => 'Ricette alternate',
    MealPrepStyle.components => 'Componenti da combinare',
  };

  String get shortLabel => switch (this) {
    MealPrepStyle.recipes => 'Piatti',
    MealPrepStyle.components => 'Componenti',
  };
}

class WeekMealPlan {
  /// Lunedì della settimana; usato anche come id del documento.
  final DateTime weekStart;
  final List<DayMealPlan> days;
  final List<PrepSession> prepSessions;
  final DateTime generatedAt;

  /// Ricette create per questo piano (combinazioni e singoli componenti),
  /// che non fanno parte del ricettario.
  final List<Recipe> generatedRecipes;

  /// Per ogni combinazione, i componenti da cucinare (id di ricette in
  /// [generatedRecipes]).
  final Map<String, List<String>> combos;

  const WeekMealPlan({
    required this.weekStart,
    required this.days,
    required this.prepSessions,
    required this.generatedAt,
    this.generatedRecipes = const [],
    this.combos = const {},
  });

  String get id => weekStart.toIso8601String().substring(0, 10);

  WeekMealPlan copyWith({
    List<DayMealPlan>? days,
    List<PrepSession>? prepSessions,
    DateTime? generatedAt,
  }) => WeekMealPlan(
    weekStart: weekStart,
    days: days ?? this.days,
    prepSessions: prepSessions ?? this.prepSessions,
    generatedAt: generatedAt ?? this.generatedAt,
    generatedRecipes: generatedRecipes,
    combos: combos,
  );

  Map<String, dynamic> toJson() => {
    'weekStart': weekStart.toIso8601String(),
    'days': days.map((e) => e.toJson()).toList(),
    'prepSessions': prepSessions.map((e) => e.toJson()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
    'generatedRecipes': generatedRecipes.map((r) => r.toJson()).toList(),
    'combos': combos,
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
    generatedRecipes: (j['generatedRecipes'] as List? ?? const [])
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList(),
    combos: {
      for (final e in ((j['combos'] as Map?) ?? const {}).entries)
        e.key as String: (e.value as List).cast<String>(),
    },
  );
}
