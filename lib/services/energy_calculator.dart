import 'dart:math';

import '../models/food.dart';
import '../models/nutrition_plan.dart';
import '../models/profile.dart';
import '../models/workout.dart';

enum EstimateSource { measured, power, distance, met }

extension EstimateSourceLabel on EstimateSource {
  String get label => switch (this) {
    EstimateSource.measured => 'misurate dal dispositivo',
    EstimateSource.power => 'da lavoro meccanico (kJ)',
    EstimateSource.distance => 'da distanza',
    EstimateSource.met => 'stima MET',
  };
}

class WorkoutEnergy {
  final Workout workout;

  /// Calorie totali spese durante la seduta.
  final double grossKcal;

  /// Calorie al netto di quelle che si sarebbero spese comunque a riposo.
  final double netKcal;
  final EstimateSource source;

  /// Carboidrati consigliati durante la seduta (g/h), 0 se non serve.
  final int fuelingCarbsPerHour;

  const WorkoutEnergy(
    this.workout,
    this.grossKcal,
    this.netKcal,
    this.source,
    this.fuelingCarbsPerHour,
  );
}

enum DayLoad { rest, light, moderate, hard }

extension DayLoadLabel on DayLoad {
  String get label => switch (this) {
    DayLoad.rest => 'Riposo',
    DayLoad.light => 'Leggero',
    DayLoad.moderate => 'Moderato',
    DayLoad.hard => 'Intenso',
  };

  /// Linee guida ISSN/ACSM sui carboidrati giornalieri, g/kg.
  double get carbsPerKg => switch (this) {
    DayLoad.rest => 3,
    DayLoad.light => 4.5,
    DayLoad.moderate => 6,
    DayLoad.hard => 8,
  };
}

class DayEnergy {
  final DateTime date;
  final double bmr;

  /// Dispendio senza sport (BMR × fattore stile di vita).
  final double baseline;
  final List<WorkoutEnergy> workouts;
  final double tdee;

  /// Correzione dovuta all'obiettivo (negativa in deficit).
  final double goalAdjustment;
  final Macros target;
  final DayLoad load;

  /// Carboidrati consigliati dalle linee guida per il carico del giorno.
  final double recommendedCarbs;

  const DayEnergy({
    required this.date,
    required this.bmr,
    required this.baseline,
    required this.workouts,
    required this.tdee,
    required this.goalAdjustment,
    required this.target,
    required this.load,
    required this.recommendedCarbs,
  });

  double get exerciseKcal => workouts.fold(0, (s, w) => s + w.netKcal);
}

/// Stima il fabbisogno calorico giornaliero e i macronutrienti.
///
/// Modello: Mifflin-St Jeor × fattore stile di vita + dispendio netto degli
/// allenamenti; l'obiettivo del piano (deficit/surplus) è distribuito sulla
/// settimana pesando meno i giorni con allenamenti intensi.
class EnergyCalculator {
  static const kcalPerKgBodyMass = 7700.0;

  static double bmr(UserProfile p, DateTime date) {
    final base =
        10 * p.weightKg + 6.25 * p.heightCm - 5 * p.ageAt(date).toDouble();
    return p.sex == Sex.male ? base + 5 : base - 161;
  }

  static WorkoutEnergy workoutEnergy(
    Workout w,
    UserProfile p,
    double baselinePerHour,
  ) {
    double gross;
    EstimateSource source;
    final hours = w.hours;

    if (w.completed && (w.calories ?? 0) > 0) {
      gross = w.calories!.toDouble();
      source = EstimateSource.measured;
    } else if ((w.joules ?? 0) > 0) {
      // Efficienza meccanica ~24%: 1 kJ di lavoro ≈ 1 kcal spesa.
      gross = w.joules! / 1000 / 4.184 / 0.24;
      source = EstimateSource.power;
    } else if (w.sport == Sport.ride && w.ftp != null && _if(w) != null) {
      final watts = _if(w)! * w.ftp!;
      gross = watts * w.movingTimeSec / 1000 / 4.184 / 0.24;
      source = EstimateSource.power;
    } else if ((w.sport == Sport.run || w.sport == Sport.walk) &&
        (w.distanceM ?? 0) > 0) {
      // Corsa ≈ 1 kcal/kg/km, camminata ≈ 0.6.
      final factor = w.sport == Sport.run ? 1.0 : 0.6;
      gross = factor * p.weightKg * w.distanceM! / 1000;
      source = EstimateSource.distance;
    } else {
      gross = _met(w) * p.weightKg * hours;
      source = EstimateSource.met;
    }

    final net = max(0.0, gross - baselinePerHour * hours);
    return WorkoutEnergy(w, gross, net, source, _fueling(w));
  }

  /// Intensity factor (0-1+) dai dati disponibili.
  static double? _if(Workout w) {
    if (w.intensity != null && w.intensity! > 0) return w.intensity! / 100;
    if (w.trainingLoad != null && w.hours > 0) {
      // TSS = h × IF² × 100  =>  IF = sqrt(TSS / (h × 100))
      return sqrt(w.trainingLoad! / (w.hours * 100));
    }
    return null;
  }

  static double _met(Workout w) {
    final intensity = _if(w);
    double pick(double easy, double mid, double hard) {
      if (intensity == null) return mid;
      if (intensity < 0.72) return easy;
      if (intensity < 0.85) return mid;
      return hard;
    }

    return switch (w.sport) {
      Sport.run => pick(8.5, 10.5, 12.5),
      Sport.ride => pick(6.0, 8.0, 10.5),
      Sport.strength => pick(3.5, 5.0, 6.0),
      Sport.swim => pick(6.0, 8.0, 10.0),
      Sport.walk => pick(3.0, 3.8, 5.0),
      Sport.other => pick(4.0, 5.5, 7.5),
    };
  }

  static int _fueling(Workout w) {
    if (w.sport == Sport.strength) return 0;
    final min = w.movingTimeSec / 60;
    if (min < 75) return 0;
    if (min < 150) return 45;
    return 75;
  }

  static DayLoad _dayLoad(List<WorkoutEnergy> ws) {
    if (ws.isEmpty) return DayLoad.rest;
    final kcal = ws.fold<double>(0, (s, w) => s + w.netKcal);
    final load = ws.fold<int>(0, (s, w) => s + (w.workout.trainingLoad ?? 0));
    final minutes = ws.fold<int>(0, (s, w) => s + w.workout.movingTimeSec) / 60;
    if (kcal > 1000 || load > 120 || minutes > 150) return DayLoad.hard;
    if (kcal > 500 || load > 60 || minutes > 70) return DayLoad.moderate;
    return DayLoad.light;
  }

  /// Raggruppa gli allenamenti per giorno ed elimina i doppioni: un evento
  /// pianificato già svolto è sostituito dall'attività abbinata.
  static Map<DateTime, List<Workout>> byDay(
    List<Workout> workouts, {
    DateTime? today,
  }) {
    final done = workouts.where((w) => w.completed).toList();
    final pairedEvents = done
        .map((w) => w.pairedEventId)
        .whereType<int>()
        .toSet();
    final doneDays = done.map((w) => w.day).toSet();
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    final map = <DateTime, List<Workout>>{};
    for (final w in workouts) {
      if (!w.completed) {
        if (pairedEvents.contains(w.eventId)) continue;
        // Evento passato non abbinato ma con attività nello stesso giorno:
        // probabilmente svolto senza abbinamento automatico.
        if (w.day.isBefore(todayDate) && doneDays.contains(w.day)) continue;
      }
      map.putIfAbsent(w.day, () => []).add(w);
    }
    return map;
  }

  /// Calcola i target per ciascun giorno dell'intervallo [days].
  static List<DayEnergy> computeDays({
    required List<DateTime> days,
    required List<Workout> workouts,
    required UserProfile profile,
    required NutritionPlan? plan,
    DateTime? today,
  }) {
    final grouped = byDay(workouts, today: today);
    final goal = plan?.goal ?? Goal.maintenance;
    final proteinPerKg = plan?.proteinPerKg ?? goal.defaultProteinPerKg;
    final w = profile.weightKg;

    // 1) Dispendio per giorno.
    final raw =
        <
          ({
            DateTime date,
            double bmr,
            double baseline,
            List<WorkoutEnergy> ws,
            double tdee,
            DayLoad load,
          })
        >[];
    for (final d in days) {
      final b = bmr(profile, d);
      final baseline = b * profile.lifestyleFactor;
      final ws = (grouped[d] ?? const [])
          .map((x) => workoutEnergy(x, profile, baseline / 24))
          .toList();
      final ex = ws.fold<double>(0, (s, x) => s + x.netKcal);
      raw.add((
        date: d,
        bmr: b,
        baseline: baseline,
        ws: ws,
        tdee: baseline + ex,
        load: _dayLoad(ws),
      ));
    }

    // 2) Correzione per obiettivo, periodizzata sul carico.
    final rate = plan?.ratePerWeek ?? 0;
    final dailyDelta = switch (goal) {
      Goal.maintenance => 0.0,
      Goal.cut => -rate * kcalPerKgBodyMass / 7,
      Goal.bulk => rate * kcalPerKgBodyMass / 7,
    };
    double weightFor(DayLoad l) => switch (goal) {
      // In deficit si taglia di più nei giorni leggeri.
      Goal.cut => switch (l) {
        DayLoad.rest => 1.3,
        DayLoad.light => 1.15,
        DayLoad.moderate => 0.85,
        DayLoad.hard => 0.5,
      },
      // In surplus si aggiunge di più nei giorni di allenamento.
      Goal.bulk => l == DayLoad.rest ? 0.8 : 1.1,
      Goal.maintenance => 1,
    };
    final weights = raw.map((r) => weightFor(r.load)).toList();

    // Limiti di sicurezza: mai sotto il BMR, surplus max 15%; il deficit è
    // al massimo il 25% del dispendio, ridotto nei giorni con sedute chiave
    // per non comprometterne qualità e recupero.
    double limit(int i) {
      final r = raw[i];
      if (dailyDelta >= 0) return 0.15 * r.tdee;
      final pct = switch (r.load) {
        DayLoad.hard => 0.10,
        DayLoad.moderate => 0.20,
        _ => 0.25,
      };
      return min(pct * r.tdee, r.tdee - r.bmr).clamp(0, double.infinity);
    }

    // Ripartisce il totale settimanale in proporzione ai pesi; la parte che
    // supera il limite di un giorno passa ai giorni che hanno ancora margine.
    final adjustments = List.filled(raw.length, 0.0);
    var remaining = (dailyDelta * raw.length).abs();
    final open = {for (var i = 0; i < raw.length; i++) i};
    while (remaining > 0.5 && open.isNotEmpty) {
      final wsum = open.fold<double>(0, (s, i) => s + weights[i]);
      var assigned = 0.0;
      for (final i in open.toList()) {
        final share = remaining * weights[i] / wsum;
        final room = limit(i) - adjustments[i];
        final take = min(share, room);
        adjustments[i] += take;
        assigned += take;
        if (take >= room) open.remove(i);
      }
      remaining -= assigned;
      if (assigned < 0.5) break;
    }

    final result = <DayEnergy>[];
    for (var i = 0; i < raw.length; i++) {
      final r = raw[i];
      final adj = dailyDelta < 0 ? -adjustments[i] : adjustments[i];
      final kcal = r.tdee + adj;

      // 3) Macro: proteine fisse per kg, grassi 25% (0.8-1.2 g/kg), resto carbo.
      final protein = proteinPerKg * w;
      final fat = (0.25 * kcal / 9).clamp(0.8 * w, 1.2 * w).toDouble();
      final carbs = max(0.0, (kcal - protein * 4 - fat * 9) / 4);

      result.add(
        DayEnergy(
          date: r.date,
          bmr: r.bmr,
          baseline: r.baseline,
          workouts: r.ws,
          tdee: r.tdee,
          goalAdjustment: adj,
          target: Macros(kcal, protein, carbs, fat),
          load: r.load,
          recommendedCarbs: r.load.carbsPerKg * w,
        ),
      );
    }
    return result;
  }
}
