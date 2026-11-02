import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/food.dart';
import '../models/recipe.dart';

class ClaudeException implements Exception {
  final String message;
  ClaudeException(this.message);

  @override
  String toString() => 'Claude: $message';
}

/// Richiesta di generazione ricette.
class RecipeRequest {
  final String prompt;
  final MealType type;
  final int count;

  /// Macro target per porzione (opzionale).
  final Macros? targetPerServing;

  const RecipeRequest({
    required this.prompt,
    required this.type,
    this.count = 1,
    this.targetPerServing,
  });
}

class GeneratedRecipes {
  final List<Recipe> recipes;

  /// Alimenti non presenti nel database, da aggiungere insieme alle ricette.
  final List<Food> newFoods;

  const GeneratedRecipes(this.recipes, this.newFoods);
}

/// Client minimale per la Messages API di Anthropic (HTTP diretto: non esiste
/// un SDK ufficiale per Dart).
class ClaudeClient {
  static const defaultModel = 'claude-opus-5-5';
  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  final String apiKey;
  final String model;
  final http.Client _http;

  ClaudeClient({required this.apiKey, String? model, http.Client? httpClient})
    : model = (model == null || model.isEmpty) ? defaultModel : model,
      _http = httpClient ?? http.Client();

  static final Map<String, dynamic> _schema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['recipes'],
    'properties': {
      'recipes': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'name',
            'mainProtein',
            'fridgeDays',
            'freezable',
            'prepMinutes',
            'instructions',
            'ingredients',
          ],
          'properties': {
            'name': {'type': 'string'},
            'mainProtein': {
              'type': 'string',
              'description':
                  'fonte proteica principale in minuscolo: pollo, tacchino, '
                  'manzo, maiale, pesce, uova, latticini, legumi, vegetale',
            },
            'fridgeDays': {'type': 'integer'},
            'freezable': {'type': 'boolean'},
            'prepMinutes': {'type': 'integer'},
            'instructions': {'type': 'string'},
            'ingredients': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'foodId',
                  'name',
                  'grams',
                  'category',
                  'kcal',
                  'protein',
                  'carbs',
                  'fat',
                ],
                'properties': {
                  'foodId': {
                    'type': 'string',
                    'description': 'id dal database fornito, oppure stringa vuota se nuovo',
                  },
                  'name': {'type': 'string'},
                  'grams': {
                    'type': 'number',
                    'description': 'grammi per UNA porzione, da crudo/secco',
                  },
                  'category': {
                    'type': 'string',
                    'enum': FoodCategory.values.map((c) => c.name).toList(),
                  },
                  'kcal': {'type': 'number', 'description': 'per 100 g'},
                  'protein': {'type': 'number', 'description': 'g per 100 g'},
                  'carbs': {
                    'type': 'number',
                    'description': 'g per 100 g, al netto della fibra',
                  },
                  'fat': {'type': 'number', 'description': 'g per 100 g'},
                },
              },
            },
          },
        },
      },
    },
  };

  Future<GeneratedRecipes> generateRecipes(
    RecipeRequest req,
    Map<String, Food> foods,
  ) async {
    final foodList = foods.values
        .map(
          (f) =>
              '${f.id} | ${f.name} | ${f.per100g.kcal.round()} kcal, P ${f.per100g.protein}, C ${f.per100g.carbs}, G ${f.per100g.fat}',
        )
        .join('\n');
    final t = req.targetPerServing;
    final target = t == null
        ? ''
        : '\nMacro target per porzione (tolleranza ±10%): ${t.kcal.round()} kcal, '
              'proteine ${t.protein.round()} g, carboidrati ${t.carbs.round()} g, '
              'grassi ${t.fat.round()} g.';

    final system =
        'Sei un nutrizionista sportivo e cuoco. Crei ricette semplici, '
        'adatte al meal prep, per chi pratica corsa, ciclismo e palestra. '
        'Scrivi in italiano. Le grammature sono per UNA porzione, a crudo o '
        'secco. Usa gli alimenti del database quando possibile (riporta il '
        'loro id e i loro valori); per alimenti nuovi lascia foodId vuoto e '
        'fornisci valori per 100 g realistici (tabelle CREA/USDA). '
        'fridgeDays è il numero di giorni di conservazione in frigo dopo la '
        'cottura. Le istruzioni sono brevi, con indicazioni per la '
        'preparazione in anticipo.';

    final user =
        'Database alimenti (id | nome | valori per 100 g):\n'
        '$foodList\n\n'
        'Genera ${req.count} ricett${req.count == 1 ? 'a' : 'e'} di tipo '
        '"${req.type.label}". Richiesta: ${req.prompt.isEmpty ? 'nessuna preferenza' : req.prompt}.'
        '$target';

    final body = {
      'model': model,
      'max_tokens': 16000,
      // Su rifiuto dei classificatori la richiesta viene ripetuta su un
      // modello di fallback scelto lato server.
      'fallbacks': 'default',
      'output_config': {
        'effort': 'medium',
        'format': {'type': 'json_schema', 'schema': _schema},
      },
      'system': system,
      'messages': [
        {'role': 'user', 'content': user},
      ],
    };

    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2026-10-21',
              'anthropic-beta': 'server-side-fallback-2026-07-01',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(minutes: 5));
    } catch (e) {
      throw ClaudeException('connessione non riuscita ($e)');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200) {
      final msg = (decoded is Map && decoded['error'] is Map)
          ? decoded['error']['message']
          : res.body;
      throw ClaudeException('errore ${res.statusCode}: $msg');
    }
    final stop = decoded['stop_reason'];
    if (stop == 'refusal') {
      throw ClaudeException('la richiesta è stata rifiutata dal modello.');
    }
    if (stop == 'max_tokens') {
      throw ClaudeException('risposta troncata: chiedi meno ricette.');
    }
    final text = (decoded['content'] as List)
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } on FormatException {
      throw ClaudeException('risposta non in formato JSON valido.');
    }
    return parseRecipes(json, req.type, foods);
  }

  /// Converte la risposta JSON in ricette, riconciliando gli ingredienti con
  /// il database (per id, poi per nome) e creando gli alimenti mancanti.
  static GeneratedRecipes parseRecipes(
    Map<String, dynamic> json,
    MealType type,
    Map<String, Food> foods,
  ) {
    const uuid = Uuid();
    final byName = {
      for (final f in foods.values) f.name.toLowerCase().trim(): f,
    };
    final newFoods = <String, Food>{};
    final recipes = <Recipe>[];

    for (final r in (json['recipes'] as List).cast<Map<String, dynamic>>()) {
      final ingredients = <Ingredient>[];
      for (final i in (r['ingredients'] as List).cast<Map<String, dynamic>>()) {
        final id = i['foodId'] as String? ?? '';
        final name = (i['name'] as String).trim();
        final grams = (i['grams'] as num).toDouble();
        Food? food =
            foods[id] ??
            byName[name.toLowerCase()] ??
            newFoods[name.toLowerCase()];
        if (food == null) {
          food = Food(
            id: 'f_ai_${uuid.v4().substring(0, 8)}',
            name: name,
            category:
                FoodCategory.values.asNameMap()[i['category']] ??
                FoodCategory.pantry,
            per100g: Macros(
              (i['kcal'] as num).toDouble(),
              (i['protein'] as num).toDouble(),
              (i['carbs'] as num).toDouble(),
              (i['fat'] as num).toDouble(),
            ),
          );
          newFoods[name.toLowerCase()] = food;
        }
        ingredients.add(Ingredient(food.id, grams));
      }
      recipes.add(
        Recipe(
          id: 'r_ai_${uuid.v4().substring(0, 8)}',
          name: r['name'] as String,
          type: type,
          ingredients: ingredients,
          instructions: r['instructions'] as String? ?? '',
          mainProtein: (r['mainProtein'] as String? ?? '').toLowerCase(),
          fridgeDays: (r['fridgeDays'] as num?)?.toInt() ?? 3,
          freezable: r['freezable'] as bool? ?? false,
          prepMinutes: (r['prepMinutes'] as num?)?.toInt() ?? 30,
          source: RecipeSource.ai,
        ),
      );
    }
    return GeneratedRecipes(recipes, newFoods.values.toList());
  }

  void close() => _http.close();
}
