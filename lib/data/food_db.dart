import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/food.dart';
import '../models/recipe.dart';

/// Database di alimenti e ricette incluso nell'app, generato da
/// `tool/recipe_db/build.py` in `assets/db/`.
class FoodDb {
  static const foodsAsset = 'assets/db/foods.json';
  static const recipesAsset = 'assets/db/recipes.json';

  final List<Food> foods;
  final List<Recipe> recipes;

  const FoodDb(this.foods, this.recipes);

  factory FoodDb.parse(String foodsJson, String recipesJson) => FoodDb(
    (jsonDecode(foodsJson) as List)
        .map((j) => Food.fromJson(j as Map<String, dynamic>, builtin: true))
        .toList(),
    (jsonDecode(recipesJson) as List)
        .map((j) => Recipe.fromJson(j as Map<String, dynamic>))
        .toList(),
  );

  static Future<FoodDb> load() async => FoodDb.parse(
    await rootBundle.loadString(foodsAsset),
    await rootBundle.loadString(recipesAsset),
  );
}
