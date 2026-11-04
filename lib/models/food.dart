/// Valori nutrizionali per 100 g di alimento (crudo / secco, come si acquista).
class Macros {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const Macros(this.kcal, this.protein, this.carbs, this.fat);

  static const zero = Macros(0, 0, 0, 0);

  Macros operator +(Macros o) =>
      Macros(kcal + o.kcal, protein + o.protein, carbs + o.carbs, fat + o.fat);

  Macros operator -(Macros o) =>
      Macros(kcal - o.kcal, protein - o.protein, carbs - o.carbs, fat - o.fat);

  Macros scale(double f) => Macros(kcal * f, protein * f, carbs * f, fat * f);

  Map<String, dynamic> toJson() => {
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory Macros.fromJson(Map<String, dynamic> j) => Macros(
    (j['kcal'] as num).toDouble(),
    (j['protein'] as num).toDouble(),
    (j['carbs'] as num).toDouble(),
    (j['fat'] as num).toDouble(),
  );

  @override
  String toString() =>
      '${kcal.round()} kcal · P ${protein.round()} · C ${carbs.round()} · G ${fat.round()}';
}

/// Reparti del supermercato, usati per raggruppare la lista della spesa.
enum FoodCategory {
  meatFish,
  dairyEggs,
  grains,
  legumes,
  fruit,
  vegetables,
  nutsSeeds,
  pantry,
  frozen,
}

extension FoodCategoryLabel on FoodCategory {
  String get label => switch (this) {
    FoodCategory.meatFish => 'Carne e pesce',
    FoodCategory.dairyEggs => 'Latticini e uova',
    FoodCategory.grains => 'Cereali, pane e patate',
    FoodCategory.legumes => 'Legumi e proteine vegetali',
    FoodCategory.fruit => 'Frutta',
    FoodCategory.vegetables => 'Verdura',
    FoodCategory.nutsSeeds => 'Frutta secca e semi',
    FoodCategory.pantry => 'Dispensa e condimenti',
    FoodCategory.frozen => 'Surgelati',
  };
}

class Food {
  final String id;
  final String name;
  final FoodCategory category;
  final Macros per100g;

  /// Peso di un'unità (es. 1 uovo = 55 g), per mostrare la spesa in pezzi.
  final double? unitGrams;
  final String? unitName;

  /// Confezione tipica, per arrotondare la lista della spesa.
  final double? packageGrams;

  /// Mesi di stagione (1-12); vuoto se disponibile tutto l'anno.
  final List<int> seasonMonths;

  final bool builtin;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.per100g,
    this.unitGrams,
    this.unitName,
    this.packageGrams,
    this.seasonMonths = const [],
    this.builtin = false,
  });

  Macros forGrams(double g) => per100g.scale(g / 100);

  bool get isSeasonal => seasonMonths.isNotEmpty;

  bool inSeason(DateTime d) =>
      seasonMonths.isEmpty || seasonMonths.contains(d.month);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'per100g': per100g.toJson(),
    'unitGrams': unitGrams,
    'unitName': unitName,
    'packageGrams': packageGrams,
    'seasonMonths': seasonMonths,
  };

  factory Food.fromJson(Map<String, dynamic> j, {bool builtin = false}) => Food(
    id: j['id'] as String,
    name: j['name'] as String,
    category:
        FoodCategory.values.asNameMap()[j['category']] ?? FoodCategory.pantry,
    per100g: Macros.fromJson(j['per100g'] as Map<String, dynamic>),
    unitGrams: (j['unitGrams'] as num?)?.toDouble(),
    unitName: j['unitName'] as String?,
    packageGrams: (j['packageGrams'] as num?)?.toDouble(),
    seasonMonths: ((j['seasonMonths'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList(),
    builtin: builtin,
  );
}
