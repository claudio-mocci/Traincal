import '../models/recipe.dart';

Recipe _r(
  String id,
  String name,
  MealType type,
  Map<String, double> ingredients, {
  required String protein,
  String how = '',
  int fridge = 3,
  bool freeze = false,
  int minutes = 30,
}) => Recipe(
  id: id,
  name: name,
  type: type,
  ingredients: ingredients.entries
      .map((e) => Ingredient(e.key, e.value))
      .toList(),
  instructions: how,
  mainProtein: protein,
  fridgeDays: fridge,
  freezable: freeze,
  prepMinutes: minutes,
  source: RecipeSource.builtin,
);

const _b = MealType.breakfast;
const _main = MealType.main;
const _s = MealType.snack;

final List<Recipe> seedRecipes = [
  // Colazioni
  _r(
    'r_porridge',
    'Porridge proteico ai frutti di bosco',
    _b,
    {
      'f_avena': 60,
      'f_latte': 200,
      'f_whey': 25,
      'f_frutti_bosco': 100,
      'f_miele': 10,
    },
    protein: 'latticini',
    fridge: 3,
    minutes: 10,
    how:
        'Cuoci l\'avena nel latte per 4-5 minuti. Fuori dal fuoco aggiungi '
        'le proteine, poi frutti di bosco e miele. Si conserva in barattoli '
        '(overnight oats) per 3 giorni.',
  ),
  _r(
    'r_yogurt_bowl',
    'Bowl di yogurt greco, avena e banana',
    _b,
    {
      'f_yogurt_greco': 200,
      'f_avena': 40,
      'f_banana': 120,
      'f_noci': 15,
      'f_miele': 10,
    },
    protein: 'latticini',
    fridge: 2,
    minutes: 5,
    how:
        'Componi la bowl con yogurt, avena, banana a rondelle, noci '
        'tritate e miele.',
  ),
  _r(
    'r_toast_uova',
    'Toast integrale con uova e avocado',
    _b,
    {'f_pane_int': 80, 'f_uova': 110, 'f_avocado': 40, 'f_pomodorini': 80},
    protein: 'uova',
    fridge: 1,
    minutes: 10,
    how:
        'Tosta il pane, schiaccia l\'avocado, aggiungi le uova strapazzate '
        'o in camicia e i pomodorini.',
  ),
  _r(
    'r_pancake',
    'Pancake di avena e albumi',
    _b,
    {
      'f_avena': 50,
      'f_albume': 150,
      'f_banana': 80,
      'f_burro_arachidi': 15,
      'f_frutti_bosco': 80,
    },
    protein: 'uova',
    fridge: 3,
    freeze: true,
    minutes: 15,
    how:
        'Frulla avena, albumi e banana. Cuoci in padella antiaderente. '
        'Servi con burro d\'arachidi e frutti di bosco. Si congelano bene.',
  ),
  _r(
    'r_fette_ricotta',
    'Fette biscottate con ricotta e miele',
    _b,
    {
      'f_fette': 40,
      'f_ricotta': 80,
      'f_miele': 15,
      'f_latte': 200,
      'f_kiwi': 75,
    },
    protein: 'latticini',
    fridge: 1,
    minutes: 5,
    how:
        'Spalma la ricotta sulle fette e completa con il miele. '
        'Accompagna con latte e un kiwi.',
  ),

  // Pranzi e cene da meal prep
  _r(
    'r_pollo_curry',
    'Pollo al curry con riso basmati e zucchine',
    _main,
    {
      'f_pollo': 150,
      'f_riso': 80,
      'f_zucchine': 150,
      'f_cipolla': 30,
      'f_yogurt_greco': 30,
      'f_olio': 10,
    },
    protein: 'pollo',
    fridge: 4,
    freeze: true,
    minutes: 35,
    how:
        'Rosola la cipolla nell\'olio, aggiungi il pollo a cubetti e il '
        'curry. Unisci le zucchine e cuoci 10 minuti. Fuori dal fuoco '
        'manteca con lo yogurt. Servi con il riso basmati.',
  ),
  _r(
    'r_tacchino_quinoa',
    'Bowl di tacchino, quinoa e verdure al forno',
    _main,
    {
      'f_tacchino': 140,
      'f_quinoa': 70,
      'f_peperoni': 100,
      'f_zucchine': 100,
      'f_olio': 10,
    },
    protein: 'tacchino',
    fridge: 4,
    minutes: 40,
    how:
        'Cuoci la quinoa. Arrostisci in forno a 200°C peperoni e zucchine '
        'per 25 minuti. Griglia il tacchino e componi le bowl.',
  ),
  _r(
    'r_pasta_ragu',
    'Pasta integrale al ragù di manzo',
    _main,
    {
      'f_pasta_int': 90,
      'f_macinato': 120,
      'f_passata': 150,
      'f_carote': 30,
      'f_cipolla': 30,
      'f_olio': 8,
      'f_parmigiano': 10,
    },
    protein: 'manzo',
    fridge: 4,
    freeze: true,
    minutes: 60,
    how:
        'Soffriggi carota e cipolla, aggiungi il macinato e rosola. Unisci '
        'la passata e cuoci almeno 40 minuti. Il ragù si congela in '
        'porzioni; cuoci la pasta al momento o il giorno prima.',
  ),
  _r(
    'r_salmone_patate',
    'Salmone al forno con patate e broccoli',
    _main,
    {'f_salmone': 150, 'f_patate': 250, 'f_broccoli': 150, 'f_olio': 8},
    protein: 'pesce',
    fridge: 2,
    minutes: 40,
    how:
        'Inforna le patate a spicchi a 200°C per 20 minuti, aggiungi '
        'salmone e broccoli e prosegui per altri 15 minuti.',
  ),
  _r(
    'r_merluzzo_couscous',
    'Merluzzo con cous cous e pomodorini',
    _main,
    {
      'f_merluzzo': 180,
      'f_couscous': 80,
      'f_pomodorini': 120,
      'f_zucchine': 100,
      'f_olio': 10,
    },
    protein: 'pesce',
    fridge: 2,
    minutes: 25,
    how:
        'Cuoci il merluzzo in padella con i pomodorini. Prepara il cous '
        'cous con acqua bollente e saltalo con le zucchine.',
  ),
  _r(
    'r_chili',
    'Chili con carne e fagioli con riso',
    _main,
    {
      'f_macinato': 100,
      'f_fagioli': 120,
      'f_passata': 150,
      'f_peperoni': 80,
      'f_cipolla': 30,
      'f_riso': 60,
      'f_olio': 8,
    },
    protein: 'manzo',
    fridge: 4,
    freeze: true,
    minutes: 50,
    how:
        'Rosola cipolla e peperoni, aggiungi la carne, poi fagioli, passata '
        'e spezie (cumino, paprika). Cuoci 30 minuti. Servi con il riso.',
  ),
  _r(
    'r_curry_ceci',
    'Curry di ceci e spinaci con riso',
    _main,
    {
      'f_ceci': 200,
      'f_spinaci': 120,
      'f_passata': 100,
      'f_riso': 70,
      'f_yogurt_greco': 50,
      'f_olio': 10,
    },
    protein: 'legumi',
    fridge: 5,
    freeze: true,
    minutes: 30,
    how:
        'Soffriggi le spezie nell\'olio, aggiungi ceci e passata e cuoci '
        '15 minuti. Unisci gli spinaci fino a farli appassire. Servi con '
        'riso e yogurt.',
  ),
  _r(
    'r_farro_tonno',
    'Insalata di farro, tonno e pomodorini',
    _main,
    {
      'f_farro': 80,
      'f_tonno': 120,
      'f_pomodorini': 120,
      'f_rucola': 30,
      'f_olio': 10,
    },
    protein: 'pesce',
    fridge: 3,
    minutes: 25,
    how:
        'Lessa il farro e lascialo raffreddare. Condisci con tonno, '
        'pomodorini, rucola e olio.',
  ),
  _r(
    'r_frittata',
    'Frittata al forno di verdure con patate dolci',
    _main,
    {
      'f_uova': 110,
      'f_albume': 120,
      'f_spinaci': 100,
      'f_zucchine': 100,
      'f_patate_dolci': 200,
      'f_parmigiano': 10,
      'f_olio': 5,
    },
    protein: 'uova',
    fridge: 3,
    minutes: 40,
    how:
        'Sbatti uova, albumi e parmigiano, unisci le verdure e cuoci in '
        'teglia a 180°C per 25 minuti. Patate dolci al forno a parte.',
  ),
  _r(
    'r_riso_wok',
    'Riso saltato con pollo e verdure',
    _main,
    {
      'f_riso': 80,
      'f_pollo': 140,
      'f_piselli': 60,
      'f_carote': 60,
      'f_uova': 55,
      'f_soia': 15,
      'f_olio': 10,
    },
    protein: 'pollo',
    fridge: 3,
    minutes: 30,
    how:
        'Usa riso già cotto e freddo. Salta in padella il pollo, poi '
        'carote e piselli, l\'uovo strapazzato e infine il riso con la '
        'salsa di soia.',
  ),
  _r(
    'r_polpette',
    'Polpette di tacchino al sugo con purè',
    _main,
    {
      'f_tacchino': 150,
      'f_passata': 150,
      'f_patate': 250,
      'f_parmigiano': 10,
      'f_latte': 50,
      'f_olio': 8,
    },
    protein: 'tacchino',
    fridge: 4,
    freeze: true,
    minutes: 50,
    how:
        'Trita il tacchino con il parmigiano e forma le polpette. Cuocile '
        'nel sugo per 20 minuti. Prepara il purè con patate lesse e latte.',
  ),
  _r(
    'r_lenticchie',
    'Lenticchie in umido con riso integrale',
    _main,
    {
      'f_lenticchie': 70,
      'f_riso_int': 60,
      'f_carote': 50,
      'f_cipolla': 30,
      'f_passata': 100,
      'f_olio': 10,
    },
    protein: 'legumi',
    fridge: 5,
    freeze: true,
    minutes: 45,
    how:
        'Soffriggi carota e cipolla, aggiungi lenticchie, passata e acqua. '
        'Cuoci 30-35 minuti. Servi con il riso integrale.',
  ),
  _r(
    'r_maiale',
    'Lonza al forno con patate dolci e fagiolini',
    _main,
    {'f_lonza': 150, 'f_patate_dolci': 250, 'f_fagiolini': 150, 'f_olio': 10},
    protein: 'maiale',
    fridge: 4,
    minutes: 45,
    how:
        'Cuoci la lonza in forno a 190°C per 30 minuti insieme alle patate '
        'dolci a cubetti. Lessa o cuoci al vapore i fagiolini.',
  ),
  _r(
    'r_wrap_pollo',
    'Wrap di pollo, avocado e verdure',
    _main,
    {
      'f_tortilla': 70,
      'f_pollo': 120,
      'f_avocado': 40,
      'f_insalata': 40,
      'f_pomodorini': 60,
      'f_yogurt_greco': 40,
    },
    protein: 'pollo',
    fridge: 2,
    minutes: 20,
    how:
        'Griglia il pollo a straccetti. Farcisci la tortilla con salsa di '
        'yogurt, insalata, pomodorini, avocado e pollo.',
  ),
  _r(
    'r_pasta_tonno',
    'Pasta con tonno e pomodorini',
    _main,
    {
      'f_pasta': 90,
      'f_tonno': 100,
      'f_pomodorini': 150,
      'f_rucola': 20,
      'f_olio': 10,
    },
    protein: 'pesce',
    fridge: 3,
    minutes: 20,
    how:
        'Salta i pomodorini con olio e aglio, aggiungi il tonno e la pasta '
        'al dente. Completa con la rucola.',
  ),
  _r(
    'r_tofu',
    'Tofu saltato con edamame, broccoli e riso',
    _main,
    {
      'f_tofu': 150,
      'f_edamame': 80,
      'f_riso': 80,
      'f_broccoli': 120,
      'f_soia': 15,
      'f_olio': 8,
    },
    protein: 'legumi',
    fridge: 4,
    minutes: 30,
    how:
        'Rosola il tofu a cubetti finché è croccante. Aggiungi broccoli ed '
        'edamame, sfuma con la salsa di soia. Servi con il riso.',
  ),
  _r(
    'r_straccetti',
    'Straccetti di manzo, rucola e grana con patate',
    _main,
    {
      'f_manzo': 150,
      'f_rucola': 40,
      'f_parmigiano': 15,
      'f_patate': 250,
      'f_olio': 10,
    },
    protein: 'manzo',
    fridge: 3,
    minutes: 35,
    how:
        'Patate al forno a 200°C per 30 minuti. Scotta gli straccetti in '
        'padella e servili su rucola e scaglie di grana.',
  ),

  // Spuntini
  _r(
    'r_skyr_mela',
    'Skyr con mela e mandorle',
    _s,
    {'f_skyr': 170, 'f_mela': 150, 'f_mandorle': 15},
    protein: 'latticini',
    fridge: 2,
    minutes: 3,
  ),
  _r(
    'r_gallette_bresaola',
    'Gallette con bresaola',
    _s,
    {'f_gallette': 32, 'f_bresaola': 50},
    protein: 'carne',
    fridge: 1,
    minutes: 2,
  ),
  _r(
    'r_banana_pb',
    "Banana e burro d'arachidi",
    _s,
    {'f_banana': 120, 'f_burro_arachidi': 20},
    protein: 'vegetale',
    fridge: 1,
    minutes: 2,
  ),
  _r(
    'r_shake',
    'Shake proteico con latte e banana',
    _s,
    {'f_whey': 30, 'f_latte': 250, 'f_banana': 100},
    protein: 'latticini',
    fridge: 1,
    minutes: 3,
  ),
  _r(
    'r_fiocchi_datteri',
    'Fiocchi di latte con datteri e noci',
    _s,
    {'f_fiocchi_latte': 150, 'f_datteri': 30, 'f_noci': 10},
    protein: 'latticini',
    fridge: 2,
    minutes: 3,
  ),
];
