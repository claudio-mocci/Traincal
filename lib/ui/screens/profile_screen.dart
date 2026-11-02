import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_plan.dart';
import '../../models/profile.dart';
import '../../services/energy_calculator.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile;
    final bmr = EnergyCalculator.bmr(p, DateTime.now());

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionTitle('Profilo'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<Sex>(
                segments: const [
                  ButtonSegment(value: Sex.male, label: Text('Uomo')),
                  ButtonSegment(value: Sex.female, label: Text('Donna')),
                ],
                selected: {p.sex},
                onSelectionChanged: (v) =>
                    s.saveProfile(p.copyWith(sex: v.first)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _NumField(
                    label: 'Anno di nascita',
                    value: p.birthYear.toDouble(),
                    decimals: 0,
                    onChanged: (v) =>
                        s.saveProfile(p.copyWith(birthYear: v.round())),
                  ),
                  _NumField(
                    label: 'Altezza (cm)',
                    value: p.heightCm,
                    decimals: 0,
                    onChanged: (v) => s.saveProfile(p.copyWith(heightCm: v)),
                  ),
                  _NumField(
                    label: 'Peso (kg)',
                    value: p.weightKg,
                    decimals: 1,
                    onChanged: (v) => s.saveProfile(p.copyWith(weightKg: v)),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aggiorna il peso da intervals.icu'),
                subtitle: const Text(
                  'Usa l\'ultimo peso registrato nel wellness',
                ),
                value: p.syncWeightFromIntervals,
                onChanged: (v) =>
                    s.saveProfile(p.copyWith(syncWeightFromIntervals: v)),
              ),
              const SizedBox(height: 8),
              Text(
                'Attività fuori dallo sport',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              DropdownButton<double>(
                isExpanded: true,
                value: _nearest(p.lifestyleFactor),
                items: const [
                  DropdownMenuItem(
                    value: 1.2,
                    child: Text(
                      'Sedentaria (lavoro d\'ufficio, smart working)',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 1.3,
                    child: Text('Leggera (ufficio + spostamenti a piedi)'),
                  ),
                  DropdownMenuItem(
                    value: 1.4,
                    child: Text('Moderata (lavoro in piedi)'),
                  ),
                  DropdownMenuItem(
                    value: 1.55,
                    child: Text('Elevata (lavoro fisico)'),
                  ),
                ],
                onChanged: (v) => s.saveProfile(p.copyWith(lifestyleFactor: v)),
              ),
              const SizedBox(height: 8),
              Text(
                'Pasti al giorno',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                  ButtonSegment(value: 5, label: Text('5')),
                ],
                selected: {p.mealsPerDay},
                onSelectionChanged: (v) =>
                    s.saveProfile(p.copyWith(mealsPerDay: v.first)),
              ),
              const SizedBox(height: 12),
              Text(
                'Metabolismo basale (Mifflin-St Jeor): ${bmr.round()} kcal · '
                'senza sport: ${(bmr * p.lifestyleFactor).round()} kcal',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SectionTitle(
          'Piani nutrizionali',
          trailing: PopupMenuButton<Goal>(
            tooltip: 'Nuovo piano',
            icon: const Icon(Icons.add),
            onSelected: (g) => showPlanEditor(context, s.newPlan(g)),
            itemBuilder: (_) => [
              for (final g in Goal.values)
                PopupMenuItem(value: g, child: Text(g.label)),
            ],
          ),
        ),
        if (s.plans.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Nessun piano: i target sono calcolati per il mantenimento. '
              'Crea un piano con + per scegliere l\'obiettivo da seguire.',
            ),
          ),
        RadioGroup<String>(
          groupValue: s.activePlan?.id,
          onChanged: (id) => id == null ? null : s.activatePlan(id),
          child: Column(
            children: [
              for (final plan in s.plans)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Radio<String>(value: plan.id),
                    title: Text(plan.name),
                    subtitle: Text(
                      [
                        plan.goal.label,
                        if (plan.goal != Goal.maintenance)
                          '${plan.goal == Goal.cut ? '-' : '+'}${plan.ratePerWeek} kg/sett.',
                        'proteine ${plan.proteinPerKg} g/kg',
                        'dal ${dayFmt.format(plan.startDate)}'
                            '${plan.endDate != null ? ' al ${dayFmt.format(plan.endDate!)}' : ''}',
                      ].join(' · '),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => v == 'edit'
                          ? showPlanEditor(context, plan)
                          : s.deletePlan(plan.id),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifica')),
                        PopupMenuItem(value: 'delete', child: Text('Elimina')),
                      ],
                    ),
                    onTap: () => s.activatePlan(plan.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static double _nearest(double v) => [
    1.2,
    1.3,
    1.4,
    1.55,
  ].reduce((a, b) => (a - v).abs() <= (b - v).abs() ? a : b);
}

class _NumField extends StatefulWidget {
  final String label;
  final double value;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _NumField({
    required this.label,
    required this.value,
    required this.decimals,
    required this.onChanged,
  });

  @override
  State<_NumField> createState() => _NumFieldState();
}

/// Campo numerico che salva quando perde il focus o con Invio, e si
/// aggiorna se il valore cambia dall'esterno (es. peso da intervals.icu).
class _NumFieldState extends State<_NumField> {
  late final TextEditingController _c;
  final _focus = FocusNode();

  String get _text => widget.value.toStringAsFixed(widget.decimals);

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _text);
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(_NumField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && old.value != widget.value) _c.text = _text;
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final d = double.tryParse(_c.text.replaceAll(',', '.'));
    if (d != null && d > 0 && d != widget.value) {
      widget.onChanged(d);
    } else {
      _c.text = _text;
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: TextField(
      controller: _c,
      focusNode: _focus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: widget.label),
      onSubmitted: (_) => _commit(),
      onTapOutside: (_) => _focus.unfocus(),
    ),
  );
}

Future<void> showPlanEditor(BuildContext context, NutritionPlan plan) =>
    showDialog(context: context, builder: (_) => _PlanEditor(plan));

class _PlanEditor extends StatefulWidget {
  final NutritionPlan plan;
  const _PlanEditor(this.plan);

  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  late NutritionPlan _p;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _p = widget.plan;
    _name = TextEditingController(text: _p.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final isNew = !s.plans.any((x) => x.id == _p.id);
    final weeklyKcal = _p.ratePerWeek * EnergyCalculator.kcalPerKgBodyMass;
    return AlertDialog(
      title: Text(isNew ? 'Nuovo piano' : 'Modifica piano'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<Goal>(
                segments: [
                  for (final g in Goal.values)
                    ButtonSegment(
                      value: g,
                      label: Text(g.label.split(' ').first),
                    ),
                ],
                selected: {_p.goal},
                onSelectionChanged: (v) => setState(
                  () => _p = _p.copyWith(
                    goal: v.first,
                    ratePerWeek: v.first.defaultRate,
                    proteinPerKg: v.first.defaultProteinPerKg,
                  ),
                ),
              ),
              if (_p.goal != Goal.maintenance) ...[
                const SizedBox(height: 12),
                Text(
                  '${_p.goal == Goal.cut ? 'Perdita' : 'Aumento'}: ${_p.ratePerWeek.toStringAsFixed(2)} kg/settimana '
                  '(~${(weeklyKcal / 7).round()} kcal/giorno)',
                ),
                Slider(
                  value: _p.ratePerWeek,
                  min: 0.1,
                  max: _p.goal == Goal.cut ? 1.0 : 0.5,
                  divisions: _p.goal == Goal.cut ? 18 : 8,
                  onChanged: (v) =>
                      setState(() => _p = _p.copyWith(ratePerWeek: v)),
                ),
                if (_p.goal == Goal.cut && _p.ratePerWeek > 0.7)
                  Text(
                    'Sopra lo 0.7% del peso a settimana il rischio di perdere '
                    'massa magra e prestazione aumenta.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Text('Proteine: ${_p.proteinPerKg.toStringAsFixed(1)} g/kg'),
              Slider(
                value: _p.proteinPerKg,
                min: 1.2,
                max: 2.6,
                divisions: 14,
                onChanged: (v) =>
                    setState(() => _p = _p.copyWith(proteinPerKg: v)),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Inizio ${dayFmt.format(_p.startDate)}'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _p.startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (d != null) {
                        setState(() => _p = _p.copyWith(startDate: d));
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: Text(
                      _p.endDate == null
                          ? 'Senza fine'
                          : 'Fine ${dayFmt.format(_p.endDate!)}',
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate:
                            _p.endDate ??
                            _p.startDate.add(const Duration(days: 56)),
                        firstDate: _p.startDate,
                        lastDate: DateTime(2035),
                      );
                      setState(
                        () => _p = d == null
                            ? _p.copyWith(clearEndDate: true)
                            : _p.copyWith(endDate: d),
                      );
                    },
                  ),
                ],
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
          onPressed: () {
            s.savePlan(
              _p.copyWith(
                name: _name.text.trim().isEmpty
                    ? _p.goal.label
                    : _name.text.trim(),
                active: isNew ? true : _p.active,
              ),
            );
            Navigator.pop(context);
          },
          child: Text(isNew ? 'Crea e attiva' : 'Salva'),
        ),
      ],
    );
  }
}
