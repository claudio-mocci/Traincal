import '../models/recipe.dart';

enum ComponentKind { base, protein, vegetable }

/// Un elemento cucinato in blocco durante il meal prep (una base di
/// carboidrati, una proteina o un contorno di verdure) da combinare con gli
/// altri pasto per pasto.
class MealComponent {
  final ComponentKind kind;
  final String foodId;

  /// Grammi per porzione, da crudo/secco.
  final double grams;

  /// Nome breve usato per comporre il nome del piatto ("farro", "pollo alla
  /// piastra", "zucchine grigliate").
  final String label;
  final String method;
  final int fridgeDays;
  final bool freezable;

  /// Fonte proteica (solo per le proteine), come in [Recipe.mainProtein].
  final String mainProtein;

  /// Condimento incluso nella porzione (olio per verdure e cotture).
  final double oilGrams;

  const MealComponent(
    this.kind,
    this.foodId,
    this.grams,
    this.label,
    this.method, {
    this.fridgeDays = 4,
    this.freezable = false,
    this.mainProtein = '',
    this.oilGrams = 0,
  });

  String get id => 'cmp_${foodId.replaceFirst('f_', '')}';

  /// Il componente come ricetta a sé, per la scheda di preparazione.
  Recipe toRecipe() => Recipe(
    id: id,
    name: label[0].toUpperCase() + label.substring(1),
    type: MealType.main,
    ingredients: [
      Ingredient(foodId, grams),
      if (oilGrams > 0) Ingredient(oilFoodId, oilGrams),
    ],
    instructions: method,
    mainProtein: mainProtein,
    fridgeDays: fridgeDays,
    freezable: freezable,
    prepMinutes: 0,
    tags: const ['componente'],
    source: RecipeSource.builtin,
  );

  static const oilFoodId = 'f_olio';
}

const _b = ComponentKind.base;
const _p = ComponentKind.protein;
const _v = ComponentKind.vegetable;

/// Catalogo dei componenti. La stagionalità delle verdure viene dal
/// database degli alimenti.
const List<MealComponent> mealComponents = [
  // Basi di carboidrati
  MealComponent(
    _b,
    'f_riso',
    75,
    'riso basmati',
    'Lessa il riso in abbondante acqua salata, scolalo al dente e '
        'raffreddalo subito stendendolo su un vassoio.',
  ),
  MealComponent(
    _b,
    'f_riso_int',
    75,
    'riso integrale',
    'Cuoci il riso integrale per 35-40 minuti, scola e raffredda in fretta.',
  ),
  MealComponent(
    _b,
    'f_riso_venere',
    70,
    'riso venere',
    'Cuoci il riso venere per 18 minuti, scola e condisci con un filo d\'olio.',
  ),
  MealComponent(
    _b,
    'f_farro',
    75,
    'farro',
    'Lessa il farro perlato per 25 minuti, scolalo e raffreddalo.',
    fridgeDays: 5,
  ),
  MealComponent(
    _b,
    'f_orzo',
    75,
    'orzo',
    'Lessa l\'orzo perlato per 30 minuti, scolalo e raffreddalo.',
    fridgeDays: 5,
  ),
  MealComponent(
    _b,
    'f_quinoa',
    70,
    'quinoa',
    'Sciacqua la quinoa e cuocila in due volumi d\'acqua per 15 minuti.',
  ),
  MealComponent(
    _b,
    'f_couscous',
    75,
    'cous cous',
    'Copri il cous cous con pari volume di acqua bollente salata, lascia '
        'riposare 5 minuti e sgrana con una forchetta.',
  ),
  MealComponent(
    _b,
    'f_bulgur',
    75,
    'bulgur',
    'Cuoci il bulgur in acqua per 12 minuti, scola e sgrana.',
  ),
  MealComponent(
    _b,
    'f_patate',
    300,
    'patate al forno',
    'Taglia le patate a spicchi e cuocile in forno a 200°C per 35-40 minuti '
        'con rosmarino.',
    oilGrams: 5,
  ),
  MealComponent(
    _b,
    'f_patate_dolci',
    280,
    'patate dolci al forno',
    'Cuoci le patate dolci a cubetti in forno a 200°C per 30 minuti.',
    oilGrams: 5,
  ),

  // Proteine
  MealComponent(
    _p,
    'f_pollo',
    140,
    'pollo alla piastra',
    'Batti leggermente i petti, marinali con limone ed erbe e cuocili alla '
        'piastra 4-5 minuti per lato. Taglia a fette solo al momento.',
    mainProtein: 'pollo',
    freezable: true,
  ),
  MealComponent(
    _p,
    'f_cosce_pollo',
    130,
    'sovracosce di pollo al forno',
    'Cuoci le sovracosce in forno a 200°C per 30 minuti con paprika e aglio.',
    mainProtein: 'pollo',
    freezable: true,
  ),
  MealComponent(
    _p,
    'f_macinato_pollo',
    140,
    'polpette di pollo e tacchino',
    'Impasta il macinato con erbe e un pizzico di sale, forma le polpette e '
        'cuocile in forno a 190°C per 20 minuti.',
    mainProtein: 'pollo',
    freezable: true,
  ),
  MealComponent(
    _p,
    'f_tacchino',
    140,
    'tacchino al limone',
    'Cuoci le fettine di tacchino in padella con limone e salvia.',
    mainProtein: 'tacchino',
    freezable: true,
  ),
  MealComponent(
    _p,
    'f_spezzatino',
    130,
    'spezzatino di manzo',
    'Rosola il manzo a cubetti, sfuma e cuoci coperto a fuoco basso per '
        'un\'ora e mezza con sedano, carota e cipolla.',
    mainProtein: 'manzo',
    freezable: true,
  ),
  MealComponent(
    _p,
    'f_manzo',
    130,
    'straccetti di manzo',
    'Scotta gli straccetti in padella molto calda per 2 minuti. Si '
        'scaldano velocemente senza stracuocerli.',
    mainProtein: 'manzo',
    fridgeDays: 3,
  ),
  MealComponent(
    _p,
    'f_lonza',
    140,
    'lonza al forno',
    'Cuoci la lonza intera in forno a 180°C per 40 minuti, falla riposare '
        'e affettala sottile.',
    mainProtein: 'maiale',
    freezable: true,
  ),
  MealComponent(
    _p,
    'f_salmone',
    130,
    'salmone al forno',
    'Cuoci i filetti in forno a 180°C per 12-15 minuti. Il pesce si '
        'conserva poco: va nei primi giorni.',
    mainProtein: 'pesce',
    fridgeDays: 2,
  ),
  MealComponent(
    _p,
    'f_merluzzo',
    170,
    'merluzzo al cartoccio',
    'Cuoci i filetti al cartoccio con limone e prezzemolo, 15 minuti a 180°C.',
    mainProtein: 'pesce',
    fridgeDays: 2,
  ),
  MealComponent(
    _p,
    'f_orata',
    150,
    'orata al forno',
    'Cuoci i filetti in forno a 180°C per 12 minuti con pomodorini e olive.',
    mainProtein: 'pesce',
    fridgeDays: 2,
  ),
  MealComponent(
    _p,
    'f_trota',
    140,
    'trota salmonata in padella',
    'Cuoci i filetti in padella antiaderente dalla parte della pelle.',
    mainProtein: 'pesce',
    fridgeDays: 2,
  ),
  MealComponent(
    _p,
    'f_gamberi',
    150,
    'gamberi saltati',
    'Salta i gamberi in padella con aglio e prezzemolo per 3 minuti.',
    mainProtein: 'pesce',
    fridgeDays: 2,
  ),
  MealComponent(
    _p,
    'f_uova',
    110,
    'uova sode',
    'Cuoci le uova per 9 minuti, raffreddale in acqua e ghiaccio e '
        'conservale con il guscio.',
    mainProtein: 'uova',
  ),
  MealComponent(
    _p,
    'f_ceci',
    180,
    'ceci speziati al forno',
    'Asciuga i ceci, condiscili con paprika e cumino e tostali in forno a '
        '200°C per 25 minuti.',
    mainProtein: 'legumi',
    fridgeDays: 5,
  ),
  MealComponent(
    _p,
    'f_lenticchie',
    70,
    'lenticchie lessate',
    'Lessa le lenticchie con alloro per 25 minuti, scolale al dente.',
    mainProtein: 'legumi',
    fridgeDays: 5,
    freezable: true,
  ),
  MealComponent(
    _p,
    'f_cannellini',
    180,
    'cannellini all\'uccelletto',
    'Insaporisci i cannellini in padella con salvia e un po\' di passata.',
    mainProtein: 'legumi',
    fridgeDays: 5,
  ),
  MealComponent(
    _p,
    'f_tofu',
    150,
    'tofu croccante',
    'Taglia il tofu a cubetti, marinalo con salsa di soia e cuocilo in forno '
        'a 200°C per 25 minuti.',
    mainProtein: 'vegetale',
    fridgeDays: 5,
  ),
  MealComponent(
    _p,
    'f_tempeh',
    120,
    'tempeh alla piastra',
    'Cuoci il tempeh a fette alla piastra, poi sfumalo con salsa di soia.',
    mainProtein: 'vegetale',
    fridgeDays: 5,
  ),

  // Verdure (olio incluso nella porzione)
  MealComponent(
    _v,
    'f_zucchine',
    180,
    'zucchine grigliate',
    'Griglia le zucchine a fette e condiscile con olio e menta.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_melanzane',
    180,
    'melanzane al forno',
    'Cuoci le melanzane a cubetti in forno a 200°C per 25 minuti.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_peperoni',
    170,
    'peperoni arrostiti',
    'Arrostisci i peperoni in forno, spellali e condiscili.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_fagiolini',
    170,
    'fagiolini lessati',
    'Lessa i fagiolini per 8 minuti e raffreddali in acqua fredda.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_asparagi',
    160,
    'asparagi al vapore',
    'Cuoci gli asparagi al vapore per 6-8 minuti.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_broccoli',
    180,
    'broccoli al vapore',
    'Cuoci le cimette al vapore per 6 minuti: restano croccanti anche '
        'dopo qualche giorno.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_cavolfiore',
    180,
    'cavolfiore arrosto',
    'Arrostisci le cimette in forno a 200°C per 25 minuti con curcuma.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_cavolini',
    160,
    'cavolini al forno',
    'Taglia a metà i cavolini e cuocili in forno a 200°C per 25 minuti.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_zucca',
    200,
    'zucca al forno',
    'Cuoci la zucca a cubetti in forno a 200°C per 25 minuti con salvia.',
    oilGrams: 8,
  ),
  MealComponent(
    _v,
    'f_finocchi',
    180,
    'finocchi gratinati',
    'Cuoci i finocchi a spicchi in forno a 190°C per 30 minuti.',
    oilGrams: 8,
  ),
  MealComponent(
    _v,
    'f_spinaci',
    180,
    'spinaci saltati',
    'Salta gli spinaci in padella con aglio fino a farli appassire.',
    oilGrams: 8,
    fridgeDays: 3,
  ),
  MealComponent(
    _v,
    'f_bietole',
    180,
    'bietole saltate',
    'Lessa le bietole, strizzale e saltale in padella con aglio.',
    oilGrams: 8,
    fridgeDays: 3,
  ),
  MealComponent(
    _v,
    'f_cime_rapa',
    180,
    'cime di rapa saltate',
    'Lessa le cime di rapa e ripassale in padella con aglio e peperoncino.',
    oilGrams: 10,
    fridgeDays: 3,
  ),
  MealComponent(
    _v,
    'f_cavolo_nero',
    150,
    'cavolo nero stufato',
    'Stufa il cavolo nero a listarelle con aglio e un goccio d\'acqua.',
    oilGrams: 8,
  ),
  MealComponent(
    _v,
    'f_carciofi',
    150,
    'carciofi trifolati',
    'Cuoci gli spicchi di carciofo in padella con aglio e prezzemolo.',
    oilGrams: 10,
  ),
  MealComponent(
    _v,
    'f_funghi',
    160,
    'funghi trifolati',
    'Cuoci i funghi a fette in padella con aglio e prezzemolo.',
    oilGrams: 8,
    fridgeDays: 3,
  ),
  MealComponent(
    _v,
    'f_carote',
    160,
    'carote al forno',
    'Cuoci le carote a bastoncini in forno a 200°C per 25 minuti con cumino.',
    oilGrams: 8,
    fridgeDays: 5,
  ),
  MealComponent(
    _v,
    'f_spinaci_surg',
    180,
    'spinaci in padella',
    'Cuoci gli spinaci surgelati in padella con aglio.',
    oilGrams: 8,
    fridgeDays: 3,
  ),
];
