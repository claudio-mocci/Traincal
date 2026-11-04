"""Colazioni meal prep: avena, chia, yogurt, pancake, lievitati proteici,
frittatine al forno e toast."""

from engine import BREAKFAST, Template, opt
from lib import NUTS_WHOLE, fruit, nuts, veg

# --- Helper locali -----------------------------------------------------------

_BOSCO_FROZEN = 'usa i frutti di bosco ancora surgelati'


def fr(keys, grams, **cut):
    """Frutta dalla libreria con grammi uniformi e `cut` ritoccati."""
    out = fruit(keys, grams)
    for o in out:
        if o.key in cut:
            o.attrs['cut'] = cut[o.key]
    return out


# Frutta fresca da mangiare cruda (bowl, oats, toppings).
FRESH = ['banana', 'mela', 'pera', 'kiwi', 'arancia', 'mandarini', 'cachi', 'melograno', 'uva',
         'fichi', 'fragole', 'ciliegie', 'albicocche', 'pesche', 'prugne', 'mirtilli', 'lamponi',
         'frutti_bosco']
# Frutta che regge la cottura in forno.
BAKE = ['mela', 'pera', 'banana', 'albicocche', 'pesche', 'prugne', 'ciliegie', 'mirtilli',
        'lamponi', 'fichi', 'frutti_bosco']

MILKS = [
    opt('latte', 'latte', {'f_latte': 150}, the='il latte', al='al latte'),
    opt('soia', 'bevanda di soia', {'f_bevanda_soia': 150}, the='la bevanda di soia',
        al='alla bevanda di soia'),
    opt('kefir', 'kefir', {'f_kefir': 150}, the='il kefir', al='al kefir'),
]

# Frutta secca per la granola: "granola alle mandorle".
GRANOLA_NUTS = [
    opt('mandorle', 'mandorle', {'f_mandorle': 15}, the='le mandorle', chop=' e trita grossolanamente le mandorle', alle='alle mandorle'),
    opt('nocciole', 'nocciole', {'f_nocciole': 15}, the='le nocciole', chop=' e trita grossolanamente le nocciole', alle='alle nocciole'),
    opt('noci', 'noci', {'f_noci': 15}, the='le noci', chop=' e trita grossolanamente le noci', alle='alle noci'),
    opt('pistacchi', 'pistacchi', {'f_pistacchi': 15}, the='i pistacchi', chop=' e trita grossolanamente i pistacchi', alle='ai pistacchi'),
    opt('anacardi', 'anacardi', {'f_anacardi': 15}, the='gli anacardi', chop=' e trita grossolanamente gli anacardi', alle='agli anacardi'),
    opt('semi_zucca', 'semi di zucca', {'f_semi_zucca': 15}, the='i semi di zucca', chop='',
        alle='ai semi di zucca'),
]

YOG = [
    opt('greco', 'yogurt greco', {'f_yogurt_greco': 200}, protein='latticini', the='lo yogurt greco'),
    opt('skyr', 'skyr', {'f_skyr': 200}, protein='latticini', the='lo skyr'),
]

# Aggiunte per lievitati: "con noci" / "le noci tritate".
BAKE_ADD = [
    opt('noci', 'noci', {'f_noci': 10}, the='le noci tritate'),
    opt('mandorle', 'mandorle', {'f_mandorle': 10}, the='le mandorle tritate'),
    opt('nocciole', 'nocciole', {'f_nocciole': 10}, the='le nocciole tritate'),
    opt('pistacchi', 'pistacchi', {'f_pistacchi': 10}, the='i pistacchi tritati'),
    opt('cioccolato', 'cioccolato fondente', {'f_cioccolato': 10}, the='il cioccolato a scaglie'),
]


def _ex_fruit(*keys):
    return lambda c: c['f'].key in keys


TEMPLATES = [
    # --- Avena ----------------------------------------------------------------
    Template(
        key='b_overnight_oats', type=BREAKFAST, protein='latticini',
        name='Overnight oats {l.al} con {f.label} e {n.label}',
        base={'f_avena': 50, 'f_chia': 10, 'f_yogurt_greco': 100, 'f_cannella': 1},
        slots={'l': MILKS, 'f': fr(FRESH, 120), 'n': nuts(NUTS_WHOLE + ['burro_arachidi', 'crema_mandorle'], 12)},
        steps=[
            "In un barattolo mescola i fiocchi d'avena, i semi di chia e la cannella.",
            'Aggiungi lo yogurt greco e {l.the}, mescola bene, chiudi e lascia in frigo per almeno 6 ore (meglio tutta la notte).',
            '{f.cut}.',
            'Al momento di servire mescola, aggiungi un goccio di {l.label} se è troppo denso e completa con {f.the} e {n.the}.',
        ],
        fridge=3, minutes=10, tags=['avena', 'senza cottura'], max=20,
    ),
    Template(
        key='b_oats_proteici', type=BREAKFAST, protein='latticini',
        name='Overnight oats proteici {s.label} con {f.label}',
        base={'f_avena': 50, 'f_latte': 180, 'f_whey': 20, 'f_chia': 5},
        slots={
            's': [
                opt('cacao', 'al cacao', {'f_cacao': 8}, the='il cacao'),
                opt('arachidi', "al burro d'arachidi", {'f_burro_arachidi': 12}, the="il burro d'arachidi"),
                opt('cocco', 'al cocco', {'f_cocco_rape': 8}, the='il cocco rapé'),
                opt('cannella', 'alla cannella', {'f_cannella': 2}, the='la cannella'),
            ],
            'f': fr(FRESH, 120),
        },
        steps=[
            'In un barattolo sciogli le proteine whey nel latte freddo con una frusta, senza lasciare grumi.',
            "Aggiungi i fiocchi d'avena, i semi di chia e {s.the}, mescola bene, chiudi e lascia in frigo per almeno 6 ore.",
            '{f.cut}.',
            'Al momento di servire mescola e completa con {f.the}.',
        ],
        fridge=3, minutes=10, tags=['avena', 'senza cottura', 'proteico'], max=14,
        exclude=lambda c: c['s'].key == 'cocco' and c['f'].key in ('uva', 'melograno'),
    ),
    Template(
        key='b_porridge', type=BREAKFAST, protein='latticini',
        name='Porridge proteico {l.al} con {f.label} e {n.label}',
        base={'f_avena': 50, 'f_whey': 20, 'f_cannella': 1},
        slots={
            'l': [
                opt('latte', 'latte', {'f_latte': 220}, the='il latte', al='al latte'),
                opt('soia', 'bevanda di soia', {'f_bevanda_soia': 220}, the='la bevanda di soia',
                    al='alla bevanda di soia'),
            ],
            'f': fr(['banana', 'mela', 'pera', 'cachi', 'kiwi', 'melograno', 'fichi', 'prugne', 'uva',
                     'mirtilli', 'lamponi', 'frutti_bosco', 'fragole', 'mandarini'], 110),
            'n': nuts(NUTS_WHOLE + ['burro_arachidi', 'crema_mandorle'], 12),
        },
        steps=[
            "Porta {l.the} a leggero bollore in un pentolino, aggiungi i fiocchi d'avena e la cannella e cuoci a fuoco basso per 5 minuti, mescolando, finché diventa cremoso.",
            'Togli dal fuoco, fai intiepidire 1 minuto e incorpora le proteine whey sciolte in 2 cucchiai d\'acqua.',
            '{f.cut}.',
            'Dividi nei contenitori; al momento di servire scalda 1-2 minuti al microonde con un goccio di {l.label} e completa con {f.the} e {n.the}.',
        ],
        fridge=3, minutes=15, tags=['avena', 'caldo', 'proteico'], max=18,
    ),
    Template(
        key='b_budino_avena', type=BREAKFAST, protein='latticini',
        name='Budino proteico di avena {s.label} con {f.label}',
        base={'f_avena': 40, 'f_latte': 250, 'f_whey': 25, 'f_miele': 6},
        slots={
            's': [
                opt('cacao', 'al cacao', {'f_cacao': 10}, mix='e il cacao'),
                opt('cannella', 'alla cannella', {'f_cannella': 2}, mix='e la cannella'),
                opt('cocco', 'al cocco', {'f_cocco_rape': 8}, mix='e il cocco rapé'),
            ],
            'f': fr(FRESH, 100),
        },
        steps=[
            "Frulla i fiocchi d'avena fino a ridurli in farina fine.",
            "In un pentolino stempera la farina d'avena {s.mix} nel latte freddo, porta a bollore e cuoci a fuoco basso per 5-6 minuti, mescolando con una frusta, finché si addensa.",
            'Togli dal fuoco, fai intiepidire 2 minuti e incorpora con la frusta le proteine whey e il miele.',
            'Versa in coppette o barattoli, copri e fai rassodare in frigo per almeno 3 ore.',
            '{f.cut}; al momento di servire completa il budino con {f.the}.',
        ],
        fridge=3, minutes=15, tags=['avena', 'proteico'], max=12,
        exclude=lambda c: c['s'].key == 'cocco' and c['f'].key in ('uva', 'melograno', 'mandarini'),
    ),
    Template(
        key='b_baked_oats', type=BREAKFAST, protein='latticini',
        name='Baked oats con {f.label} e {x.label}',
        base={'f_avena': 50, 'f_yogurt_greco': 80, 'f_albume': 60, 'f_latte': 80, 'f_lievito': 2,
              'f_cannella': 1},
        slots={
            'f': fr(BAKE, 90, frutti_bosco=_BOSCO_FROZEN),
            'x': [
                opt('cacao', 'cacao', {'f_cacao': 8}, the='il cacao'),
                opt('arachidi', "burro d'arachidi", {'f_burro_arachidi': 12}, the="il burro d'arachidi"),
                opt('mandorle', 'mandorle', {'f_mandorle': 12}, the='le mandorle tritate'),
                opt('noci', 'noci', {'f_noci': 12}, the='le noci tritate'),
                opt('nocciole', 'nocciole', {'f_nocciole': 12}, the='le nocciole tritate'),
            ],
        },
        steps=[
            'Scalda il forno a 180 °C.',
            "Frulla i fiocchi d'avena con lo yogurt greco, gli albumi, il latte, il lievito, la cannella e {x.the} fino a ottenere una pastella liscia.",
            '{f.cut}.',
            'Versa la pastella in una pirofila monoporzione, distribuisci sopra la frutta premendola leggermente e cuoci per 22-25 minuti, finché è gonfia e asciutta al centro.',
            'Fai intiepidire 5 minuti prima di servire; si mangia anche fredda o scaldata 1 minuto al microonde.',
        ],
        fridge=4, freeze=True, minutes=35, tags=['avena', 'forno'], max=14,
    ),
    Template(
        key='b_porridge_salato', type=BREAKFAST,
        name='Porridge salato con {v.label} e {p.label}',
        base={'f_avena': 50, 'f_brodo': 250, 'f_parmigiano': 10, 'f_olio': 5},
        slots={
            'v': veg(['spinaci', 'funghi', 'zucchine', 'porri', 'cavolo_nero', 'zucca', 'bietole',
                      'asparagi'], 100),
            'p': [
                opt('uovo', 'uovo sodo', {'f_uova': 55}, protein='uova', the="l'uovo a spicchi",
                    prep="Rassoda l'uovo in acqua bollente per 9 minuti, raffreddalo in acqua fredda e sgusciolo."),
                opt('cotto', 'prosciutto cotto', {'f_prosciutto_cotto': 50}, protein='maiale',
                    the='il prosciutto cotto a listarelle', prep=''),
                opt('feta', 'feta', {'f_feta': 35}, protein='latticini', the='la feta sbriciolata', prep=''),
            ],
        },
        steps=[
            '{p.prep}',
            "{v.cut}, poi scalda l'olio in un pentolino e salta{v.pron} per {v.saute} minuti.",
            "Aggiungi i fiocchi d'avena e il brodo caldo e cuoci a fuoco basso per 6-7 minuti, mescolando, finché diventa cremoso.",
            'Spegni, manteca con il parmigiano e dividi nei contenitori.',
            'Al momento di servire scalda 2 minuti al microonde con un goccio di brodo o acqua e completa con {p.the} e pepe nero.',
        ],
        fridge=3, minutes=20, tags=['avena', 'salato', 'caldo'], max=10,
    ),

    # --- Chia e yogurt ----------------------------------------------------------
    Template(
        key='b_chia_pudding', type=BREAKFAST, protein='latticini',
        name='Chia pudding {s.label} con {f.label}',
        base={'f_chia': 30, 'f_latte': 200, 'f_yogurt_greco': 125, 'f_miele': 8},
        slots={
            's': [
                opt('cacao', 'al cacao', {'f_cacao': 6}, mix='il cacao'),
                opt('cocco', 'al cocco', {'f_cocco_rape': 8}, mix='il cocco rapé'),
                opt('cannella', 'alla cannella', {'f_cannella': 2}, mix='la cannella'),
            ],
            'f': fr(FRESH, 110),
        },
        steps=[
            'In un barattolo mescola i semi di chia con il latte, il miele e {s.mix}.',
            'Dopo 10 minuti mescola di nuovo per sciogliere i grumi, chiudi e lascia in frigo per almeno 4 ore (meglio tutta la notte).',
            '{f.cut}.',
            'Al momento di servire copri il pudding con lo yogurt greco e completa con {f.the}.',
        ],
        fridge=3, minutes=10, tags=['chia', 'senza cottura'], max=14,
        exclude=lambda c: c['s'].key == 'cocco' and c['f'].key in ('uva', 'melograno', 'mandarini'),
    ),
    Template(
        key='b_yogurt_granola', type=BREAKFAST,
        name='Bowl di {y.label} con granola {n.alle} e {f.label}',
        base={'f_avena': 30, 'f_miele': 8, 'f_olio': 3, 'f_cannella': 1},
        slots={'y': YOG, 'n': GRANOLA_NUTS, 'f': fr(FRESH, 120)},
        steps=[
            'Scalda il forno a 160 °C{n.chop}.',
            "Mescola i fiocchi d'avena con {n.the}, il miele, l'olio e la cannella finché sono ben ricoperti.",
            'Stendi su una teglia con carta forno e cuoci per 15-18 minuti, mescolando a metà cottura, finché la granola è dorata; fai raffreddare: diventerà croccante.',
            '{f.cut}.',
            'Componi la bowl al momento con {y.the}, {f.the} e la granola, che va conservata a parte in un barattolo.',
        ],
        fridge=2, minutes=25, tags=['yogurt', 'granola'], max=18,
    ),
    Template(
        key='b_composta', type=BREAKFAST,
        name='{y.label} con composta di {f.pl} e {n.label}',
        base={'f_miele': 6, 'f_cannella': 1},
        slots={
            'y': [
                opt('greco', 'yogurt greco', {'f_yogurt_greco': 200}, protein='latticini', the='lo yogurt greco'),
                opt('skyr', 'skyr', {'f_skyr': 200}, protein='latticini', the='lo skyr'),
            ],
            'f': [
                opt('mela', 'mela', {'f_mela': 150}, pl='mele', the='la mela',
                    cut='sbuccia la mela e tagliala a cubetti', cook=10),
                opt('pera', 'pera', {'f_pera': 150}, pl='pere', the='la pera',
                    cut='sbuccia la pera e tagliala a cubetti', cook=8),
                opt('prugne', 'prugne', {'f_prugne': 150}, pl='prugne', the='le prugne',
                    cut='snocciola le prugne e tagliale a spicchi', cook=8),
                opt('albicocche', 'albicocche', {'f_albicocche': 150}, pl='albicocche', the='le albicocche',
                    cut='snocciola le albicocche e tagliale a spicchi', cook=6),
                opt('ciliegie', 'ciliegie', {'f_ciliegie': 150}, pl='ciliegie', the='le ciliegie',
                    cut='snocciola le ciliegie', cook=8),
                opt('fragole', 'fragole', {'f_fragole': 150}, pl='fragole', the='le fragole',
                    cut='lava le fragole e tagliale in quarti', cook=6),
                opt('pesche', 'pesche', {'f_pesche': 150}, pl='pesche', the='le pesche',
                    cut='sbuccia le pesche e tagliale a cubetti', cook=6),
                opt('fichi', 'fichi', {'f_fichi': 130}, pl='fichi', the='i fichi',
                    cut='taglia i fichi in quarti', cook=6),
                opt('cachi', 'cachi', {'f_cachi': 150}, pl='cachi', the='il caco',
                    cut='sbuccia il caco e taglialo a cubetti', cook=5),
                opt('bosco', 'frutti di bosco', {'f_frutti_bosco': 150}, pl='frutti di bosco',
                    the='i frutti di bosco', cut='usa i frutti di bosco surgelati, senza scongelarli', cook=8),
            ],
            'n': nuts(NUTS_WHOLE, 20),
        },
        steps=[
            '{f.cut}.',
            "Cuoci la frutta in un pentolino con il miele, la cannella e 2 cucchiai d'acqua a fuoco dolce per {f.cook} minuti, mescolando, finché si ammorbidisce e il fondo si addensa.",
            'Fai raffreddare la composta e trasferiscila in un barattolo.',
            'Al momento di servire versa {y.the} in una ciotola, aggiungi la composta e completa con {n.the}.',
        ],
        fridge=4, minutes=20, tags=['yogurt'], max=12,
    ),
    Template(
        key='b_smoothie_bowl', type=BREAKFAST,
        name='Smoothie bowl di banana e {f.label} con {y.label} e {n.label}',
        base={'f_banana': 100, 'f_latte': 60, 'f_chia': 5},
        slots={
            'f': fr(['frutti_bosco', 'fragole', 'mirtilli', 'lamponi', 'pesche', 'albicocche',
                     'ciliegie', 'kiwi', 'cachi', 'pera', 'mela', 'prugne'], 120,
                    frutti_bosco=_BOSCO_FROZEN),
            'y': [
                opt('skyr', 'skyr', {'f_skyr': 150}, protein='latticini', the='lo skyr'),
                opt('greco', 'yogurt greco', {'f_yogurt_greco': 150}, protein='latticini', the='lo yogurt greco'),
            ],
            'n': nuts(['mandorle', 'pistacchi', 'nocciole', 'semi_zucca', 'noci', 'burro_arachidi'], 15),
        },
        steps=[
            '{f.cut}; taglia la banana a rondelle e congela tutta la frutta in un sacchetto per almeno 4 ore.',
            'Frulla la frutta congelata con {y.the} e il latte per 1-2 minuti, fermandoti a raschiare le pareti, finché ottieni una crema densa.',
            'Versa nella ciotola e completa con {n.the} e i semi di chia.',
        ],
        fridge=1, freeze=True, minutes=10, tags=['frullato', 'senza cottura'], max=12,
    ),

    # --- Pancake e crêpes -------------------------------------------------------
    Template(
        key='b_pancake', type=BREAKFAST, protein='uova',
        name='Pancake proteici {b.label} con {f.label} e {t.label}',
        base={'f_uova': 55, 'f_albume': 100, 'f_lievito': 3, 'f_cannella': 1, 'f_olio': 3},
        slots={
            'b': [
                opt('avena', "d'avena", {'f_avena': 50},
                    mix="Frulla i fiocchi d'avena fino a ottenere una farina"),
                opt('cacao', 'al cacao', {'f_avena': 45, 'f_cacao': 8},
                    mix="Frulla i fiocchi d'avena con il cacao fino a ottenere una farina"),
                opt('banana', 'alla banana', {'f_avena': 40, 'f_banana': 60},
                    mix="Frulla i fiocchi d'avena fino a ottenere una farina, poi aggiungi la banana a pezzi"),
            ],
            'f': fr(['mela', 'pera', 'kiwi', 'arancia', 'cachi', 'fichi', 'fragole', 'ciliegie',
                     'albicocche', 'pesche', 'prugne', 'mirtilli', 'lamponi', 'frutti_bosco', 'banana'], 100),
            't': [
                opt('yogurt', 'yogurt greco al miele', {'f_yogurt_greco': 100, 'f_miele': 8},
                    the='lo yogurt greco mescolato al miele'),
                opt('arachidi', "burro d'arachidi", {'f_burro_arachidi': 15}, the="il burro d'arachidi"),
                opt('mandorle', 'crema di mandorle', {'f_crema_mandorle': 15}, the='la crema di mandorle'),
                opt('ricotta', 'ricotta', {'f_ricotta': 60, 'f_miele': 5}, the='la ricotta lavorata con il miele'),
            ],
        },
        steps=[
            "{b.mix}; unisci l'uovo, gli albumi, il lievito e la cannella e frulla ancora 30 secondi. Lascia riposare l'impasto 5 minuti.",
            "Scalda a fuoco medio una padella antiaderente unta con l'olio, versa un mestolino di impasto per volta e cuoci 2 minuti, finché compaiono bollicine in superficie; gira e cuoci 1 minuto ancora.",
            '{f.cut}.',
            'Servi i pancake con {f.the} e {t.the}. Per il meal prep conserva i pancake a parte e scaldali 1 minuto in padella o nel tostapane.',
        ],
        fridge=3, freeze=True, minutes=20, tags=['pancake', 'proteico'], max=18,
        exclude=lambda c: (c['b'].key == 'banana' and c['f'].key == 'banana')
        or (c['t'].key == 'ricotta' and c['f'].key in ('kiwi', 'arancia')),
    ),
    Template(
        key='b_crepes', type=BREAKFAST, protein='latticini',
        name='Crêpes proteiche con {r.label} e {f.label}',
        base={'f_farina': 30, 'f_uova': 55, 'f_albume': 60, 'f_latte': 80, 'f_olio': 3},
        slots={
            'r': [
                opt('ricotta', 'ricotta', {'f_ricotta': 80, 'f_miele': 6},
                    the='la ricotta lavorata con il miele'),
                opt('skyr', 'skyr', {'f_skyr': 120, 'f_miele': 6}, the='lo skyr mescolato al miele'),
                opt('yogurt', 'yogurt greco', {'f_yogurt_greco': 120, 'f_cannella': 1, 'f_miele': 6},
                    the='lo yogurt greco mescolato a miele e cannella'),
            ],
            'f': fr(['fragole', 'frutti_bosco', 'mirtilli', 'lamponi', 'banana', 'pesche', 'albicocche',
                     'pera', 'mela', 'fichi', 'cachi', 'ciliegie', 'prugne'], 100),
        },
        steps=[
            "Sbatti l'uovo con gli albumi, poi incorpora a filo il latte e la farina setacciata fino a ottenere una pastella liscia; lasciala riposare 15 minuti.",
            "Scalda una padella antiaderente da 22 cm unta con un velo d'olio, versa un mestolino di pastella ruotando la padella e cuoci 1 minuto per lato; ripeti fino a finire la pastella (2-3 crêpes).",
            '{f.cut}.',
            'Farcisci le crêpes con {r.the}, aggiungi {f.the} e chiudile a ventaglio. Per il meal prep conserva le crêpes vuote, separate da carta forno, e farciscile al momento.',
        ],
        fridge=3, freeze=True, minutes=30, tags=['crêpes'], max=12,
    ),

    # --- Lievitati da forno -----------------------------------------------------
    Template(
        key='b_muffin', type=BREAKFAST, protein='latticini',
        name='Muffin proteici allo yogurt con {f.label} e {n.label}',
        base={'f_farina_int': 35, 'f_whey': 15, 'f_yogurt_greco': 80, 'f_uova': 30, 'f_latte': 30,
              'f_miele': 10, 'f_olio': 5, 'f_lievito': 3, 'f_cannella': 1},
        slots={
            'f': fr(['mirtilli', 'lamponi', 'frutti_bosco', 'mela', 'pera', 'albicocche', 'ciliegie',
                     'prugne', 'banana', 'pesche'], 60,
                    frutti_bosco=_BOSCO_FROZEN, mela='sbuccia la mela e tagliala a cubetti piccoli',
                    pesche='taglia le pesche a cubetti piccoli',
                    albicocche='snocciola le albicocche e tagliale a cubetti',
                    prugne='snocciola le prugne e tagliale a cubetti'),
            'n': BAKE_ADD,
        },
        steps=[
            'Scalda il forno a 180 °C (statico) e prepara uno stampo da muffin con i pirottini.',
            "In una ciotola sbatti l'uovo con lo yogurt greco, il latte, il miele e l'olio.",
            'Unisci la farina integrale, le proteine whey, il lievito e la cannella setacciati e mescola solo finché l\'impasto è omogeneo.',
            "{f.cut}, poi incorpora delicatamente all'impasto la frutta e {n.the}.",
            'Distribuisci nei pirottini (2 muffin a porzione) e cuoci per 20-22 minuti, finché lo stecchino esce asciutto; fai raffreddare su una gratella.',
        ],
        fridge=4, freeze=True, minutes=35, tags=['muffin', 'forno', 'proteico'], max=14,
    ),
    Template(
        key='b_banana_bread', type=BREAKFAST, protein='latticini',
        name='Banana bread proteico {v.label} con {n.label}',
        base={'f_banana': 80, 'f_avena': 40, 'f_uova': 40, 'f_yogurt_greco': 50, 'f_whey': 10,
              'f_miele': 5, 'f_lievito': 3, 'f_cannella': 1},
        slots={
            'v': [
                opt('classico', 'classico', {}, add='', fold=''),
                opt('cacao', 'al cacao', {'f_cacao': 6}, add=' e il cacao', fold=''),
                opt('bosco', 'ai frutti di bosco', {'f_frutti_bosco': 40}, add='', fold=' e i frutti di bosco ancora surgelati'),
                opt('mirtilli', 'ai mirtilli', {'f_mirtilli': 40}, add='', fold=' e i mirtilli lavati'),
                opt('mela', 'alla mela', {'f_mela': 50}, add='', fold=' e la mela sbucciata e tagliata a cubetti'),
            ],
            'n': BAKE_ADD,
        },
        steps=[
            'Scalda il forno a 175 °C e fodera uno stampo da plumcake con carta forno.',
            "Frulla i fiocchi d'avena fino a ottenere una farina e mescolala con le proteine whey, il lievito, la cannella{v.add}.",
            "In un'altra ciotola schiaccia la banana con una forchetta e uniscila all'uovo sbattuto, allo yogurt greco e al miele.",
            'Unisci i due composti, poi incorpora {n.the}{v.fold}.',
            'Versa nello stampo e cuoci per 40-45 minuti, finché lo stecchino esce asciutto; fai raffreddare prima di tagliare a fette.',
        ],
        fridge=4, freeze=True, minutes=60, tags=['forno', 'proteico'], max=10,
        exclude=lambda c: c['v'].key == 'cacao' and c['n'].key == 'cioccolato',
    ),
    Template(
        key='b_plumcake', type=BREAKFAST, protein='latticini',
        name='Plumcake allo yogurt e {x.label} con {f.label}',
        base={'f_farina': 40, 'f_yogurt_greco': 80, 'f_uova': 35, 'f_whey': 10, 'f_miele': 10,
              'f_olio': 7, 'f_lievito': 3},
        slots={
            'x': [
                opt('limone', 'limone', {'f_limone': 5}, add='la scorza grattugiata del limone'),
                opt('cannella', 'cannella', {'f_cannella': 2}, add='la cannella'),
                opt('cacao', 'cacao', {'f_cacao': 8}, add='il cacao'),
                opt('cocco', 'cocco', {'f_cocco_rape': 10}, add='il cocco rapé'),
            ],
            'f': fr(['mela', 'pera', 'albicocche', 'prugne', 'ciliegie', 'pesche', 'mirtilli',
                     'frutti_bosco', 'fichi', 'lamponi'], 60,
                    frutti_bosco=_BOSCO_FROZEN, mela='sbuccia la mela e tagliala a cubetti',
                    pera='sbuccia la pera e tagliala a cubetti'),
        },
        steps=[
            'Scalda il forno a 170 °C e fodera uno stampo da plumcake con carta forno.',
            "Sbatti l'uovo con il miele per 2 minuti, poi aggiungi lo yogurt greco e l'olio.",
            'Incorpora la farina, le proteine whey, il lievito e {x.add}, mescolando finché l\'impasto è liscio.',
            '{f.cut}; infarina leggermente la frutta e incorporala all\'impasto.',
            'Versa nello stampo e cuoci per 40-45 minuti, finché lo stecchino esce asciutto; fai raffreddare prima di tagliare a fette.',
        ],
        fridge=4, freeze=True, minutes=60, tags=['forno'], max=12,
        exclude=lambda c: (c['x'].key == 'limone' and c['f'].key in ('fichi', 'prugne'))
        or (c['x'].key == 'cocco' and c['f'].key in ('fichi', 'prugne', 'pera')),
    ),

    # --- Salati: uova, toast, fiocchi di latte -----------------------------------
    Template(
        key='b_frittatine', type=BREAKFAST,
        name='Frittatine al forno con {v.label} e {p.label}',
        base={'f_uova': 110, 'f_albume': 100, 'f_olio': 3, 'f_pane_int': 50},
        slots={
            'v': veg(['zucchine', 'spinaci', 'peperoni', 'asparagi', 'funghi', 'pomodorini', 'broccoli',
                      'porri', 'zucca', 'bietole', 'piselli_freschi', 'carciofi'], 100),
            'p': [
                opt('cotto', 'prosciutto cotto', {'f_prosciutto_cotto': 40}, protein='uova',
                    the='il prosciutto cotto a dadini'),
                opt('crudo', 'prosciutto crudo', {'f_prosciutto_crudo': 30}, protein='uova',
                    the='il prosciutto crudo a listarelle'),
                opt('feta', 'feta', {'f_feta': 30}, protein='uova', the='la feta sbriciolata'),
                opt('parmigiano', 'parmigiano', {'f_parmigiano': 15}, protein='uova',
                    the='il parmigiano grattugiato'),
                opt('salmone', 'salmone affumicato', {'f_salmone_affumicato': 40}, protein='uova',
                    the='il salmone affumicato a pezzetti'),
            ],
        },
        steps=[
            "Scalda il forno a 180 °C e ungi uno stampo da muffin con l'olio.",
            '{v.cut}; salta{v.pron} in padella antiaderente con un pizzico di sale per {v.saute} minuti e fai intiepidire.',
            'Sbatti le uova con gli albumi, sale e pepe; unisci {v.the} e {p.the}.',
            'Distribuisci il composto in 4 stampini e cuoci per 18-20 minuti, finché le frittatine sono gonfie e rapprese.',
            'Servi con il pane integrale tostato; per il meal prep scaldale 1 minuto al microonde.',
        ],
        fridge=4, freeze=True, minutes=35, tags=['uova', 'salato', 'forno'], max=16,
        exclude=lambda c: c['p'].key == 'salmone' and c['v'].key in (
            'peperoni', 'funghi', 'zucca', 'broccoli', 'pomodorini', 'carciofi', 'bietole'),
    ),
    Template(
        key='b_toast_salato', type=BREAKFAST,
        name='Toast integrale con {p.label} e {v.label}',
        base={'f_pane_int': 70},
        slots={
            'p': [
                opt('uova', 'uova sode', {'f_uova': 110}, protein='uova', the='le uova a fette',
                    prep="Rassoda le uova in acqua bollente per 9 minuti, raffreddale in acqua fredda e sgusciale.", spread=''),
                opt('salmone', 'salmone affumicato', {'f_salmone_affumicato': 60, 'f_spalmabile': 20},
                    protein='pesce', the='il salmone affumicato', prep='', spread='Spalma il formaggio spalmabile sul pane.'),
                opt('bresaola', 'bresaola', {'f_bresaola': 50, 'f_spalmabile': 20}, protein='manzo',
                    the='la bresaola', prep='', spread='Spalma il formaggio spalmabile sul pane.'),
                opt('crudo', 'prosciutto crudo', {'f_prosciutto_crudo': 50}, protein='maiale',
                    the='il prosciutto crudo', prep='', spread=''),
            ],
            'v': [
                opt('avocado', 'avocado', {'f_avocado': 50, 'f_limone': 5}, the="l'avocado",
                    prep="Schiaccia la polpa dell'avocado con il succo di limone e un pizzico di sale."),
                opt('pomodorini', 'pomodorini', {'f_pomodorini': 100, 'f_olio': 4}, the='i pomodorini',
                    prep="Taglia i pomodorini a spicchi e condiscili con l'olio e un pizzico di sale."),
                opt('rucola', 'rucola', {'f_rucola': 25, 'f_olio': 4}, the='la rucola',
                    prep="Lava la rucola e condiscila con l'olio e un pizzico di sale."),
                opt('zucchine', 'zucchine grigliate', {'f_zucchine': 120, 'f_olio': 4}, the='le zucchine',
                    prep="Taglia le zucchine a fette sottili per il lungo e grigliale 2 minuti per lato su una piastra calda; condiscile con l'olio e sale."),
                opt('spinaci', 'spinaci', {'f_spinaci': 120, 'f_olio': 4}, the='gli spinaci',
                    prep="Salta gli spinaci in padella con l'olio e un pizzico di sale per 3 minuti e strizzali."),
                opt('cetrioli', 'cetrioli', {'f_cetrioli': 100, 'f_olio': 3}, the='il cetriolo',
                    prep="Affetta sottilmente il cetriolo e condiscilo con l'olio e un pizzico di sale."),
                opt('valeriana', 'valeriana', {'f_valeriana': 25, 'f_olio': 4}, the='la valeriana',
                    prep="Lava la valeriana e condiscila con l'olio e un pizzico di sale."),
            ],
        },
        steps=[
            '{p.prep}',
            '{v.prep}',
            'Tosta le fette di pane integrale per 2-3 minuti.',
            '{p.spread}',
            'Componi i toast con {v.the} e {p.the}; completa con pepe nero. Per il meal prep prepara i condimenti in anticipo e componi al momento.',
        ],
        fridge=2, minutes=15, tags=['toast', 'salato'], max=16,
        exclude=lambda c: (c['p'].key == 'crudo' and c['v'].key in ('cetrioli', 'spinaci'))
        or (c['p'].key == 'bresaola' and c['v'].key == 'cetrioli'),
    ),
    Template(
        key='b_toast_dolce', type=BREAKFAST, protein='latticini',
        name='Toast integrale con {s.label}, {f.label} e miele',
        base={'f_pane_int': 70, 'f_miele': 8},
        slots={
            's': [
                opt('ricotta', 'ricotta', {'f_ricotta': 100, 'f_cannella': 1},
                    the='la ricotta', prep='Lavora la ricotta con la cannella fino a renderla cremosa.'),
                opt('fiocchi', 'fiocchi di latte', {'f_fiocchi_latte': 130},
                    the='i fiocchi di latte', prep='Sgocciola bene i fiocchi di latte.'),
                opt('greco', 'crema di yogurt greco', {'f_yogurt_greco': 130, 'f_cannella': 1},
                    the='la crema di yogurt greco',
                    prep='Mescola lo yogurt greco con la cannella fino a ottenere una crema densa.'),
            ],
            'f': fr(['fragole', 'fichi', 'pera', 'mela', 'pesche', 'albicocche', 'banana', 'mirtilli',
                     'lamponi', 'kiwi', 'prugne', 'cachi', 'ciliegie'], 100,
                    mela='taglia la mela a fettine sottili', pera='taglia la pera a fettine sottili',
                    banana='taglia la banana a rondelle sottili', fichi='taglia i fichi a fettine'),
        },
        steps=[
            '{s.prep}',
            '{f.cut}.',
            'Tosta le fette di pane integrale per 2-3 minuti.',
            'Spalma {s.the} sul pane, disponi sopra la frutta e completa con un filo di miele. Prepara la crema in anticipo e componi al momento.',
        ],
        fridge=2, minutes=10, tags=['toast'], max=12,
        exclude=lambda c: c['s'].key == 'fiocchi' and c['f'].key in ('kiwi', 'cachi'),
    ),
    Template(
        key='b_fiocchi_bowl', type=BREAKFAST, protein='latticini',
        name='Bowl salata di fiocchi di latte con {v.label} e {c.label}',
        base={'f_fiocchi_latte': 200, 'f_olio': 5, 'f_semi_zucca': 8},
        slots={
            'v': [
                opt('pomodorini', 'pomodorini', {'f_pomodorini': 120}, prep='taglia i pomodorini in quarti'),
                opt('cetrioli', 'cetrioli', {'f_cetrioli': 120}, prep='taglia il cetriolo a cubetti'),
                opt('finocchi', 'finocchi', {'f_finocchi': 120}, prep='affetta sottilmente il finocchio'),
                opt('carote', 'carote', {'f_carote': 100}, prep='pela le carote e grattugiale a julienne'),
                opt('peperoni', 'peperoni', {'f_peperoni': 120}, prep='taglia il peperone a listarelle sottili'),
                opt('avocado', 'avocado', {'f_avocado': 60, 'f_limone': 5},
                    prep="taglia l'avocado a cubetti e bagnalo con il succo di limone"),
            ],
            'c': [
                opt('pane', 'pane integrale', {'f_pane_int': 50}, the='il pane integrale tostato'),
                opt('cracker', 'cracker integrali', {'f_crackers': 25}, the='i cracker integrali'),
                opt('gallette', 'gallette di riso', {'f_gallette': 24}, the='le gallette di riso'),
            ],
        },
        steps=[
            'Sgocciola i fiocchi di latte e versali in una ciotola.',
            '{v.prep}.',
            "Aggiungi la verdura ai fiocchi di latte, condisci con l'olio, sale e pepe e completa con i semi di zucca.",
            'Accompagna con {c.the}. Per il meal prep tieni le verdure tagliate in un contenitore a parte e componi al momento.',
        ],
        fridge=2, minutes=10, tags=['salato', 'senza cottura'], max=8,
    ),
]
