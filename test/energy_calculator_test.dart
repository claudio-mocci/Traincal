import 'package:flutter_test/flutter_test.dart';
import 'package:traincal/models/nutrition_plan.dart';
import 'package:traincal/models/profile.dart';
import 'package:traincal/models/workout.dart';
import 'package:traincal/services/energy_calculator.dart';

void main() {
  const profile = UserProfile(
    sex: Sex.male,
    birthYear: 1990,
    heightCm: 180,
    weightKg: 75,
    lifestyleFactor: 1.3,
  );
  final monday = DateTime(2026, 11, 2);
  final week = List.generate(7, (i) => monday.add(Duration(days: i)));

  Workout planned(
    int day,
    String type,
    int minutes, {
    int? load,
    double? km,
    int? joules,
  }) => Workout(
    id: 'e$day$type',
    completed: false,
    eventId: day * 10,
    date: week[day],
    icuType: type,
    name: type,
    movingTimeSec: minutes * 60,
    trainingLoad: load,
    distanceM: km == null ? null : km * 1000,
    joules: joules,
  );

  test('BMR Mifflin-St Jeor', () {
    // 10*75 + 6.25*180 - 5*36 + 5 = 1700
    expect(EnergyCalculator.bmr(profile, DateTime(2026, 6, 1)), 1700);
    expect(
      EnergyCalculator.bmr(profile.copyWith(sex: Sex.female), DateTime(2026)),
      1534,
    );
  });

  test('stima per fonte: misurata, kJ, distanza, MET', () {
    const perHour = 1700 * 1.3 / 24;
    final measured = Workout(
      id: 'a1',
      completed: true,
      date: monday,
      icuType: 'Run',
      name: 'x',
      movingTimeSec: 3600,
      calories: 800,
    );
    final e1 = EnergyCalculator.workoutEnergy(measured, profile, perHour);
    expect(e1.source, EstimateSource.measured);
    expect(e1.grossKcal, 800);
    expect(e1.netKcal, closeTo(800 - perHour, 0.01));

    final ride = planned(0, 'Ride', 120, joules: 2000000);
    final e2 = EnergyCalculator.workoutEnergy(ride, profile, perHour);
    expect(e2.source, EstimateSource.power);
    expect(e2.grossKcal, closeTo(1992, 1));
    expect(e2.fuelingCarbsPerHour, 45);

    final run = planned(0, 'Run', 50, km: 10);
    final e3 = EnergyCalculator.workoutEnergy(run, profile, perHour);
    expect(e3.source, EstimateSource.distance);
    expect(e3.grossKcal, 750);

    final gym = planned(0, 'WeightTraining', 60);
    final e4 = EnergyCalculator.workoutEnergy(gym, profile, perHour);
    expect(e4.source, EstimateSource.met);
    expect(e4.grossKcal, 5.0 * 75);
    expect(e4.fuelingCarbsPerHour, 0);
  });

  test('evento pianificato già svolto non viene contato due volte', () {
    final event = planned(0, 'Run', 60, load: 60);
    final done = Workout(
      id: 'a1',
      completed: true,
      pairedEventId: event.eventId,
      date: week[0],
      icuType: 'Run',
      name: 'Corsa',
      movingTimeSec: 3500,
      calories: 700,
    );
    final grouped = EnergyCalculator.byDay([event, done], today: week[3]);
    expect(grouped[week[0]]!.map((w) => w.id), ['a1']);
  });

  test('mantenimento: target = dispendio, macro coerenti', () {
    final days = EnergyCalculator.computeDays(
      days: week,
      workouts: [planned(1, 'Run', 60, load: 70, km: 12)],
      profile: profile,
      plan: null,
      today: monday,
    );
    expect(days, hasLength(7));
    final rest = days[0];
    expect(rest.load, DayLoad.rest);
    expect(rest.target.kcal, closeTo(rest.tdee, 0.01));
    expect(days[1].target.kcal, greaterThan(rest.target.kcal + 700));
    for (final d in days) {
      final fromMacros =
          d.target.protein * 4 + d.target.carbs * 4 + d.target.fat * 9;
      expect(fromMacros, closeTo(d.target.kcal, 1));
      expect(d.target.protein, closeTo(1.6 * 75, 0.01));
    }
  });

  test('dimagrimento: deficit settimanale rispettato e periodizzato', () {
    final plan = NutritionPlan(
      id: 'p',
      name: 'cut',
      goal: Goal.cut,
      startDate: monday,
      ratePerWeek: 0.5,
      proteinPerKg: 2.2,
    );
    final days = EnergyCalculator.computeDays(
      days: week,
      workouts: [
        planned(2, 'Ride', 180, load: 150, joules: 2500000),
        planned(4, 'Run', 45, load: 50, km: 9),
      ],
      profile: profile,
      plan: plan,
      today: monday,
    );
    final weekly = days.fold<double>(0, (s, d) => s + d.goalAdjustment);
    // Il deficit richiesto (-3850) è quasi raggiungibile con i limiti
    // giornalieri: la parte eccedente si sposta sui giorni con margine.
    expect(weekly, inInclusiveRange(-0.5 * 7700, -0.9 * 0.5 * 7700));
    final hard = days[2];
    final rest = days[0];
    expect(hard.load, DayLoad.hard);
    expect(
      hard.goalAdjustment.abs(),
      lessThanOrEqualTo(0.10 * hard.tdee + 0.01),
    );
    expect(hard.goalAdjustment.abs(), lessThan(rest.goalAdjustment.abs()));
    for (final d in days) {
      expect(d.target.kcal, greaterThanOrEqualTo(d.bmr));
    }
  });

  test('aumento massa: surplus limitato al 15%', () {
    final plan = NutritionPlan(
      id: 'p',
      name: 'bulk',
      goal: Goal.bulk,
      startDate: monday,
      ratePerWeek: 0.5,
      proteinPerKg: 1.8,
    );
    final days = EnergyCalculator.computeDays(
      days: week,
      workouts: const [],
      profile: profile,
      plan: plan,
    );
    for (final d in days) {
      expect(d.goalAdjustment, greaterThan(0));
      expect(d.goalAdjustment, lessThanOrEqualTo(0.15 * d.tdee + 0.01));
    }
  });
}
