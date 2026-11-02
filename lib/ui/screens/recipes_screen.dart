import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food.dart';
import '../../models/recipe.dart';
import '../../services/claude_client.dart';
import '../../services/meal_planner.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  MealType? _type;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.recipes
        .where((r) => _type == null || r.type == _type)
        .where((r) => r.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'new',
            tooltip: 'Nuova ricetta',
            onPressed: () => _openEditor(context, null),
            child: const Icon(Icons.edit),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'ai',
            icon: const Icon(Icons.auto_awesome),
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: 140),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cerca ricetta',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tutte'),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
                for (final t in MealType.values)
                  ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
          ),
          for (final r in list)
            ListTile(
              leading: Icon(switch (r.source) {
                RecipeSource.builtin => Icons.menu_book,
                RecipeSource.user => Icons.person,
                RecipeSource.ai => Icons.auto_awesome,
              }),
              title: Text(r.name),
              subtitle: Text(
                '${r.type.label} · ${r.macrosPerServing(s.foods)}',
              ),
              trailing: Tooltip(
                message: 'Usa nel meal prep',
                child: Switch(
                  value: !s.mealPrepPrefs.excludedRecipeIds.contains(r.id),
                  onChanged: (v) => s.setRecipeExcluded(r.id, !v),
                ),
              ),
              onTap: () => showRecipeDetail(context, r),
            ),
        ],
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
                '${r.type.label} · ${r.prepMinutes} min · frigo ${r.fridgeDays} gg'
                '${r.freezable ? ' · congelabile' : ''}',
              ),
              const Divider(),
              for (final i in r.ingredients)
                Text(
                  '• ${s.foods[i.foodId]?.name ?? i.foodId}: ${i.grams.round()} g',
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
