import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/food.dart';
import '../../models/meal_plan.dart';
import '../../models/recipe.dart';
import '../../services/shopping_list.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/week_selector.dart';
import 'recipes_screen.dart';

class MealPrepScreen extends StatelessWidget {
  const MealPrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final plan = s.weekMealPlan;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const WeekSelector(),
          _OptionsBar(hasPlan: plan != null),
          for (final w in s.mealPlanWarnings)
            ListTile(
              dense: true,
              leading: const Icon(Icons.info_outline, size: 18),
              title: Text(w),
            ),
          const TabBar(
            tabs: [
              Tab(text: 'Menu'),
              Tab(text: 'Preparazione'),
              Tab(text: 'Spesa'),
            ],
          ),
          Expanded(
            child: plan == null
                ? const EmptyHint(
                    icon: Icons.restaurant,
                    text:
                        'Genera il menu della settimana: le porzioni vengono '
                        'scalate sul fabbisogno stimato di ogni giorno.',
                  )
                : TabBarView(
                    children: [
                      _MenuTab(plan),
                      _PrepTab(plan),
                      _ShoppingTab(s.shoppingList!),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _OptionsBar extends StatelessWidget {
  final bool hasPlan;
  const _OptionsBar({required this.hasPlan});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.mealPrepPrefs;
    Widget stepper(
      String label,
      int value,
      int min,
      int max,
      void Function(int) onChanged,
    ) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value'),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          stepper(
            'Sessioni di cucina',
            p.prepSessions,
            1,
            3,
            (v) => s.saveMealPrepPrefs(p.copyWith(prepSessions: v)),
          ),
          stepper(
            'Colazioni diverse',
            p.breakfastVariety,
            1,
            4,
            (v) => s.saveMealPrepPrefs(p.copyWith(breakfastVariety: v)),
          ),
          stepper(
            'Spuntini diversi',
            p.snackVariety,
            1,
            4,
            (v) => s.saveMealPrepPrefs(p.copyWith(snackVariety: v)),
          ),
          FilledButton.icon(
            icon: Icon(hasPlan ? Icons.refresh : Icons.auto_awesome),
            label: Text(hasPlan ? 'Rigenera' : 'Genera menu'),
            onPressed: () => s.generateMealPlan(),
          ),
        ],
      ),
    );
  }
}

class _MenuTab extends StatelessWidget {
  final WeekMealPlan plan;
  const _MenuTab(this.plan);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final recipes = s.recipesById;
    final planner = s.planner;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final d in plan.days)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLongFmt.format(d.date),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  MacroRow(planner.dayTotal(d), target: d.target, dense: true),
                  const Divider(),
                  for (final m in d.meals)
                    if (recipes[m.recipeId] case final r?)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 92,
                          child: Text(
                            m.slot.label,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        title: Text(r.name),
                        subtitle: Text(
                          '${fmtServings(m.servings)} porz. · '
                          '${(r.macrosPerServing(s.foods).kcal * m.servings).round()} kcal',
                        ),
                        trailing: IconButton(
                          tooltip: 'Sostituisci in tutta la settimana',
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () => _swap(context, r),
                        ),
                        onTap: () => showRecipeDetail(context, r),
                      ),
                  if (d.extras.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Integrazioni: ${d.extras.map((e) => '${s.foods[e.foodId]?.name ?? e.foodId} ${e.grams.round()} g').join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _swap(BuildContext context, Recipe current) async {
    final s = context.read<AppState>();
    final options = s.recipes
        .where((r) => r.type == current.type && r.id != current.id)
        .toList();
    final picked = await showDialog<Recipe>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('Sostituisci "${current.name}"'),
        children: [
          for (final r in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, r),
              child: ListTile(
                title: Text(r.name),
                subtitle: Text(r.macrosPerServing(s.foods).toString()),
              ),
            ),
        ],
      ),
    );
    if (picked != null) s.swapRecipeInPlan(current.id, picked.id);
  }
}

class _PrepTab extends StatelessWidget {
  final WeekMealPlan plan;
  const _PrepTab(this.plan);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final recipes = s.recipesById;
    final dates = plan.prepSessions.map((p) => p.date).toSet().toList()..sort();
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final date in dates) ...[
          SectionTitle('Sessione di ${dayLongFmt.format(date)}'),
          for (final ps in plan.prepSessions.where((p) => p.date == date))
            if (recipes[ps.recipeId] case final r?)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExpansionTile(
                  shape: const Border(),
                  title: Text(r.name),
                  subtitle: Text(
                    '${fmtServings(ps.totalServings)} porzioni per '
                    '${ps.coversDays.map(dayFmt.format).join(', ')}\n'
                    'Frigo ${r.fridgeDays} gg${r.freezable ? ' · congelabile' : ''} · ${r.prepMinutes} min',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final i in r.ingredients)
                      Text(
                        '• ${s.foods[i.foodId]?.name ?? i.foodId}: '
                        '${(i.grams * ps.totalServings).round()} g',
                      ),
                    if (r.instructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(r.instructions),
                    ],
                  ],
                ),
              ),
        ],
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Colazioni e spuntini si preparano al momento o la sera prima. '
            'Dividi ogni preparazione nelle porzioni indicate nel menu: nei '
            'giorni più intensi le porzioni sono più abbondanti.',
          ),
        ),
      ],
    );
  }
}

class _ShoppingTab extends StatefulWidget {
  final ShoppingList list;
  const _ShoppingTab(this.list);

  @override
  State<_ShoppingTab> createState() => _ShoppingTabState();
}

class _ShoppingTabState extends State<_ShoppingTab> {
  final _checked = <String>{};

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${list.byCategory.values.fold<int>(0, (a, l) => a + l.length)} prodotti',
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copia'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: list.toPlainText()),
                  );
                  if (context.mounted) {
                    showInfo(context, 'Lista copiata negli appunti');
                  }
                },
              ),
            ],
          ),
        ),
        for (final e in list.byCategory.entries) ...[
          SectionTitle(e.key.label),
          for (final item in e.value)
            CheckboxListTile(
              dense: true,
              value: _checked.contains(item.food.id),
              onChanged: (v) => setState(
                () => v == true
                    ? _checked.add(item.food.id)
                    : _checked.remove(item.food.id),
              ),
              title: Text(
                item.food.name,
                style: _checked.contains(item.food.id)
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              subtitle: Text(item.quantityLabel),
            ),
        ],
      ],
    );
  }
}
