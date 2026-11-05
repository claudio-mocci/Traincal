import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food.dart';
import '../../models/nutrition_plan.dart';
import '../../services/energy_calculator.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/visuals.dart';
import '../widgets/week_selector.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  int? _selected;
  DateTime? _week;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final days = s.weekEnergy;
    // Cambiando settimana si riparte da oggi (se è nella settimana) o lunedì.
    if (_week != s.selectedWeek) {
      _week = s.selectedWeek;
      final i = days.indexWhere(
        (d) => DateUtils.isSameDay(d.date, DateTime.now()),
      );
      _selected = i < 0 ? 0 : i;
    }
    final selected = days[_selected!];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        const WeekSelector(),
        const SizedBox(height: 4),
        DayStrip(
          days: [for (final d in days) d.date],
          selected: _selected!,
          marked: (i) => days[i].workouts.isNotEmpty,
          onSelected: (i) => setState(() => _selected = i),
        ),
        const SizedBox(height: 16),
        _DayHero(selected, plan: s.activePlan),
        if (!s.intervalsConfigured) ...[
          const SizedBox(height: 12),
          const _Notice(
            icon: Icons.link_rounded,
            text:
                'Collega intervals.icu (icona impostazioni in alto) per '
                'importare gli allenamenti pianificati e svolti.',
          ),
        ],
        _SectionHeader('Allenamenti'),
        if (selected.workouts.isEmpty)
          const _Notice(
            icon: Icons.self_improvement_rounded,
            text: 'Giorno di riposo: il target è calcolato senza sport.',
          )
        else
          for (final w in selected.workouts) ...[
            _WorkoutCard(w),
            const SizedBox(height: 8),
          ],
        _Advice(selected),
        const SizedBox(height: 8),
        _EnergyDetails(selected),
        _SectionHeader(
          'La tua settimana',
          trailing: s.intervalsConfigured
              ? TextButton.icon(
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('Pubblica'),
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
        _WeekOverview(
          days: days,
          selected: _selected!,
          onSelected: (i) => setState(() => _selected = i),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _SectionHeader(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 0, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Card scura del giorno selezionato: anello con kcal e ripartizione dei
/// macro, grammi per macro e bilancio energetico.
class _DayHero extends StatelessWidget {
  final DayEnergy d;
  final NutritionPlan? plan;
  const _DayHero(this.d, {required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final t = d.target;
    final onHero = theme.textTheme.apply(
      bodyColor: c.onHero,
      displayColor: c.onHero,
    );
    Widget macro(String label, double grams, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: onHero.bodyMedium?.copyWith(color: c.onHeroMuted),
            ),
          ),
          Text(
            '${grams.round()} g',
            style: onHero.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    Widget stat(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: onHero.labelSmall?.copyWith(color: c.onHeroMuted),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: onHero.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    String signed(double v) => '${v >= 0 ? '+' : '−'}${v.abs().round()}';

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _capitalize(dayLongFmt.format(d.date)),
                  style: onHero.titleMedium,
                ),
              ),
              _LoadBadge(d.load),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            plan == null
                ? 'Mantenimento'
                : '${plan!.name} · ${plan!.goal.label}',
            style: onHero.bodySmall?.copyWith(color: c.onHeroMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              MacroDonut(
                track: Colors.white.withValues(alpha: 0.08),
                segments: [
                  (t.protein * 4, c.protein),
                  (t.carbs * 4, c.carbs),
                  (t.fat * 9, c.fat),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${t.kcal.round()}',
                      style: onHero.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: onHero.labelSmall?.copyWith(color: c.onHeroMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    macro('Proteine', t.protein, c.protein),
                    macro('Carboidrati', t.carbs, c.carbs),
                    macro('Grassi', t.fat, c.fat),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                stat('Dispendio', '${d.tdee.round()}'),
                stat('Sport', signed(d.exerciseKcal)),
                stat(
                  d.goalAdjustment < 0 ? 'Deficit' : 'Obiettivo',
                  d.goalAdjustment.abs() < 1 ? '0' : signed(d.goalAdjustment),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _LoadBadge extends StatelessWidget {
  final DayLoad load;
  const _LoadBadge(this.load);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (load) {
      DayLoad.rest => c.onHeroMuted,
      DayLoad.light => c.sport,
      DayLoad.moderate => c.carbs,
      DayLoad.hard => c.protein,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            load.label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutEnergy w;
  const _WorkoutCard(this.w);

  @override
  Widget build(BuildContext context) {
    final wk = w.workout;
    final c = context.colors;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SportTile(wk.sport),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wk.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      InfoPill(
                        fmtDuration(wk.movingTimeSec),
                        icon: Icons.schedule_rounded,
                      ),
                      if (wk.trainingLoad != null)
                        InfoPill(
                          'load ${wk.trainingLoad}',
                          icon: Icons.bolt_rounded,
                        ),
                      InfoPill(
                        wk.completed ? 'Svolto' : 'Pianificato',
                        icon: wk.completed
                            ? Icons.check_circle_rounded
                            : Icons.event_rounded,
                        color: wk.completed ? c.success : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Lorde ${w.grossKcal.round()} kcal, ${w.source.label}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${w.netKcal.round()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: c.kcal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('kcal', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Consigli del giorno: carboidrati sotto le linee guida e integrazione
/// durante le sedute lunghe.
class _Advice extends StatelessWidget {
  final DayEnergy d;
  const _Advice(this.d);

  @override
  Widget build(BuildContext context) {
    final carbsLow = d.target.carbs < d.recommendedCarbs * 0.8;
    final fueling = d.workouts.where((w) => w.fuelingCarbsPerHour > 0);
    if (!carbsLow && fueling.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          if (carbsLow)
            _Notice(
              icon: Icons.warning_amber_rounded,
              color: c.protein,
              text:
                  'Carboidrati sotto le linee guida per il carico '
                  '(${d.load.carbsPerKg} g/kg = ${d.recommendedCarbs.round()} g): '
                  'in una giornata intensa valuta di ridurre il deficit.',
            ),
          for (final w in fueling) ...[
            if (carbsLow) const SizedBox(height: 8),
            _Notice(
              icon: Icons.local_drink_rounded,
              color: c.carbs,
              text:
                  '${w.workout.name}: assumi ~${w.fuelingCarbsPerHour} g/h '
                  'di carboidrati durante la seduta.',
            ),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _Notice({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final col = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: col, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _EnergyDetails extends StatelessWidget {
  final DayEnergy d;
  const _EnergyDetails(this.d);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget kv(String k, double v, {bool bold = false, bool signed = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  k,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: bold ? null : theme.colorScheme.onSurfaceVariant,
                    fontWeight: bold ? FontWeight.w600 : null,
                  ),
                ),
              ),
              Text(
                '${signed && v > 0 ? '+' : ''}${v.round()} kcal',
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.insights_rounded),
        title: Text('Come è calcolato', style: theme.textTheme.titleSmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          kv('Metabolismo basale', d.bmr),
          kv('Dispendio senza sport', d.baseline),
          kv('Allenamenti (netto)', d.exerciseKcal),
          const Divider(height: 16),
          kv('Dispendio totale stimato', d.tdee, bold: true),
          if (d.goalAdjustment.abs() > 1)
            kv(
              d.goalAdjustment < 0 ? 'Deficit obiettivo' : 'Surplus obiettivo',
              d.goalAdjustment,
              signed: true,
            ),
          kv('Target del giorno', d.target.kcal, bold: true),
          const SizedBox(height: 6),
          Text(
            'Carboidrati consigliati per il carico (${d.load.carbsPerKg} g/kg): '
            '${d.recommendedCarbs.round()} g',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Riepilogo della settimana: piano attivo, medie e una riga per giorno con
/// barra delle kcal.
class _WeekOverview extends StatelessWidget {
  final List<DayEnergy> days;
  final int selected;
  final ValueChanged<int> onSelected;

  const _WeekOverview({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final theme = Theme.of(context);
    final c = context.colors;
    final plan = s.activePlan;
    final total = days.fold(Macros.zero, (a, d) => a + d.target);
    final avg = total.scale(1 / days.length);
    final maxKcal = days.fold<double>(
      1,
      (m, d) => d.target.kcal > m ? d.target.kcal : m,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: plan?.id,
                    hint: const Text('Nessun piano attivo (mantenimento)'),
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(16),
                    items: [
                      for (final p in s.plans)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} · ${p.goal.label}'),
                        ),
                    ],
                    onChanged: (id) => id == null ? null : s.activatePlan(id),
                  ),
                ),
              ],
            ),
            Text('Media giornaliera', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            MacroRow(avg, dense: true),
            const SizedBox(height: 8),
            Text(
              'Peso ${s.profile.weightKg.toStringAsFixed(1)} kg · '
              'totale ${total.kcal.round()} kcal'
              '${plan != null && plan.goal != Goal.maintenance ? ' · obiettivo ${plan.goal == Goal.cut ? '-' : '+'}${plan.ratePerWeek} kg/sett.' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (plan != null && plan.goal != Goal.maintenance)
              _GoalCoverage(days, plan),
            const Divider(height: 24),
            for (var i = 0; i < days.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          _capitalize(
                            dayFmt.format(days[i].date).split(' ').first,
                          ),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: i == selected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: days[i].target.kcal / maxKcal,
                                minHeight: 8,
                                color: i == selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.45,
                                      ),
                                backgroundColor: c.subtle,
                              ),
                            ),
                            if (days[i].workouts.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  days[i].workouts
                                      .map((w) => w.workout.name)
                                      .join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: c.sport,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '${days[i].target.kcal.round()}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
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
          color: short
              ? context.colors.carbs
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
