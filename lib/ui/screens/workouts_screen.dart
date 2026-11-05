import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/workout.dart';
import '../../services/energy_calculator.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/visuals.dart';
import '../widgets/week_selector.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final days = s.weekDays;
    final list = s.workoutsBetween(days.first, days.last);
    final baselinePerHour =
        EnergyCalculator.bmr(s.profile, DateTime.now()) *
        s.profile.lifestyleFactor /
        24;

    return Scaffold(
      floatingActionButton: s.intervalsConfigured
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Pianifica'),
              onPressed: () => showWorkoutEditor(context),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const WeekSelector(),
          if (!s.intervalsConfigured)
            const EmptyHint(
              icon: Icons.link_off,
              text:
                  'Configura la API key di intervals.icu nelle impostazioni '
                  'per leggere e pianificare gli allenamenti.',
            )
          else if (list.isEmpty)
            const EmptyHint(
              icon: Icons.event_available,
              text: 'Nessun allenamento in questa settimana.',
            ),
          for (final day in days)
            if (list.any((w) => w.day == day)) ...[
              SectionTitle(
                dayLongFmt.format(day)[0].toUpperCase() +
                    dayLongFmt.format(day).substring(1),
              ),
              for (final w in list.where((w) => w.day == day))
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                    leading: SportTile(w.sport, size: 46),
                    title: Text(w.name),
                    subtitle: Text(
                      [
                        w.sport.label,
                        if (w.movingTimeSec > 0) fmtDuration(w.movingTimeSec),
                        if ((w.distanceM ?? 0) > 0)
                          '${(w.distanceM! / 1000).toStringAsFixed(1)} km',
                        if (w.trainingLoad != null) 'load ${w.trainingLoad}',
                        '~${EnergyCalculator.workoutEnergy(w, s.profile, baselinePerHour).grossKcal.round()} kcal',
                      ].join(' · '),
                    ),
                    trailing: w.completed
                        ? const Tooltip(
                            message: 'Svolto',
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          )
                        : PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                showWorkoutEditor(context, existing: w);
                              } else if (v == 'delete') {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text(
                                      'Eliminare l\'allenamento?',
                                    ),
                                    content: Text(
                                      '"${w.name}" verrà rimosso anche dal calendario di intervals.icu.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Annulla'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Elimina'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  await guarded(
                                    context,
                                    () => s.deleteWorkout(w),
                                  );
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Modifica'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Elimina'),
                              ),
                            ],
                          ),
                    onTap: w.completed
                        ? null
                        : () => showWorkoutEditor(context, existing: w),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}

Future<void> showWorkoutEditor(BuildContext context, {Workout? existing}) =>
    showDialog(
      context: context,
      builder: (_) => _WorkoutEditor(existing: existing),
    );

class _WorkoutEditor extends StatefulWidget {
  final Workout? existing;
  const _WorkoutEditor({this.existing});

  @override
  State<_WorkoutEditor> createState() => _WorkoutEditorState();
}

class _WorkoutEditorState extends State<_WorkoutEditor> {
  late DateTime _date;
  late Sport _sport;
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _minutes;
  late final TextEditingController _km;
  late final TextEditingController _load;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final s = context.read<AppState>();
    final now = DateTime.now();
    final defaultDay = s.selectedWeek.isAfter(now) ? s.selectedWeek : now;
    _date =
        e?.day ?? DateTime(defaultDay.year, defaultDay.month, defaultDay.day);
    _sport = e?.sport ?? Sport.run;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _minutes = TextEditingController(
      text: e == null ? '60' : (e.movingTimeSec ~/ 60).toString(),
    );
    _km = TextEditingController(
      text: (e?.distanceM ?? 0) > 0
          ? (e!.distanceM! / 1000).toStringAsFixed(1)
          : '',
    );
    _load = TextEditingController(text: e?.trainingLoad?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _minutes, _km, _load]) {
      c.dispose();
    }
    super.dispose();
  }

  WorkoutDraft _draft() => WorkoutDraft(
    eventId: widget.existing?.eventId,
    date: _date,
    sport: _sport,
    name: _name.text.trim().isEmpty ? _sport.label : _name.text.trim(),
    description: _desc.text,
    durationMin: int.tryParse(_minutes.text) ?? 0,
    distanceKm: double.tryParse(_km.text.replaceAll(',', '.')),
    targetLoad: int.tryParse(_load.text),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final d = _draft();
    final preview = EnergyCalculator.workoutEnergy(
      Workout(
        id: 'preview',
        completed: false,
        date: d.date,
        icuType: d.sport.icuType,
        name: d.name,
        movingTimeSec: d.durationMin * 60,
        distanceM: d.distanceKm == null ? null : d.distanceKm! * 1000,
        trainingLoad: d.targetLoad,
      ),
      s.profile,
      EnergyCalculator.bmr(s.profile, d.date) * s.profile.lifestyleFactor / 24,
    );

    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Nuovo allenamento' : 'Modifica allenamento',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(dayLongFmt.format(_date)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<Sport>(
                segments: [
                  for (final sp in [
                    Sport.run,
                    Sport.ride,
                    Sport.strength,
                    Sport.swim,
                  ])
                    ButtonSegment(
                      value: sp,
                      icon: Icon(sportIcon(sp)),
                      label: Text(sp.label),
                    ),
                ],
                selected: {_sport},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _sport = v.first),
              ),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Durata (min)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_sport != Sport.strength)
                    Expanded(
                      child: TextField(
                        controller: _km,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Distanza (km)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _load,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Load (TSS)',
                        helperText: 'opzionale',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _desc,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Descrizione / struttura',
                  helperText: 'Puoi usare la sintassi workout di intervals.icu (es. "- 10m Z2")',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Stima: ~${preview.grossKcal.round()} kcal (${preview.source.label})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  final ok = await guarded(context, () async {
                    await s.saveWorkout(_draft());
                    return true;
                  });
                  if (!context.mounted) return;
                  setState(() => _saving = false);
                  if (ok == true) Navigator.pop(context);
                },
          child: Text(_saving ? 'Salvataggio…' : 'Salva su intervals.icu'),
        ),
      ],
    );
  }
}
