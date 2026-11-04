import 'dart:io';

import 'package:traincal/data/food_db.dart';

/// Il database incluso nell'app, letto direttamente dagli asset.
final testDb = FoodDb.parse(
  File(FoodDb.foodsAsset).readAsStringSync(),
  File(FoodDb.recipesAsset).readAsStringSync(),
);
