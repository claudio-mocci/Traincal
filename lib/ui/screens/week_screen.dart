import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food.dart';
import '../../models/nutrition_plan.dart';
import '../../services/energy_calculator.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/week_selector.dart';

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final days = s.weekEnergy;
    final total = days.fold(Macros.zero, (a, d) => a + d.target);
    final avg = total.scale(1 / days.length);
    final plan = s.activePlan;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const WeekSelector(),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: plan?.id,
                        hint: const Text('Nessun piano attivo (mantenimento)'),
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final p in s.plans)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} · ${p.goal.label}'),
                            ),
                        ],
                        onChanged: (id) =>
                            id == null ? null : s.activatePlan(id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Media giornaliera della settimana',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                MacroRow(avg),
                const SizedBox(height: 8),
                Text(
                  'Peso ${s.profile.weightKg.toStringAsFixed(1)} kg · '
                  'totale settimana ${total.kcal.round()} kcal'
                  '${plan != null && plan.goal != Goal.maintenance ? ' · obiettivo ${plan.goal == Goal.cut ? '-' : '+'}${plan.ratePerWeek} kg/sett.' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (plan != null && plan.goal != Goal.maintenance)
                  _GoalCoverage(days, plan),
              ],
            ),
          ),
        ),
        if (!s.intervalsConfigured)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Collega intervals.icu (icona impostazioni in alto) per '
              'importare gli allenamenti pianificati e svolti.',
            ),
          ),
        SectionTitle(
          'Giorni',
          trailing: s.intervalsConfigured
              ? TextButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Pubblica su intervals.icu'),
                  onPressed: () async {
                    final n = await guarded(context, s.publishWeekTargets);
                    if (n != null && context.mounted) {
                      showInfo(
                        context,
                        'Pubblicati i target di $n giorni come note sul calendario',
                      );
                    }
                  },
                )
              : null,
        ),
        for (final d in days) _DayCard(d),
      ],
    );
  }
}

/// Confronta la variazione di peso richiesta con quella ottenibile entro i
/// limiti giornalieri di deficit/surplus.
class _GoalCoverage extends StatelessWidget {
  final List<DayEnergy> days;
  final NutritionPlan plan;
  const _GoalCoverage(this.days, this.plan);

  @override
  Widget build(BuildContext context) {
    final weekly = days.fold<double>(0, (s, d) => s + d.goalAdjustment);
    final kg = weekly.abs() / EnergyCalculator.kcalPerKgBodyMass;
    final short = kg < plan.ratePerWeek * 0.95;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${weekly < 0 ? 'Deficit' : 'Surplus'} della settimana: '
        '${weekly.abs().round()} kcal ≈ ${kg.toStringAsFixed(2)} kg'
        '${short ? ' (meno del richiesto: i limiti giornalieri proteggono le sedute intense)' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: short ? theme.colorScheme.tertiary : null,
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DayEnergy d;
  const _DayCard(this.d);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateUtils.isSameDay(d.date, DateTime.now());
    final carbsLow = d.target.carbs < d.recommendedCarbs * 0.8;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: today
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ExpansionTile(
        shape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                dayLongFmt.format(d.date),
                style: theme.textTheme.titleSmall,
              ),
            ),
            Chip(
              label: Text(d.load.label),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MacroRow(d.target, dense: true),
              if (d.workouts.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final w in d.workouts) _WorkoutLine(w),
              ],
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Metabolismo basale', d.bmr),
          _kv('Dispendio senza sport', d.baseline),
          _kv('Allenamenti (netto)', d.exerciseKcal),
          _kv('Dispendio totale stimato', d.tdee, bold: true),
          if (d.goalAdjustment.abs() > 1)
            _kv(
              d.goalAdjustment < 0 ? 'Deficit obiettivo' : 'Surplus obiettivo',
              d.goalAdjustment,
            ),
          _kv('Target', d.target.kcal, bold: true),
          const SizedBox(height: 8),
          Text(
            'Carboidrati consigliati per il carico (${d.load.carbsPerKg} g/kg): '
            '${d.recommendedCarbs.round()} g',
            style: theme.textTheme.bodySmall?.copyWith(
              color: carbsLow ? theme.colorScheme.error : null,
            ),
          ),
          if (carbsLow)
            Text(
              'Il target di carboidrati è sotto le linee guida: in una '
              'giornata intensa valuta di ridurre il deficit.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          for (final w in d.workouts.where((w) => w.fuelingCarbsPerHour > 0))
            Text(
              '⚡ ${w.workout.name}: assumi ~${w.fuelingCarbsPerHour} g/h di '
              'carboidrati durante la seduta.',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, double v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      children: [
        Expanded(child: Text(k)),
        Text(
          '${v > 0 && k.startsWith('Surplus') ? '+' : ''}${v.round()} kcal',
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
      ],
    ),
  );
}

class _WorkoutLine extends StatelessWidget {
  final WorkoutEnergy w;
  const _WorkoutLine(this.w);

  @override
  Widget build(BuildContext context) {
    final wk = w.workout;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(sportIcon(wk.sport), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${wk.name} · ${fmtDuration(wk.movingTimeSec)}'
              '${wk.trainingLoad != null ? ' · load ${wk.trainingLoad}' : ''}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            message: 'Lorde ${w.grossKcal.round()} kcal, ${w.source.label}',
            child: Text('+${w.netKcal.round()} kcal'),
          ),
          const SizedBox(width: 4),
          Icon(
            wk.completed ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: wk.completed
                ? Colors.green
                : Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
