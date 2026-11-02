enum Goal { maintenance, cut, bulk }

extension GoalLabel on Goal {
  String get label => switch (this) {
    Goal.maintenance => 'Mantenimento / performance',
    Goal.cut => 'Dimagrimento',
    Goal.bulk => 'Aumento massa',
  };

  /// Velocità di variazione del peso di default (kg/settimana).
  double get defaultRate => switch (this) {
    Goal.maintenance => 0,
    Goal.cut => 0.4,
    Goal.bulk => 0.25,
  };

  double get defaultProteinPerKg => switch (this) {
    Goal.maintenance => 1.6,
    Goal.cut => 2.2,
    Goal.bulk => 1.8,
  };
}

/// Un piano nutrizionale che l'utente può scegliere e "portare avanti".
/// Solo un piano alla volta è attivo.
class NutritionPlan {
  final String id;
  final String name;
  final Goal goal;
  final DateTime startDate;
  final DateTime? endDate;

  /// kg/settimana da perdere (cut) o guadagnare (bulk). Ignorato in mantenimento.
  final double ratePerWeek;
  final double proteinPerKg;
  final bool active;

  const NutritionPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.startDate,
    this.endDate,
    required this.ratePerWeek,
    required this.proteinPerKg,
    this.active = false,
  });

  NutritionPlan copyWith({
    String? name,
    Goal? goal,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    double? ratePerWeek,
    double? proteinPerKg,
    bool? active,
  }) => NutritionPlan(
    id: id,
    name: name ?? this.name,
    goal: goal ?? this.goal,
    startDate: startDate ?? this.startDate,
    endDate: clearEndDate ? null : (endDate ?? this.endDate),
    ratePerWeek: ratePerWeek ?? this.ratePerWeek,
    proteinPerKg: proteinPerKg ?? this.proteinPerKg,
    active: active ?? this.active,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'goal': goal.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'ratePerWeek': ratePerWeek,
    'proteinPerKg': proteinPerKg,
    'active': active,
  };

  factory NutritionPlan.fromJson(Map<String, dynamic> j) {
    final goal = Goal.values.byName(j['goal'] as String);
    return NutritionPlan(
      id: j['id'] as String,
      name: j['name'] as String,
      goal: goal,
      startDate: DateTime.parse(j['startDate'] as String),
      endDate: j['endDate'] == null ? null : DateTime.parse(j['endDate']),
      ratePerWeek: (j['ratePerWeek'] as num?)?.toDouble() ?? goal.defaultRate,
      proteinPerKg:
          (j['proteinPerKg'] as num?)?.toDouble() ?? goal.defaultProteinPerKg,
      active: j['active'] as bool? ?? false,
    );
  }
}
