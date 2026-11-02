import 'food.dart';

enum MealSlot { breakfast, morningSnack, lunch, afternoonSnack, dinner }

extension MealSlotLabel on MealSlot {
  String get label => switch (this) {
    MealSlot.breakfast => 'Colazione',
    MealSlot.morningSnack => 'Spuntino mattina',
    MealSlot.lunch => 'Pranzo',
    MealSlot.afternoonSnack => 'Spuntino pomeriggio',
    MealSlot.dinner => 'Cena',
  };

  MealType get type => switch (this) {
    MealSlot.breakfast => MealType.breakfast,
    MealSlot.morningSnack || MealSlot.afternoonSnack => MealType.snack,
    MealSlot.lunch || MealSlot.dinner => MealType.main,
  };
}

/// Tipologia di ricetta: i pasti principali sono quelli da meal prep.
enum MealType { breakfast, main, snack }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
    MealType.breakfast => 'Colazione',
    MealType.main => 'Pranzo / cena',
    MealType.snack => 'Spuntino',
  };
}

enum RecipeSource { builtin, user, ai }

class Ingredient {
  final String foodId;

  /// Grammi per porzione.
  final double grams;

  const Ingredient(this.foodId, this.grams);

  Map<String, dynamic> toJson() => {'foodId': foodId, 'grams': grams};

  factory Ingredient.fromJson(Map<String, dynamic> j) =>
      Ingredient(j['foodId'] as String, (j['grams'] as num).toDouble());
}

class Recipe {
  final String id;
  final String name;
  final MealType type;
  final List<Ingredient> ingredients;
  final String instructions;

  /// Fonte proteica principale (pollo, pesce, legumi...), per variare il menu.
  final String mainProtein;

  /// Giorni di conservazione in frigo dopo la preparazione.
  final int fridgeDays;
  final bool freezable;
  final int prepMinutes;
  final RecipeSource source;

  const Recipe({
    required this.id,
    required this.name,
    required this.type,
    required this.ingredients,
    this.instructions = '',
    this.mainProtein = '',
    this.fridgeDays = 3,
    this.freezable = false,
    this.prepMinutes = 30,
    this.source = RecipeSource.user,
  });

  Macros macrosPerServing(Map<String, Food> foods) {
    var m = Macros.zero;
    for (final i in ingredients) {
      final f = foods[i.foodId];
      if (f != null) m = m + f.forGrams(i.grams);
    }
    return m;
  }

  Recipe copyWith({
    String? id,
    String? name,
    MealType? type,
    List<Ingredient>? ingredients,
    String? instructions,
    String? mainProtein,
    int? fridgeDays,
    bool? freezable,
    int? prepMinutes,
    RecipeSource? source,
  }) => Recipe(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    ingredients: ingredients ?? this.ingredients,
    instructions: instructions ?? this.instructions,
    mainProtein: mainProtein ?? this.mainProtein,
    fridgeDays: fridgeDays ?? this.fridgeDays,
    freezable: freezable ?? this.freezable,
    prepMinutes: prepMinutes ?? this.prepMinutes,
    source: source ?? this.source,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'instructions': instructions,
    'mainProtein': mainProtein,
    'fridgeDays': fridgeDays,
    'freezable': freezable,
    'prepMinutes': prepMinutes,
    'source': source.name,
  };

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
    id: j['id'] as String,
    name: j['name'] as String,
    type: MealType.values.byName(j['type'] as String),
    ingredients: (j['ingredients'] as List)
        .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
        .toList(),
    instructions: j['instructions'] as String? ?? '',
    mainProtein: j['mainProtein'] as String? ?? '',
    fridgeDays: (j['fridgeDays'] as num?)?.toInt() ?? 3,
    freezable: j['freezable'] as bool? ?? false,
    prepMinutes: (j['prepMinutes'] as num?)?.toInt() ?? 30,
    source: RecipeSource.values.asNameMap()[j['source']] ?? RecipeSource.user,
  );
}
