import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/food.dart';
import '../../models/meal_plan.dart';
import '../../models/recipe.dart';
import '../../services/meal_planner.dart';
import '../../services/shopping_list.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/login_required.dart';
import '../widgets/visuals.dart';
import '../widgets/week_selector.dart';
import 'recipes_screen.dart';

class MealPrepScreen extends StatelessWidget {
  const MealPrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!s.loggedIn) {
      return const LoginRequired(
        'Il menu della settimana è legato al tuo account: accedi per '
        'generarlo e ritrovarlo su tutti i dispositivi.',
      );
    }
    final plan = s.weekMealPlan;
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: WeekSelector(),
          ),
          _PlanHeader(hasPlan: plan != null),
          if (s.mealPlanWarnings.isNotEmpty) _Warnings(s.mealPlanWarnings),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.colors.subtle,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(26),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
                splashBorderRadius: BorderRadius.circular(26),
                tabs: const [
                  Tab(text: 'Menu'),
                  Tab(text: 'Preparazione'),
                  Tab(text: 'Spesa'),
                ],
              ),
            ),
          ),
          Expanded(
            child: plan == null
                ? const EmptyHint(
                    icon: Icons.restaurant_rounded,
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

/// Riepilogo delle opzioni del menu, con il pulsante per generarlo.
class _PlanHeader extends StatelessWidget {
  final bool hasPlan;
  const _PlanHeader({required this.hasPlan});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.mealPrepPrefs;
    final theme = Theme.of(context);
    final freeCount = s
        .freeMealsFor(s.selectedWeek)
        .values
        .fold<int>(0, (a, v) => a + v.length);
    final lockedCount = s.weekMealPlan?.days.where((d) => d.locked).length ?? 0;
    final summary = [
      p.style.shortLabel,
      '${p.prepSessions} ${p.prepSessions == 1 ? 'sessione' : 'sessioni'}',
      if (p.style == MealPrepStyle.recipes) '${p.mainVariety} ricette/sessione',
      if (p.pinnedRecipeIds.isNotEmpty) '${p.pinnedRecipeIds.length} fisse',
      if (freeCount > 0)
        '$freeCount ${freeCount == 1 ? 'pasto libero' : 'pasti liberi'}',
      if (lockedCount > 0)
        '$lockedCount ${lockedCount == 1 ? 'giorno bloccato' : 'giorni bloccati'}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showOptions(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Opzioni',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: Icon(
                  hasPlan ? Icons.refresh_rounded : Icons.auto_awesome_rounded,
                  size: 18,
                ),
                label: Text(hasPlan ? 'Rigenera' : 'Genera menu'),
                onPressed: () => s.generateMealPlan(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _OptionsSheet(),
  );
}

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.mealPrepPrefs;
    final theme = Theme.of(context);
    Widget stepper(
      String label,
      String help,
      int value,
      int min,
      int max,
      void Function(int) onChanged,
    ) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                Text(
                  help,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.remove_rounded),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.add_rounded),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );

    final byId = s.recipesById;
    int pinned(MealType t) =>
        p.pinnedRecipeIds.where((id) => byId[id]?.type == t).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opzioni del menu', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Pranzi e cene', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MealPrepStyle>(
                segments: [
                  for (final st in MealPrepStyle.values)
                    ButtonSegment(
                      value: st,
                      label: Text(st.shortLabel),
                      tooltip: st.label,
                      icon: Icon(
                        st == MealPrepStyle.recipes
                            ? Icons.restaurant_menu_rounded
                            : Icons.dashboard_customize_rounded,
                      ),
                    ),
                ],
                selected: {p.style},
                showSelectedIcon: false,
                onSelectionChanged: (v) =>
                    s.saveMealPrepPrefs(p.copyWith(style: v.first)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              p.style == MealPrepStyle.recipes
                  ? 'Più ricette per sessione, alternate tra i pasti.'
                  : 'Basi, proteine e verdure cucinate a parte e combinate '
                        'in modo diverso ogni pasto.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            stepper(
              'Sessioni di cucina',
              'Quante volte cucini nella settimana',
              p.prepSessions,
              1,
              3,
              (v) => s.saveMealPrepPrefs(p.copyWith(prepSessions: v)),
            ),
            if (p.style == MealPrepStyle.recipes)
              stepper(
                'Ricette per sessione',
                'Piatti diversi preparati ogni volta',
                p.mainVariety,
                2,
                4,
                (v) => s.saveMealPrepPrefs(p.copyWith(mainVariety: v)),
              ),
            stepper(
              'Colazioni diverse',
              pinned(MealType.breakfast) > 0
                  ? '${pinned(MealType.breakfast)} fisse dalla schermata Ricette'
                  : 'A rotazione nella settimana',
              p.breakfastVariety,
              1,
              4,
              (v) => s.saveMealPrepPrefs(p.copyWith(breakfastVariety: v)),
            ),
            stepper(
              'Spuntini diversi',
              pinned(MealType.snack) > 0
                  ? '${pinned(MealType.snack)} fissi dalla schermata Ricette'
                  : 'A rotazione nella settimana',
              p.snackVariety,
              1,
              4,
              (v) => s.saveMealPrepPrefs(p.copyWith(snackVariety: v)),
            ),
            const SizedBox(height: 16),
            Text('Pasti da preparare', style: theme.textTheme.labelLarge),
            Text(
              'Tocca un pasto per cambiarne lo stato. Libero (es. cena fuori): '
              'niente ricetta, preparazione né spesa, ma le sue calorie restano '
              'riservate. Eliminato (es. lo spuntino nei giorni di riposo): le '
              'sue calorie passano agli altri pasti. Le modifiche valgono '
              'subito anche per il menu attuale.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            const _FreeMealsGrid(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Applica e rigenera'),
                onPressed: () {
                  s.generateMealPlan();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Griglia giorni × pasti della settimana selezionata: spuntato = pasto
/// preparato con il meal prep, vuoto = pasto libero.
class _FreeMealsGrid extends StatelessWidget {
  const _FreeMealsGrid();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final theme = Theme.of(context);
    final slots = MealSlot.values
        .where(MealPlanner.slotShares(s.profile.mealsPerDay).containsKey)
        .toList();
    final days = s.weekDays;
    final c = context.colors;

    // Preparato → libero → eliminato → preparato.
    MealStatus next(MealStatus st) =>
        MealStatus.values[(st.index + 1) % MealStatus.values.length];
    Widget cell(int d, MealSlot slot) {
      final st = s.mealStatus(d, slot);
      final (icon, color, tip) = switch (st) {
        MealStatus.planned => (
          Icons.check_box_rounded,
          theme.colorScheme.primary,
          'Preparato',
        ),
        MealStatus.free => (
          Icons.no_meals_rounded,
          c.carbs,
          'Libero (calorie riservate)',
        ),
        MealStatus.removed => (
          Icons.disabled_by_default_outlined,
          theme.colorScheme.onSurfaceVariant,
          'Eliminato (calorie ridistribuite)',
        ),
      };
      return IconButton(
        tooltip: '${slot.label}: $tip',
        icon: Icon(icon, color: color),
        onPressed: () => s.setMealStatus(d, [slot], next(st)),
      );
    }

    Widget legend(IconData icon, Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.labelSmall),
      ],
    );

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 72),
            for (final slot in slots)
              Expanded(
                child: Tooltip(
                  message: slot.label,
                  child: Icon(
                    _MenuTabState._slotIcon(slot),
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        for (var d = 0; d < days.length; d++)
          Row(
            children: [
              SizedBox(
                width: 72,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                  ),
                  // Giorno intero: tutto libero ↔ tutto preparato.
                  onPressed: () {
                    final allFree = slots.every(
                      (slot) => s.mealStatus(d, slot) == MealStatus.free,
                    );
                    s.setMealStatus(
                      d,
                      slots,
                      allFree ? MealStatus.planned : MealStatus.free,
                    );
                  },
                  child: Text(
                    dayFmt.format(days[d]).split(' ').take(2).join(' '),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
              for (final slot in slots) Expanded(child: cell(d, slot)),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            legend(
              Icons.check_box_rounded,
              theme.colorScheme.primary,
              'preparato',
            ),
            legend(Icons.no_meals_rounded, c.carbs, 'libero'),
            legend(
              Icons.disabled_by_default_outlined,
              theme.colorScheme.onSurfaceVariant,
              'eliminato',
            ),
          ],
        ),
      ],
    );
  }
}

class _Warnings extends StatelessWidget {
  final List<String> warnings;
  const _Warnings(this.warnings);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = context.colors.carbs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          dense: true,
          leading: Icon(Icons.info_outline_rounded, color: color),
          title: Text(
            warnings.length == 1
                ? '1 avviso sul menu'
                : '${warnings.length} avvisi sul menu',
            style: theme.textTheme.labelLarge,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            for (final w in warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $w', style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuTab extends StatefulWidget {
  final WeekMealPlan plan;
  const _MenuTab(this.plan);

  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  late int _day = () {
    final i = widget.plan.days.indexWhere(
      (d) => DateUtils.isSameDay(d.date, DateTime.now()),
    );
    return i < 0 ? 0 : i;
  }();

  static IconData _slotIcon(MealSlot s) => switch (s) {
    MealSlot.breakfast => Icons.wb_twilight_rounded,
    MealSlot.morningSnack || MealSlot.afternoonSnack => Icons.cookie_rounded,
    MealSlot.lunch => Icons.wb_sunny_rounded,
    MealSlot.dinner => Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final plan = widget.plan;
    final recipes = s.planRecipesById;
    final planner = s.planner;
    final theme = Theme.of(context);
    final c = context.colors;
    final d = plan.days[_day.clamp(0, plan.days.length - 1)];
    final total = planner.dayTotal(d);
    final planned = MealPlanner.plannedTarget(d);
    final shares = MealPlanner.slotShares(d.slotCount);
    final shareSum = shares.values.fold<double>(0, (a, b) => a + b);
    double freeKcal(MealSlot slot) =>
        shareSum == 0 ? 0 : d.target.kcal * (shares[slot] ?? 0) / shareSum;
    final mealBySlot = {for (final m in d.meals) m.slot: m};

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        DayStrip(
          days: [for (final x in plan.days) x.date],
          selected: _day,
          marked: (i) => plan.days[i].locked,
          onSelected: (i) => setState(() => _day = i),
        ),
        const SizedBox(height: 10),
        _LockRow(locked: d.locked, onChanged: (v) => s.setDayLocked(_day, v)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MacroBar(
                        label: 'Kcal',
                        value: total.kcal,
                        target: planned.kcal,
                        color: c.kcal,
                        unit: '',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MacroBar(
                        label: 'Proteine',
                        value: total.protein,
                        target: planned.protein,
                        color: c.protein,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MacroBar(
                        label: 'Carboidrati',
                        value: total.carbs,
                        target: planned.carbs,
                        color: c.carbs,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MacroBar(
                        label: 'Grassi',
                        value: total.fat,
                        target: planned.fat,
                        color: c.fat,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (d.freeSlots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Le barre si riferiscono ai pasti del menu: '
              '~${(d.target.kcal - planned.kcal).round()} kcal restano per '
              '${d.freeSlots.length == 1 ? 'il pasto libero' : 'i pasti liberi'}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final slot in MealSlot.values)
          if (d.freeSlots.contains(slot)) ...[
            _slotHeader(context, slot, '~${freeKcal(slot).round()} kcal'),
            _FreeMealCard(
              kcal: freeKcal(slot),
              onRestore: () =>
                  s.setMealStatus(_day, [slot], MealStatus.planned),
              onRemove: () => s.setMealStatus(_day, [slot], MealStatus.removed),
            ),
          ] else if (d.removedSlots.contains(slot))
            _RemovedMealRow(
              slot: slot,
              onRestore: () =>
                  s.setMealStatus(_day, [slot], MealStatus.planned),
            )
          else if (mealBySlot[slot] case final m?)
            if (recipes[m.recipeId] case final r?) ...[
              _slotHeader(
                context,
                slot,
                '${(r.macrosPerServing(s.foods).kcal * m.servings).round()} kcal',
              ),
              _MealCard(
                meal: m,
                recipe: r,
                onServings: () => showDialog(
                  context: context,
                  builder: (_) =>
                      _ServingsDialog(date: d.date, meal: m, recipe: r),
                ),
                onSwap: () => _swap(context, r),
                dayLocked: d.locked,
                onToggleLock: () =>
                    s.setMealLocked(_day, slot, !m.recipeLocked),
                onFree: () => s.setMealStatus(_day, [slot], MealStatus.free),
                onRemove: () =>
                    s.setMealStatus(_day, [slot], MealStatus.removed),
              ),
            ],
        if (d.extras.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 18,
                  color: c.sport,
                ),
                const SizedBox(width: 8),
                Text('Integrazioni', style: theme.textTheme.titleSmall),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in d.extras)
                InfoPill(
                  '${s.foods[e.foodId]?.name ?? e.foodId} · ${e.grams.round()} g',
                  color: c.sport,
                  background: c.sport.withValues(alpha: 0.12),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _slotHeader(BuildContext context, MealSlot slot, String trailing) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Icon(_slotIcon(slot), size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(slot.label, style: theme.textTheme.titleSmall)),
          Text(
            trailing,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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

/// Pasto fuori dal meal prep: mostra quante kcal restano a disposizione.
class _FreeMealCard extends StatelessWidget {
  final double kcal;
  final VoidCallback onRestore;
  final VoidCallback onRemove;
  const _FreeMealCard({
    required this.kcal,
    required this.onRestore,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: c.subtle,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.no_meals_rounded, color: c.carbs),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pasto libero', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Fuori dal meal prep: hai circa ${kcal.round()} kcal a '
                      'disposizione.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.disabled_by_default_outlined,
                    size: 18,
                  ),
                  label: const Text('Elimina'),
                  onPressed: onRemove,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.restaurant_rounded, size: 18),
                  label: const Text('Ripristina'),
                  onPressed: onRestore,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pasto eliminato: una riga discreta con la possibilità di ripristinarlo.
class _RemovedMealRow extends StatelessWidget {
  final MealSlot slot;
  final VoidCallback onRestore;
  const _RemovedMealRow({required this.slot, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(
            Icons.disabled_by_default_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${slot.label} eliminato: calorie ridistribuite sugli altri pasti',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onRestore, child: const Text('Ripristina')),
        ],
      ),
    );
  }
}

/// Interruttore per bloccare il giorno: la rigenerazione non lo tocca.
class _LockRow extends StatelessWidget {
  final bool locked;
  final ValueChanged<bool> onChanged;
  const _LockRow({required this.locked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = locked
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: locked
          ? theme.colorScheme.primary.withValues(alpha: 0.10)
          : context.colors.subtle,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!locked),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  locked
                      ? 'Giorno bloccato: "Rigenera" non lo modifica'
                      : 'Blocca il giorno (o un singolo pasto dal menu ⋮) per '
                            'mantenerlo quando rigeneri',
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ),
              Switch(value: locked, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealEntry meal;
  final Recipe recipe;
  final VoidCallback onServings;
  final VoidCallback onSwap;
  final VoidCallback onFree;
  final VoidCallback onRemove;
  final VoidCallback onToggleLock;

  /// Giorno bloccato: il pasto è bloccato con lui.
  final bool dayLocked;

  const _MealCard({
    required this.meal,
    required this.recipe,
    required this.onServings,
    required this.onSwap,
    required this.onFree,
    required this.onRemove,
    required this.onToggleLock,
    required this.dayLocked,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final theme = Theme.of(context);
    final c = context.colors;
    final m = recipe.macrosPerServing(s.foods).scale(meal.servings);
    final fixed = meal.locked || recipe.fixedServings != null;
    final kept = meal.recipeLocked || dayLocked;
    return Card(
      child: InkWell(
        onTap: () => showRecipeDetail(context, recipe),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              FoodTile(recipe, size: 58),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (kept)
                          InfoPill(
                            dayLocked ? 'Giorno bloccato' : 'Bloccato',
                            icon: Icons.lock_rounded,
                            color: theme.colorScheme.primary,
                            background: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        InfoPill(
                          '${fmtServings(meal.servings)} porz.',
                          icon: fixed
                              ? Icons.edit_rounded
                              : Icons.restaurant_rounded,
                          color: fixed ? theme.colorScheme.primary : null,
                        ),
                        InfoPill(
                          'P ${m.protein.round()}',
                          color: c.protein,
                          background: c.protein.withValues(alpha: 0.12),
                        ),
                        InfoPill(
                          'C ${m.carbs.round()}',
                          color: c.carbs,
                          background: c.carbs.withValues(alpha: 0.12),
                        ),
                        InfoPill(
                          'G ${m.fat.round()}',
                          color: c.fat,
                          background: c.fat.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Porzioni',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: fixed ? theme.colorScheme.primary : null,
                    ),
                    onPressed: onServings,
                  ),
                  PopupMenuButton<VoidCallback>(
                    tooltip: 'Altre azioni',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) => action(),
                    itemBuilder: (_) => [
                      if (!dayLocked)
                        PopupMenuItem(
                          value: onToggleLock,
                          child: ListTile(
                            leading: Icon(
                              meal.recipeLocked
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                            ),
                            title: Text(
                              meal.recipeLocked
                                  ? 'Sblocca pasto'
                                  : 'Blocca pasto',
                            ),
                            subtitle: const Text(
                              'Rigenerando mantiene la ricetta',
                            ),
                          ),
                        ),
                      PopupMenuItem(
                        value: onSwap,
                        child: const ListTile(
                          leading: Icon(Icons.swap_horiz_rounded),
                          title: Text('Sostituisci in tutta la settimana'),
                        ),
                      ),
                      PopupMenuItem(
                        value: onFree,
                        child: const ListTile(
                          leading: Icon(Icons.no_meals_rounded),
                          title: Text('Rendi pasto libero'),
                          subtitle: Text('Le calorie restano riservate'),
                        ),
                      ),
                      PopupMenuItem(
                        value: onRemove,
                        child: const ListTile(
                          leading: Icon(Icons.disabled_by_default_outlined),
                          title: Text('Elimina pasto'),
                          subtitle: Text('Calorie ridistribuite sugli altri'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    final theme = Theme.of(context);
    final recipes = s.planRecipesById;
    final dates = plan.prepSessions.map((p) => p.date).toSet().toList()..sort();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        for (final (n, date) in dates.indexed) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${n + 1}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessione di ${dayLongFmt.format(date)}',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        'Per ${plan.prepSessions.firstWhere((p) => p.date == date).coversDays.map((d) => dayFmt.format(d).split(' ').first).join(', ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final ps in plan.prepSessions.where((p) => p.date == date))
            if (recipes[ps.recipeId] case final r?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    leading: FoodTile(r, size: 48),
                    title: Text(
                      r.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          InfoPill(
                            '${fmtServings(ps.totalServings)} porzioni',
                            icon: Icons.restaurant_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          InfoPill(
                            'frigo ${r.fridgeDays} gg',
                            icon: Icons.kitchen_rounded,
                          ),
                          if (r.freezable)
                            const InfoPill(
                              'congelabile',
                              icon: Icons.ac_unit_rounded,
                            ),
                          if (r.prepMinutes > 0)
                            InfoPill(
                              '${r.prepMinutes} min',
                              icon: Icons.schedule_rounded,
                            ),
                        ],
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final i in r.ingredients)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.foods[i.foodId]?.name ?? i.foodId,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '${(i.grams * ps.totalServings).round()} g',
                                style: theme.textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      if (r.instructions.isNotEmpty) ...[
                        const Divider(height: 20),
                        Text(r.instructions, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
        ],
        const SizedBox(height: 8),
        if (plan.combos.isNotEmpty)
          const _TipCard(
            'Basi, proteine e verdure si conservano in contenitori separati: '
            'il menu indica come combinarle pasto per pasto.',
          ),
        const _TipCard(
          'Colazioni e spuntini si preparano al momento o la sera prima. '
          'Dividi ogni preparazione nelle porzioni indicate nel menu: nei '
          'giorni più intensi le porzioni sono più abbondanti.',
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.subtle,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
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

  static IconData _icon(FoodCategory c) => switch (c) {
    FoodCategory.meatFish => Icons.set_meal_rounded,
    FoodCategory.dairyEggs => Icons.egg_rounded,
    FoodCategory.grains => Icons.grain_rounded,
    FoodCategory.legumes => Icons.eco_rounded,
    FoodCategory.fruit => Icons.apple_rounded,
    FoodCategory.vegetables => Icons.grass_rounded,
    FoodCategory.nutsSeeds => Icons.spa_rounded,
    FoodCategory.pantry => Icons.inventory_2_rounded,
    FoodCategory.frozen => Icons.ac_unit_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    final theme = Theme.of(context);
    final total = list.byCategory.values.fold<int>(0, (a, l) => a + l.length);
    final done = _checked.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$total prodotti', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      minHeight: 6,
                      backgroundColor: context.colors.subtle,
                      color: context.colors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$done nel carrello',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 18),
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
        for (final e in list.byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Row(
              children: [
                Icon(_icon(e.key), size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.key.label, style: theme.textTheme.titleSmall),
                ),
                Text(
                  '${e.value.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                for (final (i, item) in e.value.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 56),
                  CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: const RoundedRectangleBorder(),
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    value: _checked.contains(item.food.id),
                    onChanged: (v) => setState(
                      () => v == true
                          ? _checked.add(item.food.id)
                          : _checked.remove(item.food.id),
                    ),
                    title: Text(
                      item.food.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: _checked.contains(item.food.id)
                            ? TextDecoration.lineThrough
                            : null,
                        color: _checked.contains(item.food.id)
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      item.quantityLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
