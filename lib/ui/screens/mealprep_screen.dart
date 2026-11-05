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
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
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
          SegmentedButton<MealPrepStyle>(
            segments: [
              for (final st in MealPrepStyle.values)
                ButtonSegment(
                  value: st,
                  label: Text(st.shortLabel),
                  tooltip: st.label,
                  icon: Icon(
                    st == MealPrepStyle.recipes
                        ? Icons.restaurant_menu
                        : Icons.dashboard_customize,
                  ),
                ),
            ],
            selected: {p.style},
            showSelectedIcon: false,
            onSelectionChanged: (v) =>
                s.saveMealPrepPrefs(p.copyWith(style: v.first)),
          ),
          if (p.style == MealPrepStyle.recipes)
            stepper(
              'Ricette per sessione',
              p.mainVariety,
              2,
              4,
              (v) => s.saveMealPrepPrefs(p.copyWith(mainVariety: v)),
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
          if (p.pinnedRecipeIds.isNotEmpty)
            Builder(
              builder: (context) {
                final byId = s.recipesById;
                int count(MealType t) =>
                    p.pinnedRecipeIds.where((id) => byId[id]?.type == t).length;
                return Chip(
                  avatar: const Icon(Icons.push_pin, size: 16),
                  label: Text(
                    'Fisse: ${count(MealType.breakfast)} colazioni, '
                    '${count(MealType.snack)} spuntini',
                  ),
                );
              },
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
    final recipes = s.planRecipesById;
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
                          '${(r.macrosPerServing(s.foods).kcal * m.servings).round()} kcal'
                          '${m.locked
                              ? ' · impostate a mano'
                              : r.fixedServings != null
                              ? ' · porzione fissa'
                              : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Porzioni',
                              icon: Icon(
                                m.locked || r.fixedServings != null
                                    ? Icons.lock_outline
                                    : Icons.tune,
                              ),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => _ServingsDialog(
                                  date: d.date,
                                  meal: m,
                                  recipe: r,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Sostituisci in tutta la settimana',
                              icon: const Icon(Icons.swap_horiz),
                              onPressed: () => _swap(context, r),
                            ),
                          ],
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
    final picked = await showDialog<Recipe>(
      context: context,
      builder: (_) => _SwapDialog(current: current, days: s.weekDays),
    );
    if (picked != null) s.swapRecipeInPlan(current.id, picked.id);
  }
}

/// Scelta della ricetta sostitutiva: stesso tipo di pasto, prima quelle di
/// stagione nella settimana, con ricerca per nome.
class _SwapDialog extends StatefulWidget {
  final Recipe current;
  final List<DateTime> days;
  const _SwapDialog({required this.current, required this.days});

  @override
  State<_SwapDialog> createState() => _SwapDialogState();
}

class _SwapDialogState extends State<_SwapDialog> {
  String _query = '';
  late final List<Recipe> _options;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final planner = s.planner;
    final penalty = {
      for (final r in s.recipes)
        if (r.type == widget.current.type && r.id != widget.current.id)
          r: (planner.seasonPenalty(r, widget.days) * 10).round(),
    };
    _options = penalty.keys.toList()
      ..sort((a, b) {
        final c = penalty[a]!.compareTo(penalty[b]!);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _query.toLowerCase();
    final list = _options
        .where((r) => r.name.toLowerCase().contains(q))
        .toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Sostituisci "${widget.current.name}"',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cerca ricetta',
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (c, i) {
                  final r = list[i];
                  return ListTile(
                    leading: r.isInSeason(s.foods, widget.days)
                        ? const Icon(Icons.eco_outlined)
                        : const SizedBox(width: 24),
                    title: Text(r.name),
                    subtitle: Text(r.macrosPerServing(s.foods).toString()),
                    onTap: () => Navigator.pop(c, r),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Porzioni di un pasto del menu: impostate a mano restano fisse e gli
/// altri pasti del giorno si adattano per rispettare il target.
class _ServingsDialog extends StatefulWidget {
  final DateTime date;
  final MealEntry meal;
  final Recipe recipe;

  const _ServingsDialog({
    required this.date,
    required this.meal,
    required this.recipe,
  });

  @override
  State<_ServingsDialog> createState() => _ServingsDialogState();
}

class _ServingsDialogState extends State<_ServingsDialog> {
  late double _servings = widget.meal.servings;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final perServing = widget.recipe.macrosPerServing(s.foods);
    final fixedByRecipe = widget.recipe.fixedServings != null;
    return AlertDialog(
      title: Text(widget.recipe.name),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.meal.slot.label} · ${dayLongFmt.format(widget.date)}',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  onPressed: _servings > 0.25
                      ? () => setState(() => _servings -= 0.25)
                      : null,
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${fmtServings(_servings)} porz.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: _servings < 4
                      ? () => setState(() => _servings += 0.25)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: MacroRow(perServing.scale(_servings), dense: true)),
            const SizedBox(height: 12),
            Text(
              fixedByRecipe
                  ? 'Questa ricetta ha una porzione fissa '
                        '(${fmtServings(widget.recipe.fixedServings!)}): puoi '
                        'cambiarla qui solo per questo pasto, o dall\'editor '
                        'della ricetta per tutti.'
                  : 'Gli altri pasti del giorno vengono ricalcolati per '
                        'restare nel target.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.meal.locked)
          TextButton(
            onPressed: () {
              s.setMealServings(widget.date, widget.meal.slot, null);
              Navigator.pop(context);
            },
            child: const Text('Automatico'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            s.setMealServings(widget.date, widget.meal.slot, _servings);
            Navigator.pop(context);
          },
          child: const Text('Imposta'),
        ),
      ],
    );
  }
}

class _PrepTab extends StatelessWidget {
  final WeekMealPlan plan;
  const _PrepTab(this.plan);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final recipes = s.planRecipesById;
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
                    'Frigo ${r.fridgeDays} gg${r.freezable ? ' · congelabile' : ''}'
                    '${r.prepMinutes > 0 ? ' · ${r.prepMinutes} min' : ''}',
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
        if (plan.combos.isNotEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Basi, proteine e verdure si conservano in contenitori separati: '
              'il menu indica come combinarle pasto per pasto.',
            ),
          ),
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
