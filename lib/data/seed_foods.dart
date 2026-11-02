import '../models/food.dart';

// Valori indicativi per 100 g di prodotto crudo/secco, ricavati dalle tabelle
// CREA e USDA. I carboidrati sono al netto della fibra.
Food _f(
  String id,
  String name,
  FoodCategory c,
  double kcal,
  double p,
  double cho,
  double fat, {
  double? unit,
  String? unitName,
  double? pack,
}) => Food(
  id: id,
  name: name,
  category: c,
  per100g: Macros(kcal, p, cho, fat),
  unitGrams: unit,
  unitName: unitName,
  packageGrams: pack,
  builtin: true,
);

const _m = FoodCategory.meatFish;
const _d = FoodCategory.dairyEggs;
const _g = FoodCategory.grains;
const _l = FoodCategory.legumes;
const _fr = FoodCategory.fruit;
const _v = FoodCategory.vegetables;
const _n = FoodCategory.nutsSeeds;
const _p = FoodCategory.pantry;
const _z = FoodCategory.frozen;

final List<Food> seedFoods = [
  // Carne e pesce
  _f('f_pollo', 'Petto di pollo', _m, 110, 23, 0, 1.5, pack: 500),
  _f('f_tacchino', 'Fesa di tacchino', _m, 107, 24, 0, 1.2, pack: 500),
  _f('f_manzo', 'Manzo magro (girello)', _m, 120, 21.5, 0, 3.5, pack: 400),
  _f('f_macinato', 'Macinato di manzo 5%', _m, 137, 21, 0, 5.5, pack: 500),
  _f('f_lonza', 'Lonza di maiale', _m, 146, 21, 0, 7, pack: 500),
  _f('f_salmone', 'Salmone fresco', _m, 200, 20, 0, 13, pack: 300),
  _f('f_merluzzo', 'Merluzzo / nasello', _m, 75, 17, 0, 0.7, pack: 400),
  _f(
    'f_tonno',
    'Tonno al naturale (sgocciolato)',
    _m,
    108,
    25,
    0,
    1,
    unit: 52,
    unitName: 'scatoletta',
    pack: 156,
  ),
  _f('f_bresaola', 'Bresaola', _m, 151, 32, 0.4, 2, pack: 80),

  // Latticini e uova
  _f('f_uova', 'Uova', _d, 128, 12.4, 0, 8.7, unit: 55, unitName: 'uovo'),
  _f('f_albume', 'Albume', _d, 43, 10.7, 0.7, 0, pack: 500),
  _f('f_yogurt_greco', 'Yogurt greco 0%', _d, 57, 10, 4, 0.2, pack: 500),
  _f('f_skyr', 'Skyr', _d, 63, 11, 4, 0.2, pack: 450),
  _f('f_latte', 'Latte parzialmente scremato', _d, 46, 3.5, 5, 1.6, pack: 1000),
  _f('f_fiocchi_latte', 'Fiocchi di latte', _d, 98, 11.5, 3, 4.5, pack: 200),
  _f('f_ricotta', 'Ricotta vaccina', _d, 146, 8.8, 3.5, 10.9, pack: 250),
  _f('f_mozzarella_light', 'Mozzarella light', _d, 163, 19, 1.5, 9, pack: 125),
  _f('f_parmigiano', 'Parmigiano Reggiano', _d, 392, 33.5, 0, 28.1, pack: 200),
  _f('f_feta', 'Feta', _d, 264, 14, 4, 21, pack: 200),
  _f('f_whey', 'Proteine whey', _d, 380, 78, 7, 5, pack: 1000),

  // Cereali, pane e patate
  _f('f_avena', "Fiocchi d'avena", _g, 370, 13.5, 60, 7, pack: 500),
  _f('f_pasta', 'Pasta di semola', _g, 355, 12.5, 71, 1.5, pack: 500),
  _f('f_pasta_int', 'Pasta integrale', _g, 340, 13.5, 64, 2.5, pack: 500),
  _f('f_riso', 'Riso basmati', _g, 355, 7.5, 79, 0.6, pack: 1000),
  _f('f_riso_int', 'Riso integrale', _g, 360, 7.5, 74, 2.7, pack: 1000),
  _f('f_farro', 'Farro perlato', _g, 340, 14, 67, 2.5, pack: 500),
  _f('f_quinoa', 'Quinoa', _g, 368, 14, 64, 6, pack: 500),
  _f('f_couscous', 'Cous cous', _g, 370, 13, 74, 0.6, pack: 500),
  _f('f_pane_int', 'Pane integrale', _g, 245, 9, 44, 3, pack: 500),
  _f('f_fette', 'Fette biscottate', _g, 405, 11, 76, 6, pack: 300),
  _f(
    'f_gallette',
    'Gallette di riso',
    _g,
    385,
    8,
    81,
    3,
    unit: 8,
    unitName: 'galletta',
    pack: 120,
  ),
  _f(
    'f_tortilla',
    'Tortilla integrale',
    _g,
    300,
    9,
    48,
    7,
    unit: 62,
    unitName: 'tortilla',
    pack: 370,
  ),
  _f('f_patate', 'Patate', _g, 77, 2, 17, 0.1, pack: 1500),
  _f('f_patate_dolci', 'Patate dolci', _g, 86, 1.6, 20, 0.1, pack: 1000),

  // Legumi e proteine vegetali
  _f(
    'f_ceci',
    'Ceci in scatola (sgocciolati)',
    _l,
    119,
    7,
    16.5,
    2.5,
    pack: 240,
  ),
  _f(
    'f_fagioli',
    'Fagioli borlotti in scatola (sgocciolati)',
    _l,
    100,
    6.5,
    15,
    0.5,
    pack: 240,
  ),
  _f('f_lenticchie', 'Lenticchie secche', _l, 330, 24, 51, 1.5, pack: 500),
  _f('f_tofu', 'Tofu', _l, 130, 13, 2, 7.5, pack: 200),

  // Frutta
  _f(
    'f_banana',
    'Banana',
    _fr,
    89,
    1.1,
    20,
    0.3,
    unit: 120,
    unitName: 'banana',
  ),
  _f('f_mela', 'Mela', _fr, 52, 0.3, 12.5, 0.2, unit: 150, unitName: 'mela'),
  _f('f_kiwi', 'Kiwi', _fr, 61, 1.1, 13, 0.5, unit: 75, unitName: 'kiwi'),
  _f(
    'f_arancia',
    'Arancia',
    _fr,
    47,
    0.9,
    10.5,
    0.1,
    unit: 180,
    unitName: 'arancia',
  ),
  _f('f_datteri', 'Datteri secchi', _fr, 280, 2.5, 66, 0.4, pack: 200),
  _f(
    'f_avocado',
    'Avocado',
    _fr,
    160,
    2,
    2,
    14.7,
    unit: 150,
    unitName: 'avocado',
  ),

  // Verdura
  _f('f_zucchine', 'Zucchine', _v, 17, 1.2, 3.1, 0.3),
  _f('f_broccoli', 'Broccoli', _v, 34, 2.8, 4.5, 0.4),
  _f('f_spinaci', 'Spinaci', _v, 23, 2.9, 1.6, 0.4),
  _f('f_pomodorini', 'Pomodorini', _v, 20, 1, 3.9, 0.2),
  _f('f_peperoni', 'Peperoni', _v, 27, 1, 5, 0.3),
  _f('f_carote', 'Carote', _v, 41, 0.9, 8, 0.2),
  _f('f_cipolla', 'Cipolla', _v, 40, 1.1, 9, 0.1),
  _f('f_insalata', 'Insalata mista', _v, 17, 1.3, 2.5, 0.2),
  _f('f_rucola', 'Rucola', _v, 25, 2.6, 2, 0.7),
  _f('f_fagiolini', 'Fagiolini', _v, 31, 1.8, 5, 0.2),
  _f('f_funghi', 'Funghi champignon', _v, 22, 3.1, 3.3, 0.3),

  // Frutta secca e semi
  _f('f_mandorle', 'Mandorle', _n, 580, 21, 10, 50, pack: 200),
  _f('f_noci', 'Noci sgusciate', _n, 654, 15, 7, 65, pack: 150),
  _f('f_burro_arachidi', "Burro d'arachidi", _n, 590, 25, 16, 50, pack: 350),
  _f('f_chia', 'Semi di chia', _n, 486, 17, 8, 31, pack: 250),

  // Dispensa
  _f('f_olio', "Olio extravergine d'oliva", _p, 899, 0, 0, 99.9, pack: 1000),
  _f('f_passata', 'Passata di pomodoro', _p, 36, 1.5, 6.5, 0.2, pack: 700),
  _f('f_miele', 'Miele', _p, 304, 0.3, 82, 0, pack: 500),
  _f('f_soia', 'Salsa di soia', _p, 53, 8, 5, 0.6, pack: 150),
  _f('f_cioccolato', 'Cioccolato fondente 85%', _p, 600, 10, 19, 52, pack: 100),

  // Surgelati
  _f(
    'f_frutti_bosco',
    'Frutti di bosco surgelati',
    _z,
    45,
    0.8,
    8,
    0.3,
    pack: 300,
  ),
  _f('f_piselli', 'Piselli surgelati', _z, 75, 5.4, 10, 0.4, pack: 450),
  _f('f_edamame', 'Edamame surgelati', _z, 121, 12, 9, 5, pack: 400),
];
