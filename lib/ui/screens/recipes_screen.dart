import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food.dart';
import '../../models/recipe.dart';
import '../../services/claude_client.dart';
import '../../services/meal_planner.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/visuals.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  static const _dietTags = ['vegetariano', 'vegano', 'senza glutine'];

  MealType? _type;
  String _query = '';
  bool _seasonOnly = false;
  bool _pinnedOnly = false;
  bool _mineOnly = false;
  final Set<String> _tags = {};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final days = s.weekDays;
    final q = _query.toLowerCase();
    final list = s.recipes
        .where((r) => _type == null || r.type == _type)
        .where((r) => r.name.toLowerCase().contains(q))
        .where((r) => _tags.every(r.tags.contains))
        .where((r) => !_seasonOnly || r.isInSeason(s.foods, days))
        .where(
          (r) => !_pinnedOnly || s.mealPrepPrefs.pinnedRecipeIds.contains(r.id),
        )
        .where((r) => !_mineOnly || r.source == RecipeSource.user)
        .toList();

    final theme = Theme.of(context);
    IconData typeIcon(MealType? t) => switch (t) {
      null => Icons.apps_rounded,
      MealType.breakfast => Icons.breakfast_dining_rounded,
      MealType.main => Icons.dinner_dining_rounded,
      MealType.snack => Icons.cookie_rounded,
    };
    Widget hScroll(List<Widget> children) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            c,
          ],
        ],
      ),
    );

    final header = [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Cerca ricetta',
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      const SizedBox(height: 12),
      hScroll([
        for (final t in <MealType?>[null, ...MealType.values])
          ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              typeIcon(t),
              size: 18,
              color: _type == t ? Colors.white : theme.colorScheme.primary,
            ),
            label: Text(t?.label ?? 'Tutte'),
            selected: _type == t,
            onSelected: (_) => setState(() => _type = t),
          ),
      ]),
      const SizedBox(height: 8),
      hScroll([
        FilterChip(
          avatar: const Icon(Icons.person_outline_rounded, size: 18),
          label: const Text('Mie ricette'),
          tooltip: 'Ricette create o modificate da te',
          selected: _mineOnly,
          onSelected: (v) => setState(() => _mineOnly = v),
        ),
        FilterChip(
          avatar: const Icon(Icons.eco_outlined, size: 18),
          label: const Text('Di stagione'),
          tooltip:
              'Nessun ingrediente fuori stagione nella settimana '
              'selezionata',
          selected: _seasonOnly,
          onSelected: (v) => setState(() => _seasonOnly = v),
        ),
        FilterChip(
          avatar: const Icon(Icons.push_pin_outlined, size: 18),
          label: const Text('Fisse'),
          tooltip: 'Colazioni e spuntini sempre presenti nel menu',
          selected: _pinnedOnly,
          onSelected: (v) => setState(() => _pinnedOnly = v),
        ),
        for (final t in _dietTags)
          FilterChip(
            label: Text(t),
            selected: _tags.contains(t),
            onSelected: (v) =>
                setState(() => v ? _tags.add(t) : _tags.remove(t)),
          ),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
        child: Text(
          '${list.length} ricette',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ];

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'new',
            tooltip: 'Nuova ricetta',
            onPressed: () => _openEditor(context, null),
            child: const Icon(Icons.edit_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'ai',
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Genera con AI'),
            onPressed: () {
              if (!s.claudeConfigured) {
                showInfo(
                  context,
                  'Configura la API key di Anthropic nelle impostazioni',
                );
                return;
              }
              showDialog(context: context, builder: (_) => const _AiDialog());
            },
          ),
        ],
      ),
      // Lista costruita a richiesta: il database contiene centinaia di
      // ricette.
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 140),
        itemCount: header.length + list.length,
        itemBuilder: (context, i) {
          if (i < header.length) return header[i];
          final r = list[i - header.length];
          final inSeason = r.isInSeason(s.foods, days);
          final pinned = s.mealPrepPrefs.pinnedRecipeIds.contains(r.id);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _RecipeCard(
              recipe: r,
              inSeason: inSeason,
              pinned: pinned,
              included: !s.mealPrepPrefs.excludedRecipeIds.contains(r.id),
            ),
          );
        },
      ),
    );
  }
}

const _derivedTags = {
  'vegetariano',
  'vegano',
  'senza glutine',
  'senza lattosio',
};

/// Nota di stagionalità di un ingrediente per la settimana selezionata.
String _seasonNote(Food? f, List<DateTime> days) {
  if (f == null || !f.isSeasonal) return '';
  return days.every(f.inSeason)
      ? ' (di stagione)'
      : days.any(f.inSeason)
      ? ' (a fine o inizio stagione)'
      : ' (fuori stagione)';
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool inSeason;
  final bool pinned;
  final bool included;

  const _RecipeCard({
    required this.recipe,
    required this.inSeason,
    required this.pinned,
    required this.included,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final theme = Theme.of(context);
    final c = context.colors;
    final r = recipe;
    final m = r.macrosPerServing(s.foods);
    return Card(
      child: InkWell(
        onTap: () => showRecipeDetail(context, r),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              Opacity(
                opacity: included ? 1 : 0.4,
                child: FoodTile(r, size: 58),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (r.source != RecipeSource.builtin) ...[
                          Icon(
                            r.source == RecipeSource.ai
                                ? Icons.auto_awesome_rounded
                                : Icons.person_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            r.type.label.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      r.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: included
                            ? null
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        InfoPill(
                          '${m.kcal.round()} kcal',
                          icon: Icons.local_fire_department_rounded,
                          color: c.kcal,
                          background: c.kcal.withValues(alpha: 0.12),
                        ),
                        InfoPill(
                          'P ${m.protein.round()} g',
                          color: c.protein,
                          background: c.protein.withValues(alpha: 0.12),
                        ),
                        if (r.prepMinutes > 0)
                          InfoPill(
                            '${r.prepMinutes} min',
                            icon: Icons.schedule_rounded,
                          ),
                        if (r.fixedServings != null)
                          InfoPill(
                            'porzione fissa',
                            icon: Icons.lock_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        if (!inSeason)
                          const InfoPill(
                            'fuori stagione',
                            icon: Icons.eco_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r.type != MealType.main)
                    IconButton(
                      tooltip: pinned
                          ? 'Non più fissa'
                          : 'Fissa: sempre presente nel menu',
                      isSelected: pinned,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.push_pin_outlined),
                      selectedIcon: Icon(
                        Icons.push_pin_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () => s.setRecipePinned(r.id, !pinned),
                    ),
                  Tooltip(
                    message: 'Usa nel meal prep',
                    child: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: included,
                        onChanged: (v) => s.setRecipeExcluded(r.id, !v),
                      ),
                    ),
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

void _openEditor(BuildContext context, Recipe? r) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RecipeEditor(initial: r),
      fullscreenDialog: true,
    ),
  );
}

Future<void> showRecipeDetail(BuildContext context, Recipe r) {
  final s = context.read<AppState>();
  final m = r.macrosPerServing(s.foods);
  return showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(r.name),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Per porzione', style: Theme.of(c).textTheme.labelMedium),
              const SizedBox(height: 4),
              MacroRow(m),
              const SizedBox(height: 12),
              Text(
                '${r.type.label} · ${r.prepMinutes} min · '
                '${r.fridgeDays == 0 ? 'da consumare subito' : 'frigo ${r.fridgeDays} gg'}'
                '${r.freezable ? ' · congelabile' : ''}',
              ),
              if (r.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final t in r.tags)
                      Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const Divider(),
              for (final i in r.ingredients)
                Text(
                  '• ${s.foods[i.foodId]?.name ?? i.foodId}: ${i.grams.round()} g'
                  '${_seasonNote(s.foods[i.foodId], s.weekDays)}',
                ),
              if (r.instructions.isNotEmpty) ...[
                const Divider(),
                Text(r.instructions),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (r.source != RecipeSource.builtin)
          TextButton(
            onPressed: () {
              s.deleteRecipe(r);
              Navigator.pop(c);
            },
            child: const Text('Elimina'),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(c);
            _openEditor(
              context,
              r.source == RecipeSource.builtin
                  ? r.copyWith(
                      id: s.newRecipeId(),
                      name: '${r.name} (mia)',
                      source: RecipeSource.user,
                    )
                  : r,
            );
          },
          child: Text(
            r.source == RecipeSource.builtin
                ? 'Duplica e modifica'
                : 'Modifica',
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Chiudi'),
        ),
      ],
    ),
  );
}

class RecipeEditor extends StatefulWidget {
  final Recipe? initial;
  const RecipeEditor({super.key, this.initial});

  @override
  State<RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends State<RecipeEditor> {
  late final TextEditingController _name;
  late final TextEditingController _protein;
  late final TextEditingController _instructions;
  late MealType _type;
  late int _fridge;
  late int _minutes;
  late bool _freezable;
  double? _fixedServings;
  late List<Ingredient> _ingredients;
  late String _id;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _id = r?.id ?? context.read<AppState>().newRecipeId();
    _name = TextEditingController(text: r?.name ?? '');
    _protein = TextEditingController(text: r?.mainProtein ?? '');
    _instructions = TextEditingController(text: r?.instructions ?? '');
    _type = r?.type ?? MealType.main;
    _fridge = r?.fridgeDays ?? 3;
    _minutes = r?.prepMinutes ?? 30;
    _freezable = r?.freezable ?? false;
    _fixedServings = r?.fixedServings;
    _ingredients = [...?r?.ingredients];
  }

  @override
  void dispose() {
    _name.dispose();
    _protein.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Recipe _build() => Recipe(
    id: _id,
    name: _name.text.trim(),
    type: _type,
    ingredients: _ingredients,
    instructions: _instructions.text.trim(),
    mainProtein: _protein.text.trim().toLowerCase(),
    fridgeDays: _fridge,
    freezable: _freezable,
    prepMinutes: _minutes,
    fixedServings: _fixedServings,
    // Le etichette di dieta dipendono dagli ingredienti, che qui possono
    // cambiare: restano solo le altre.
    tags: [
      for (final t in widget.initial?.tags ?? const <String>[])
        if (!_derivedTags.contains(t)) t,
    ],
    source: widget.initial?.source == RecipeSource.ai
        ? RecipeSource.ai
        : RecipeSource.user,
  );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final macros = _build().macrosPerServing(s.foods);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Nuova ricetta' : 'Modifica ricetta',
        ),
        actions: [
          TextButton(
            onPressed: _name.text.trim().isEmpty || _ingredients.isEmpty
                ? null
                : () {
                    s.saveRecipe(_build());
                    Navigator.pop(context);
                  },
            child: const Text('Salva'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SegmentedButton<MealType>(
            segments: [
              for (final t in MealType.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _protein,
                  decoration: const InputDecoration(
                    labelText: 'Fonte proteica',
                    hintText: 'pollo, legumi…',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _fridge,
                  decoration: const InputDecoration(
                    labelText: 'Giorni in frigo',
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('Subito')),
                    for (var i = 1; i <= 6; i++)
                      DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (v) => setState(() => _fridge = v ?? 3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: '$_minutes',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minuti'),
                  onChanged: (v) => _minutes = int.tryParse(v) ?? _minutes,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Congelabile'),
            value: _freezable,
            onChanged: (v) => setState(() => _freezable = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Porzione fissa'),
            subtitle: const Text(
              'Nel menu si mangia sempre questa quantità, senza adattarla '
              'alle kcal del giorno',
            ),
            value: _fixedServings != null,
            onChanged: (v) => setState(() => _fixedServings = v ? 1 : null),
          ),
          if (_fixedServings != null)
            Row(
              children: [
                const Expanded(child: Text('Porzioni per pasto')),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _fixedServings! > 0.25
                      ? () => setState(
                          () => _fixedServings = _fixedServings! - 0.25,
                        )
                      : null,
                ),
                Text(fmtServings(_fixedServings!)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _fixedServings! < 4
                      ? () => setState(
                          () => _fixedServings = _fixedServings! + 0.25,
                        )
                      : null,
                ),
              ],
            ),
          SectionTitle(
            'Ingredienti (per porzione)',
            trailing: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
              onPressed: () async {
                final ing = await showDialog<Ingredient>(
                  context: context,
                  builder: (_) => const _IngredientDialog(),
                );
                if (ing != null) setState(() => _ingredients.add(ing));
              },
            ),
          ),
          MacroRow(macros),
          for (var i = 0; i < _ingredients.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                s.foods[_ingredients[i].foodId]?.name ?? _ingredients[i].foodId,
              ),
              subtitle: Text(
                s.foods[_ingredients[i].foodId]
                        ?.forGrams(_ingredients[i].grams)
                        .toString() ??
                    '',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      key: ValueKey('g$i${_ingredients[i].foodId}'),
                      initialValue: _ingredients[i].grams.round().toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(suffixText: 'g'),
                      onChanged: (v) {
                        final g = double.tryParse(v);
                        if (g != null) {
                          setState(
                            () => _ingredients[i] = Ingredient(
                              _ingredients[i].foodId,
                              g,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _ingredients.removeAt(i)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructions,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Procedimento',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientDialog extends StatefulWidget {
  const _IngredientDialog();

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  Food? _food;
  final _grams = TextEditingController(text: '100');

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final foods = s.foods.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return AlertDialog(
      title: const Text('Aggiungi ingrediente'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<Food>(
              displayStringForOption: (f) => f.name,
              optionsBuilder: (v) => foods.where(
                (f) => f.name.toLowerCase().contains(v.text.toLowerCase()),
              ),
              onSelected: (f) => setState(() => _food = f),
              fieldViewBuilder: (context, c, focus, submit) => TextField(
                controller: c,
                focusNode: focus,
                decoration: const InputDecoration(labelText: 'Alimento'),
              ),
            ),
            TextField(
              controller: _grams,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Grammi per porzione',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nuovo alimento'),
                onPressed: () async {
                  final f = await showDialog<Food>(
                    context: context,
                    builder: (_) => const FoodDialog(),
                  );
                  if (f != null) {
                    s.saveFood(f);
                    setState(() => _food = f);
                  }
                },
              ),
            ),
            if (_food != null) Text('Selezionato: ${_food!.name}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _food == null
              ? null
              : () => Navigator.pop(
                  context,
                  Ingredient(_food!.id, double.tryParse(_grams.text) ?? 100),
                ),
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}

class FoodDialog extends StatefulWidget {
  const FoodDialog({super.key});

  @override
  State<FoodDialog> createState() => _FoodDialogState();
}

class _FoodDialogState extends State<FoodDialog> {
  final _name = TextEditingController();
  final _values = List.generate(4, (_) => TextEditingController());
  FoodCategory _cat = FoodCategory.pantry;

  @override
  void dispose() {
    _name.dispose();
    for (final c in _values) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(int i) =>
      double.tryParse(_values[i].text.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    const labels = ['kcal', 'Proteine g', 'Carboidrati g', 'Grassi g'];
    return AlertDialog(
      title: const Text('Nuovo alimento'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            DropdownButtonFormField<FoodCategory>(
              initialValue: _cat,
              decoration: const InputDecoration(labelText: 'Reparto'),
              items: [
                for (final c in FoodCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _cat = v ?? _cat),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Valori per 100 g (crudo)'),
            ),
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextField(
                        controller: _values[i],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(labelText: labels[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              Food(
                id: context.read<AppState>().newFoodId(),
                name: _name.text.trim(),
                category: _cat,
                per100g: Macros(_v(0), _v(1), _v(2), _v(3)),
              ),
            );
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

class _AiDialog extends StatefulWidget {
  const _AiDialog();

  @override
  State<_AiDialog> createState() => _AiDialogState();
}

class _AiDialogState extends State<_AiDialog> {
  final _prompt = TextEditingController();
  MealType _type = MealType.main;
  int _count = 2;
  bool _useTarget = true;
  bool _loading = false;
  GeneratedRecipes? _result;
  final _selected = <String>{};

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Macros _targetPerServing(AppState s) {
    final days = s.weekEnergy;
    final avg = days
        .fold(Macros.zero, (a, d) => a + d.target)
        .scale(1 / days.length);
    final shares = MealPlanner.slotShares(s.profile.mealsPerDay);
    final share = shares.entries
        .where((e) => e.key.type == _type)
        .map((e) => e.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return avg.scale(share == 0 ? 0.3 : share);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final target = _targetPerServing(s);
    final result = _result;
    final allFoods = {
      ...s.foods,
      if (result != null)
        for (final f in result.newFoods) f.id: f,
    };

    return AlertDialog(
      title: const Text('Genera ricette con Claude'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result == null) ...[
                SegmentedButton<MealType>(
                  segments: [
                    for (final t in MealType.values)
                      ButtonSegment(value: t, label: Text(t.label)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _prompt,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Cosa ti va?',
                    hintText: 'es. piatti unici con pesce, pronti in 30 minuti, che durino 4 giorni',
                  ),
                ),
                Row(
                  children: [
                    const Text('Quante ricette'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _count,
                      items: [
                        for (var i = 1; i <= 4; i++)
                          DropdownMenuItem(value: i, child: Text('$i')),
                      ],
                      onChanged: (v) => setState(() => _count = v ?? 2),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _useTarget,
                  onChanged: (v) => setState(() => _useTarget = v ?? true),
                  title: const Text('Adatta ai miei macro'),
                  subtitle: Text('Per porzione: $target'),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Claude sta preparando le ricette, può volerci un minuto…',
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else
                for (final r in result.recipes)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(r.id),
                    onChanged: (v) => setState(
                      () => v == true
                          ? _selected.add(r.id)
                          : _selected.remove(r.id),
                    ),
                    title: Text(r.name),
                    subtitle: Text(
                      '${r.macrosPerServing(allFoods)}\n'
                      '${r.ingredients.map((i) => '${allFoods[i.foodId]?.name} ${i.grams.round()} g').join(', ')}',
                    ),
                    isThreeLine: true,
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Chiudi'),
        ),
        if (result == null)
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    final g = await guarded(
                      context,
                      () => s.generateRecipes(
                        RecipeRequest(
                          prompt: _prompt.text.trim(),
                          type: _type,
                          count: _count,
                          targetPerServing: _useTarget ? target : null,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    setState(() {
                      _loading = false;
                      _result = g;
                      if (g != null) {
                        _selected.addAll(g.recipes.map((r) => r.id));
                      }
                    });
                  },
            child: const Text('Genera'),
          )
        else
          FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    s.saveGenerated(
                      result,
                      result.recipes.where((r) => _selected.contains(r.id)),
                    );
                    Navigator.pop(context);
                    showInfo(
                      context,
                      '${_selected.length} ricette aggiunte al ricettario',
                    );
                  },
            child: const Text('Salva selezionate'),
          ),
      ],
    );
  }
}
