enum Sex { male, female }

/// Dati antropometrici e preferenze di base dell'utente.
class UserProfile {
  final Sex sex;
  final int birthYear;
  final double heightCm;
  final double weightKg;

  /// Moltiplicatore del metabolismo basale per le attività NON sportive
  /// (lavoro, spostamenti). 1.2 = sedentario, 1.4 = lavoro in piedi.
  final double lifestyleFactor;

  /// Numero di pasti al giorno (3-5).
  final int mealsPerDay;

  /// Se true, il peso viene aggiornato dai dati wellness di intervals.icu.
  final bool syncWeightFromIntervals;

  const UserProfile({
    this.sex = Sex.male,
    this.birthYear = 1990,
    this.heightCm = 175,
    this.weightKg = 70,
    this.lifestyleFactor = 1.3,
    this.mealsPerDay = 4,
    this.syncWeightFromIntervals = true,
  });

  int ageAt(DateTime date) => date.year - birthYear;

  UserProfile copyWith({
    Sex? sex,
    int? birthYear,
    double? heightCm,
    double? weightKg,
    double? lifestyleFactor,
    int? mealsPerDay,
    bool? syncWeightFromIntervals,
  }) => UserProfile(
    sex: sex ?? this.sex,
    birthYear: birthYear ?? this.birthYear,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    lifestyleFactor: lifestyleFactor ?? this.lifestyleFactor,
    mealsPerDay: mealsPerDay ?? this.mealsPerDay,
    syncWeightFromIntervals:
        syncWeightFromIntervals ?? this.syncWeightFromIntervals,
  );

  Map<String, dynamic> toJson() => {
    'sex': sex.name,
    'birthYear': birthYear,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'lifestyleFactor': lifestyleFactor,
    'mealsPerDay': mealsPerDay,
    'syncWeightFromIntervals': syncWeightFromIntervals,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    sex: Sex.values.byName(j['sex'] as String? ?? 'male'),
    birthYear: (j['birthYear'] as num?)?.toInt() ?? 1990,
    heightCm: (j['heightCm'] as num?)?.toDouble() ?? 175,
    weightKg: (j['weightKg'] as num?)?.toDouble() ?? 70,
    lifestyleFactor: (j['lifestyleFactor'] as num?)?.toDouble() ?? 1.3,
    mealsPerDay: (j['mealsPerDay'] as num?)?.toInt() ?? 4,
    syncWeightFromIntervals: j['syncWeightFromIntervals'] as bool? ?? true,
  );
}
