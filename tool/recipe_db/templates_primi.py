"""Primi piatti da meal prep: pasta con sughi di verdura, carne e pesce,
pasta e legumi, pasta al forno e lasagne, risotti e farrotti, cous cous e
bulgur, noodles saltati, pasta fredda."""

from engine import MAIN, Template, opt
from lib import prot, veg

# --- Formati di pasta ---------------------------------------------------------

SHAPES = {
    'penne': ('penne', 'le penne', 'le', 'f_pasta'),
    'penne_int': ('penne integrali', 'le penne', 'le', 'f_pasta_int'),
    'fusilli': ('fusilli', 'i fusilli', 'li', 'f_pasta'),
    'fusilli_int': ('fusilli integrali', 'i fusilli', 'li', 'f_pasta_int'),
    'rigatoni': ('rigatoni', 'i rigatoni', 'li', 'f_pasta'),
    'mezze_maniche': ('mezze maniche', 'le mezze maniche', 'le', 'f_pasta'),
    'paccheri': ('paccheri', 'i paccheri', 'li', 'f_pasta'),
    'spaghetti': ('spaghetti', 'gli spaghetti', 'li', 'f_pasta'),
    'spaghetti_int': ('spaghetti integrali', 'gli spaghetti', 'li', 'f_pasta_int'),
    'linguine': ('linguine', 'le linguine', 'le', 'f_pasta'),
    'casarecce': ('casarecce', 'le casarecce', 'le', 'f_pasta'),
    'trofie': ('trofie', 'le trofie', 'le', 'f_pasta'),
}


def pasta(keys, g=80):
    out = []
    for k in keys:
        label, the, pron, fid = SHAPES[k]
        out.append(opt(k, label, {fid: g}, the=the, pron=pron))
    return out


def titled(opts, prefix=' con '):
    """Aggiunge l'attributo `title` (es. ' con zucca') alle opzioni."""
    for o in opts:
        o.attrs['title'] = prefix + o.label
    return opts


# --- Ragù e condimenti di carne ------------------------------------------------

RAGU_MEAT = [
    opt('manzo', 'manzo', {'f_macinato': 120}, 'manzo',
        add='Aggiungi il macinato e fallo rosolare a fuoco vivace per 6-7 minuti, sgranandolo con un cucchiaio di legno.',
        water=' e mezzo bicchiere di acqua', simmer=40),
    opt('misto', 'manzo e maiale', {'f_macinato': 70, 'f_salsiccia': 50}, 'carne',
        add='Aggiungi il macinato e la salsiccia spellata e sbriciolata e falli rosolare a fuoco vivace per 6-7 minuti, sgranandoli con un cucchiaio di legno.',
        water=' e mezzo bicchiere di acqua', simmer=40),
    opt('pollo', 'pollo e tacchino', {'f_macinato_pollo': 130}, 'pollo',
        add='Aggiungi il macinato di pollo e tacchino e fallo rosolare per 5-6 minuti, sgranandolo con un cucchiaio di legno.',
        water=' e mezzo bicchiere di acqua', simmer=30),
    opt('lenticchie', 'lenticchie', {'f_lenticchie': 60}, 'legumi',
        add='Aggiungi le lenticchie sciacquate e lasciale insaporire nel soffritto per 2 minuti.',
        water=' e 250 ml di acqua', simmer=40),
    opt('tempeh', 'tempeh', {'f_tempeh': 120}, 'vegetale',
        add='Sbriciola il tempeh con le mani, aggiungilo al soffritto e fallo rosolare per 5 minuti.',
        water=' e mezzo bicchiere di acqua', simmer=25),
]

RAGU_VEG = [
    opt('classico', '', {}, title='', early='', late=''),
    opt('funghi', 'funghi', {'f_funghi': 120}, title=' con funghi',
        early='Pulisci e affetta i funghi e falli saltare nel soffritto per 5 minuti.', late=''),
    opt('piselli', 'piselli', {'f_piselli': 90}, title=' con piselli', early='',
        late='Negli ultimi 12 minuti di cottura unisci i piselli surgelati.'),
    opt('melanzane', 'melanzane', {'f_melanzane': 150}, title=' con melanzane',
        early='Taglia le melanzane a cubetti e falle rosolare nel soffritto per 8 minuti.', late=''),
    opt('zucchine', 'zucchine', {'f_zucchine': 150}, title=' con zucchine', early='',
        late='Negli ultimi 10 minuti di cottura unisci le zucchine tagliate a cubetti piccoli.'),
]

WHITE_MEAT = [
    opt('pollo', 'pollo', {'f_macinato_pollo': 130}, 'pollo', the='il macinato di pollo'),
    opt('manzo', 'manzo', {'f_macinato': 120}, 'manzo', the='il macinato di manzo'),
    opt('vitello', 'vitello', {'f_vitello': 130}, 'manzo', the='il vitello tritato'),
    opt('salsiccia', 'salsiccia', {'f_salsiccia': 60, 'f_macinato': 60}, 'carne',
        the='la salsiccia sbriciolata e il macinato di manzo'),
]

# Proteine "da rosolare e mettere da parte" per risotti e farrotti.
RISO_PROT = {
    'salsiccia': opt('salsiccia', 'salsiccia', {'f_salsiccia': 70}, 'maiale', the='la salsiccia', pron='la',
                     cut='spella la salsiccia e sbriciolala', pan=5),
    'speck': opt('speck', 'speck', {'f_speck': 40}, 'maiale', the='lo speck', pron='lo',
                 cut='taglia lo speck a listarelle', pan=2),
    'pollo': opt('pollo', 'pollo', {'f_pollo': 120}, 'pollo', the='il pollo', pron='lo',
                 cut='taglia il pollo a bocconcini', pan=5),
    'ceci': opt('ceci', 'ceci', {'f_ceci': 200}, 'legumi', the='i ceci', pron='li',
                cut='sciacqua e sgocciola i ceci', pan=3),
}

# --- Pesce -----------------------------------------------------------------------

ALICI = opt('alici', 'alici', {'f_alici': 150}, 'pesce', the='le alici', pron='le',
            cut='pulisci le alici eliminando testa e lisca, aprile a libro e tagliale a pezzi', pan=2, oven=8)

FIORI = opt('fiori', 'fiori di zucca', {'f_fiori_zucca': 60}, the='i fiori di zucca', pron='li',
            cut='elimina il pistillo dai fiori di zucca e tagliali a listarelle', saute=2)

FISH_RED = [
    opt('polpo', 'polpo', {'f_polpo': 230}, 'pesce', cut='taglia il polpo a pezzetti',
        early='Aggiungi il polpo e fallo rosolare per 5 minuti.', stew=40, late=''),
    opt('calamari', 'calamari', {'f_calamari': 200}, 'pesce', cut='taglia i calamari ad anelli',
        early='Aggiungi i calamari e falli rosolare per 3 minuti.', stew=25, late=''),
    opt('merluzzo', 'merluzzo', {'f_merluzzo': 180}, 'pesce',
        cut='taglia il merluzzo a cubetti eliminando eventuali spine', early='', stew=12,
        late='Aggiungi il merluzzo e cuoci per 5 minuti senza mescolare troppo, per non sfaldarlo.'),
    opt('gamberi', 'gamberi', {'f_gamberi': 160}, 'pesce', cut='elimina il filo intestinale dai gamberi',
        early='', stew=12, late='Aggiungi i gamberi e cuoci per 3 minuti.'),
    opt('cozze', 'cozze', {'f_cozze': 200}, 'pesce', cut='sciacqua le cozze sgusciate',
        early='', stew=12, late='Aggiungi le cozze e cuoci per 3 minuti.'),
    opt('tonno', 'tonno', {'f_tonno': 90}, 'pesce', cut='sgocciola il tonno e sbriciolalo',
        early='', stew=12, late='Spegni il fuoco e unisci il tonno.'),
]

# --- Verdure con salsa per gli gnocchi al forno ----------------------------------

_TOMATO = 'Aggiungi la passata e cuoci per altri 8 minuti.'
_CREAM = 'Aggiungi il latte e il formaggio spalmabile e mescola a fuoco basso fino a ottenere una crema.'
GNOCCHI_VEG = []
for _o in veg(['melanzane', 'zucchine', 'peperoni', 'funghi', 'spinaci'], scale=0.8):
    _o.ing['f_passata'] = 120
    _o.attrs['sauce'] = _TOMATO
    GNOCCHI_VEG.append(_o)
for _o in veg(['zucca', 'radicchio', 'broccoli', 'porri', 'cavolo_nero'], scale=0.8):
    _o.ing.update({'f_latte': 80, 'f_spalmabile': 30})
    _o.attrs['sauce'] = _CREAM
    GNOCCHI_VEG.append(_o)

COUSCOUS_VEG = veg(['zucchine', 'melanzane', 'peperoni', 'zucca', 'cavolfiore', 'patate_dolci', 'finocchi'])
COUSCOUS_VEG[5].ing['f_patate_dolci'] = 140  # già ricche di amido

# --- Pasta fredda e insalata di riso ----------------------------------------------

COLD_VEG = [
    opt('pomodorini', 'pomodorini', {'f_pomodorini': 150}, prep='lava i pomodorini e tagliali in quattro'),
    opt('zucchine', 'zucchine grigliate', {'f_zucchine': 180},
        prep='taglia le zucchine a fette sottili per il lungo, grigliale su una piastra rovente 2 minuti per lato e tagliale a pezzetti'),
    opt('melanzane', 'melanzane grigliate', {'f_melanzane': 180},
        prep='taglia le melanzane a fette di mezzo centimetro, grigliale 3 minuti per lato e tagliale a pezzetti'),
    opt('peperoni', 'peperoni arrostiti', {'f_peperoni': 160},
        prep='arrostisci i peperoni in forno a 220 °C per 25 minuti, chiudili in un sacchetto per 10 minuti, spellali e tagliali a listarelle'),
    opt('fagiolini', 'fagiolini', {'f_fagiolini': 150},
        prep='spunta i fagiolini, lessali in acqua salata per 8 minuti e raffreddali in acqua e ghiaccio'),
]

COLD_PROT = [
    opt('tonno', 'tonno', {'f_tonno': 90}, 'pesce', prep='sgocciola il tonno e sbriciolalo'),
    opt('sgombro', 'sgombro', {'f_sgombro_scatola': 90}, 'pesce', prep='sgocciola lo sgombro e spezzettalo'),
    opt('pollo', 'pollo', {'f_pollo': 120}, 'pollo',
        prep='cuoci il petto di pollo su una piastra rovente per 5 minuti per lato, lascialo intiepidire e taglialo a straccetti'),
    opt('mozzarella', 'mozzarella', {'f_mozzarella_light': 110}, 'latticini',
        prep='taglia la mozzarella a cubetti e lasciala sgocciolare in un colino'),
    opt('ceci', 'ceci', {'f_ceci': 200}, 'legumi', prep='sciacqua e sgocciola i ceci'),
]


TEMPLATES = [
    # ------------------------------------------------------------------ ragù
    Template(
        key='p_ragu_bianco', type=MAIN,
        name='{f.label} al ragù bianco di {m.label} e {v.label}',
        base={'f_olio': 10, 'f_cipolla': 30, 'f_carote': 20, 'f_sedano': 20, 'f_erbe': 2,
              'f_brodo': 100, 'f_parmigiano': 8},
        slots={
            'f': pasta(['rigatoni', 'mezze_maniche', 'fusilli', 'penne_int']),
            'm': WHITE_MEAT,
            'v': veg(['zucchine', 'funghi', 'porcini', 'carciofi', 'asparagi', 'piselli_freschi', 'zucca',
                      'peperoni', 'radicchio', 'broccoli', 'porri', 'melanzane', 'cavolo_nero', 'fave'],
                     scale=0.8),
        },
        steps=[
            'Trita finemente cipolla, carota e sedano; {v.cut}.',
            "In una padella ampia scalda l'olio e fai appassire il trito per 5 minuti a fuoco medio.",
            'Aggiungi {m.the} e fai rosolare a fuoco vivace per 6-7 minuti, sgranando la carne con un cucchiaio di legno.',
            'Unisci {v.the} e le erbe aromatiche tritate, bagna con il brodo caldo e cuoci a fuoco medio per {v.saute} minuti, finché il sugo si è ristretto; regola di sale e pepe.',
            'Cuoci {f.the} in abbondante acqua salata, scola{f.pron} 2 minuti prima del tempo indicato e salta{f.pron} nel ragù con il parmigiano grattugiato e un mestolo di acqua di cottura.',
        ],
        fridge=3, freeze=True, minutes=40, max=14,
    ),
    Template(
        key='p_ragu_rosso', type=MAIN,
        name='{f.label} al ragù di {m.label}{v.title}',
        base={'f_olio': 8, 'f_cipolla': 30, 'f_carote': 30, 'f_sedano': 25, 'f_passata': 150,
              'f_concentrato': 10, 'f_parmigiano': 10},
        slots={
            'f': pasta(['rigatoni', 'paccheri', 'mezze_maniche', 'penne_int']),
            'm': RAGU_MEAT,
            'v': RAGU_VEG,
        },
        steps=[
            "Trita finemente cipolla, carota e sedano e fai appassire il trito in una casseruola con l'olio per 5 minuti.",
            '{v.early}',
            '{m.add}',
            'Unisci la passata, il concentrato{m.water}, copri e fai sobbollire a fuoco basso per {m.simmer} minuti, mescolando di tanto in tanto; regola di sale e pepe.',
            '{v.late}',
            'Cuoci {f.the} in abbondante acqua salata, scola{f.pron} al dente e condisci{f.pron} con il ragù e il parmigiano grattugiato.',
            'Per il meal prep il ragù si può preparare in dose doppia e congelare a parte in porzioni.',
        ],
        fridge=4, freeze=True, minutes=60, max=12,
    ),
    # ------------------------------------------------------------------ pesce
    Template(
        key='p_pesce_estate', type=MAIN,
        name='{f.label} con {p.label}, {v.label} e pomodorini',
        base={'f_olio': 10, 'f_aglio': 4, 'f_pomodorini': 120, 'f_prezzemolo': 5, 'f_spezie': 0.5},
        slots={
            'f': pasta(['spaghetti', 'linguine', 'mezze_maniche', 'paccheri', 'casarecce']),
            'p': prot(['pesce_spada', 'tonno_fresco', 'gamberi', 'calamari'], scale=0.95) + [ALICI],
            'v': veg(['zucchine', 'melanzane', 'peperoni'], scale=0.8) + [FIORI],
        },
        steps=[
            '{v.cut}; {p.cut}; lava i pomodorini e tagliali a metà.',
            "In una padella ampia scalda metà dell'olio con l'aglio schiacciato e il peperoncino, aggiungi {v.the} e salta{v.pron} a fuoco vivace per {v.saute} minuti.",
            'Unisci i pomodorini e cuoci per 5 minuti, schiacciandoli leggermente.',
            "Aggiungi {p.the} con il resto dell'olio e cuoci{p.pron} per {p.pan} minuti; elimina l'aglio e regola di sale e pepe.",
            'Cuoci {f.the} in abbondante acqua salata, scola{f.pron} al dente tenendo da parte un mestolo di acqua di cottura e salta{f.pron} nel sugo per 1 minuto.',
            'Completa con il prezzemolo tritato. Per il meal prep tieni la pasta ben al dente: si ammorbidisce quando la riscaldi.',
        ],
        fridge=2, minutes=30, max=10,
    ),
    Template(
        key='p_pesce_rosso', type=MAIN,
        name='{f.label} al sugo di {p.label}{g.title}',
        base={'f_olio': 10, 'f_aglio': 4, 'f_pelati': 200, 'f_prezzemolo': 5, 'f_spezie': 0.5},
        slots={
            'f': pasta(['spaghetti', 'linguine', 'paccheri', 'mezze_maniche']),
            'p': FISH_RED,
            'g': [opt('semplice', '', {}, title='', step=''),
                  opt('olive', 'olive e capperi', {'f_olive': 15, 'f_capperi': 8}, title=' con olive e capperi',
                      step='A metà cottura unisci le olive tagliate a rondelle e i capperi.')],
        },
        steps=[
            '{p.cut}; schiaccia i pelati con una forchetta.',
            "In una casseruola scalda l'olio con l'aglio schiacciato e il peperoncino per 1 minuto.",
            '{p.early}',
            'Unisci i pelati, copri e cuoci a fuoco basso per {p.stew} minuti; regola di sale.',
            '{g.step}',
            '{p.late}',
            'Cuoci {f.the} in abbondante acqua salata, scola{f.pron} al dente, salta{f.pron} nel sugo per 1 minuto e completa con il prezzemolo tritato.',
        ],
        fridge=2, minutes=35, max=8,
    ),
    Template(
        key='p_pesce_verdure', type=MAIN,
        name='{f.label} con {p.label} e {v.label}',
        base={'f_olio': 10, 'f_aglio': 4, 'f_prezzemolo': 5, 'f_limone': 10, 'f_pangrattato': 10},
        slots={
            'f': pasta(['linguine', 'mezze_maniche', 'casarecce', 'spaghetti_int']),
            'p': prot(['gamberi', 'salmone', 'merluzzo', 'calamari']),
            'v': veg(['broccoli', 'cime_rapa', 'carciofi', 'cavolfiore', 'asparagi', 'zucchine', 'porri',
                      'finocchi', 'piselli_freschi'], scale=0.9),
        },
        exclude=lambda c: c['p'].key == 'salmone' and c['v'].key == 'cime_rapa',
        steps=[
            '{v.cut}; {p.cut}.',
            "In una padella ampia scalda metà dell'olio con l'aglio, aggiungi {v.the} e salta{v.pron} per {v.saute} minuti, bagnando con un goccio d'acqua se serve.",
            "Unisci {p.the} con il resto dell'olio e cuoci{p.pron} per {p.pan} minuti; regola di sale e pepe.",
            'Tosta il pangrattato in un padellino asciutto per 2-3 minuti, finché è dorato.',
            'Cuoci {f.the} in abbondante acqua salata, scola{f.pron} al dente e salta{f.pron} nel condimento con la scorza grattugiata e il succo del limone.',
            'Completa con prezzemolo tritato e pangrattato tostato; per il meal prep tieni il pangrattato a parte, così resta croccante.',
        ],
        fridge=2, minutes=30, max=10,
    ),
    # ------------------------------------------------------------------ pesto
    Template(
        key='p_pesto', type=MAIN,
        name='{f.label} al pesto di {s.label} con {p.label}',
        base={'f_olio': 3},
        slots={
            'f': pasta(['trofie', 'fusilli', 'casarecce', 'penne_int']),
            's': [
                opt('basilico', 'basilico',
                    {'f_basilico': 15, 'f_pinoli': 8, 'f_parmigiano': 8, 'f_olio': 8, 'f_aglio': 1},
                    make="Frulla basilico, pinoli, parmigiano, una punta d'aglio e l'olio con un cucchiaio di acqua fredda"),
                opt('rucola', 'rucola e mandorle',
                    {'f_rucola': 40, 'f_mandorle': 10, 'f_parmigiano': 8, 'f_olio': 8, 'f_aglio': 1},
                    make="Frulla rucola, mandorle, parmigiano, una punta d'aglio e l'olio con un cucchiaio di acqua fredda"),
                opt('pistacchi', 'pistacchi',
                    {'f_pistacchi': 15, 'f_basilico': 8, 'f_parmigiano': 8, 'f_olio': 6},
                    make="Frulla pistacchi, basilico, parmigiano e l'olio con due cucchiai di acqua fredda"),
                opt('cavolo_nero', 'cavolo nero e noci',
                    {'f_cavolo_nero': 80, 'f_noci': 10, 'f_parmigiano': 8, 'f_olio': 8, 'f_aglio': 2},
                    make="Sbollenta le foglie di cavolo nero senza costa per 3 minuti, poi frullale con noci, parmigiano, aglio e l'olio"),
            ],
            'p': prot(['pollo', 'tacchino', 'ceci'], scale=0.9),
        },
        steps=[
            "{p.cut}; rosola{p.pron} in padella con un cucchiaino di olio per {p.pan} minuti e regola di sale.",
            '{s.make}, fino a ottenere una crema; regola di sale.',
            "Cuoci {f.the} in abbondante acqua salata e scola{f.pron} al dente, tenendo da parte un po' di acqua di cottura.",
            'Condisci {f.the} fuori dal fuoco con il pesto allungato con 2-3 cucchiai di acqua di cottura e aggiungi {p.the}.',
            'Il pesto non va cotto: quando riscaldi la porzione fallo a fuoco dolce con un goccio di acqua.',
        ],
        fridge=3, minutes=25, max=12,
    ),
    # ------------------------------------------------------------- pasta e legumi
    Template(
        key='p_pasta_legumi', type=MAIN,
        name='Pasta e {l.label}{v.title}',
        base={'f_pasta': 70, 'f_olio': 10, 'f_cipolla': 30, 'f_carote': 20, 'f_sedano': 20, 'f_aglio': 3,
              'f_erbe': 2, 'f_brodo': 450, 'f_parmigiano': 10},
        slots={
            'l': [
                opt('ceci', 'ceci', {'f_ceci': 220}, 'legumi',
                    add='Aggiungi i ceci e il brodo caldo e cuoci per 10 minuti.'),
                opt('borlotti', 'fagioli', {'f_fagioli': 230}, 'legumi',
                    add='Aggiungi i fagioli borlotti e il brodo caldo e cuoci per 10 minuti.'),
                opt('cannellini', 'fagioli cannellini', {'f_cannellini': 230}, 'legumi',
                    add='Aggiungi i cannellini e il brodo caldo e cuoci per 10 minuti.'),
                opt('lenticchie', 'lenticchie', {'f_lenticchie': 60}, 'legumi',
                    add='Aggiungi le lenticchie sciacquate e il brodo caldo e cuoci a fuoco basso per 30 minuti.'),
            ],
            'v': titled(veg(['zucca', 'cavolo_nero', 'bietole', 'broccoli', 'spinaci', 'zucchine', 'carciofi',
                             'cime_rapa', 'carote'], scale=0.7)),
        },
        steps=[
            'Trita cipolla, carota e sedano; {v.cut}.',
            "In una pentola capiente scalda due terzi dell'olio e fai appassire il trito con l'aglio e le erbe aromatiche tritate per 5 minuti.",
            '{l.add}',
            'Unisci {v.the} e prosegui la cottura per {v.boil} minuti; frulla un mestolo di minestra con il frullatore a immersione e rimettilo in pentola per renderla cremosa.',
            'Aggiungi la pasta e cuocila nella minestra per il tempo indicato, mescolando spesso e aggiungendo brodo caldo se serve.',
            "Servi con il parmigiano grattugiato e l'olio rimasto a crudo. Per il meal prep cuoci la pasta 2 minuti in meno: continuerà ad assorbire il brodo.",
        ],
        fridge=4, minutes=50, tags=['zuppa', 'piatto unico'], max=12,
    ),
    # ------------------------------------------------------------ pasta al forno
    Template(
        key='p_forno_rossa', type=MAIN,
        name='{f.label} al forno con {p.label} e {v.label}',
        base={'f_olio': 8, 'f_cipolla': 20, 'f_passata': 150, 'f_mozzarella_light': 50, 'f_parmigiano': 10,
              'f_basilico': 3},
        slots={
            'f': pasta(['rigatoni', 'penne', 'mezze_maniche', 'penne_int']),
            'p': [
                opt('polpettine', 'polpettine', {'f_macinato': 110}, 'manzo', the='le polpettine',
                    prep='Impasta il macinato con un pizzico di sale, forma delle polpettine grandi come una nocciola e rosolale in padella per 5 minuti'),
                opt('salsiccia', 'salsiccia', {'f_salsiccia': 70}, 'maiale', the='la salsiccia',
                    prep='Spella la salsiccia, sbriciolala e rosolala in padella senza grassi per 6 minuti'),
                opt('prosciutto', 'prosciutto cotto', {'f_prosciutto_cotto': 70}, 'maiale', the='il prosciutto cotto',
                    prep='Taglia il prosciutto cotto a dadini'),
                opt('ricotta', 'ricotta', {'f_ricotta': 100}, 'latticini', the='la ricotta a fiocchetti',
                    prep='Lavora la ricotta con una forchetta e un pizzico di pepe'),
            ],
            'v': veg(['melanzane', 'zucchine', 'peperoni', 'funghi', 'spinaci'], scale=0.9) + [
                opt('piselli', 'piselli', {'f_piselli': 100}, the='i piselli', pron='li',
                    cut='sbollenta i piselli surgelati per 3 minuti e scolali', saute=5)],
        },
        steps=[
            'Scalda il forno a 200 °C.',
            "In una casseruola fai appassire la cipolla tritata con metà dell'olio, unisci la passata e il basilico e cuoci per 10 minuti.",
            "{v.cut}; salta{v.pron} in padella con il resto dell'olio per {v.saute} minuti.",
            '{p.prep}.',
            'Cuoci {f.the} in acqua salata per metà del tempo indicato, scola{f.pron} e condisci{f.pron} con il sugo, {v.the}, {p.the} e metà della mozzarella a cubetti.',
            'Trasferisci in una teglia, copri con la mozzarella rimasta e il parmigiano e cuoci in forno per 20 minuti, finché la superficie è gratinata. Dividi in porzioni quando è tiepida.',
        ],
        fridge=4, freeze=True, minutes=55, tags=['forno'], max=8,
    ),
    Template(
        key='p_forno_bianca', type=MAIN,
        name='Pasta al forno bianca con {v.label} e {p.label}',
        base={'f_pasta': 80, 'f_latte': 150, 'f_farina': 12, 'f_burro': 6, 'f_parmigiano': 12,
              'f_mozzarella_light': 40, 'f_olio': 5, 'f_cipolla': 20},
        slots={
            'v': veg(['zucca', 'broccoli', 'cavolfiore', 'funghi', 'porcini', 'radicchio', 'carciofi',
                      'asparagi', 'porri', 'spinaci'], scale=0.9),
            'p': [
                opt('prosciutto', 'prosciutto cotto', {'f_prosciutto_cotto': 70}, 'maiale',
                    the='il prosciutto cotto', prep='Taglia il prosciutto cotto a dadini'),
                opt('salsiccia', 'salsiccia', {'f_salsiccia': 60}, 'maiale', the='la salsiccia',
                    prep='Spella la salsiccia, sbriciolala e rosolala in padella senza grassi per 6 minuti'),
                opt('speck', 'speck', {'f_speck': 40}, 'maiale', the='lo speck',
                    prep='Taglia lo speck a listarelle e fallo dorare in padella per 2 minuti'),
                opt('pollo', 'pollo', {'f_pollo': 110}, 'pollo', the='il pollo',
                    prep='Taglia il pollo a dadini e rosolalo in padella per 6 minuti'),
            ],
        },
        steps=[
            'Scalda il forno a 200 °C.',
            "{v.cut}; salta{v.pron} in padella con l'olio e la cipolla tritata per {v.saute} minuti.",
            '{p.prep}.',
            'Prepara la besciamella: sciogli il burro in un pentolino, aggiungi la farina e tostala per 1 minuto, poi versa il latte freddo a filo mescolando con una frusta e cuoci per 5 minuti finché si addensa; insaporisci con sale e noce moscata.',
            'Cuoci la pasta in acqua salata per metà del tempo indicato, scolala e condiscila con la besciamella, {v.the}, {p.the} e metà del parmigiano.',
            'Trasferisci in una teglia, completa con la mozzarella a cubetti e il parmigiano rimasto e cuoci in forno per 20-25 minuti, finché la superficie è gratinata.',
        ],
        fridge=4, freeze=True, minutes=55, tags=['forno'], max=10,
    ),
    Template(
        key='p_lasagne', type=MAIN,
        name='Lasagne al ragù di {m.label}{v.title}',
        base={'f_lasagne': 75, 'f_olio': 6, 'f_cipolla': 25, 'f_carote': 25, 'f_sedano': 20,
              'f_passata': 130, 'f_latte': 100, 'f_farina': 8, 'f_burro': 5, 'f_parmigiano': 12},
        slots={
            'm': [
                opt('manzo', 'manzo', {'f_macinato': 100}, 'manzo',
                    add='Aggiungi il macinato e fallo rosolare a fuoco vivace per 6-7 minuti, sgranandolo con un cucchiaio di legno.',
                    water=' e mezzo bicchiere di acqua', simmer=40),
                opt('misto', 'manzo e maiale', {'f_macinato': 60, 'f_salsiccia': 40}, 'carne',
                    add='Aggiungi il macinato e la salsiccia spellata e sbriciolata e falli rosolare a fuoco vivace per 6-7 minuti.',
                    water=' e mezzo bicchiere di acqua', simmer=40),
                opt('pollo', 'pollo e tacchino', {'f_macinato_pollo': 110}, 'pollo',
                    add='Aggiungi il macinato di pollo e tacchino e fallo rosolare per 5-6 minuti, sgranandolo con un cucchiaio di legno.',
                    water=' e mezzo bicchiere di acqua', simmer=30),
                opt('lenticchie', 'lenticchie', {'f_lenticchie': 50}, 'legumi',
                    add='Aggiungi le lenticchie sciacquate e lasciale insaporire nel soffritto per 2 minuti.',
                    water=' e 250 ml di acqua', simmer=40),
            ],
            'v': [o for o in RAGU_VEG],
        },
        steps=[
            "Trita cipolla, carota e sedano e fai appassire il trito in una casseruola con l'olio per 5 minuti.",
            '{v.early}',
            '{m.add}',
            'Unisci la passata{m.water}, copri e cuoci a fuoco basso per {m.simmer} minuti; il ragù deve restare morbido. {v.late}',
            'Prepara la besciamella: sciogli il burro, tosta la farina per 1 minuto, versa il latte freddo a filo mescolando con una frusta e cuoci per 5 minuti finché si addensa.',
            'Scalda il forno a 190 °C. In una pirofila alterna strati di sfoglie (del tipo che non richiede precottura), ragù, besciamella e parmigiano, finendo con ragù, besciamella e parmigiano.',
            'Copri con alluminio e cuoci per 25 minuti, poi scopri e gratina per altri 10 minuti. Lascia riposare 15 minuti prima di tagliare le porzioni.',
        ],
        fridge=4, freeze=True, minutes=90, tags=['forno'], max=10,
    ),
    Template(
        key='p_cannelloni', type=MAIN,
        name='Cannelloni di ricotta e {v.label}{p.title}',
        base={'f_lasagne': 70, 'f_ricotta': 100, 'f_parmigiano': 15, 'f_passata': 150, 'f_olio': 8,
              'f_aglio': 3, 'f_basilico': 3, 'f_mozzarella_light': 30},
        slots={
            'v': veg(['spinaci', 'bietole', 'zucca', 'funghi', 'carciofi', 'asparagi', 'zucchine', 'radicchio'],
                     scale=0.8),
            'p': [opt('semplici', '', {}, title='', fill=''),
                  opt('prosciutto', 'prosciutto cotto', {'f_prosciutto_cotto': 50}, title=' con prosciutto cotto',
                      fill=', il prosciutto cotto a dadini')],
        },
        protein='latticini',
        steps=[
            'Scalda il forno a 190 °C.',
            "{v.cut}; salta{v.pron} in padella con metà dell'olio e l'aglio per {v.saute} minuti, poi trita{v.pron} grossolanamente.",
            'Mescola le verdure con la ricotta, due terzi del parmigiano{p.fill}, sale e pepe.',
            'Lessa le sfoglie per lasagne per 2 minuti in acqua salata, stendile su un canovaccio, distribuisci il ripieno sul lato corto e arrotolale a formare i cannelloni.',
            "Cuoci la passata con il resto dell'olio e il basilico per 10 minuti; versane metà in una pirofila, adagia i cannelloni e coprili con il sugo rimasto, la mozzarella a cubetti e il parmigiano rimasto.",
            'Cuoci in forno per 25 minuti, finché la superficie è gratinata.',
        ],
        fridge=4, freeze=True, minutes=60, tags=['forno'], max=8,
    ),
    Template(
        key='p_gnocchi_forno', type=MAIN,
        name='Gnocchi al forno con {v.label} e {p.label}',
        base={'f_gnocchi': 200, 'f_olio': 6, 'f_aglio': 3, 'f_mozzarella_light': 60, 'f_parmigiano': 12},
        slots={
            'v': GNOCCHI_VEG,
            'p': [
                opt('salsiccia', 'salsiccia', {'f_salsiccia': 60}, 'maiale', mix='',
                    prep='Spella la salsiccia, sbriciolala e uniscila alle verdure a metà cottura.'),
                opt('speck', 'speck', {'f_speck': 40}, 'maiale', mix='',
                    prep='Taglia lo speck a listarelle e uniscilo alle verdure negli ultimi 2 minuti.'),
                opt('prosciutto', 'prosciutto cotto', {'f_prosciutto_cotto': 60}, 'maiale',
                    mix=', il prosciutto cotto a dadini', prep=''),
                opt('scamorza', 'scamorza', {'f_scamorza': 30}, 'latticini',
                    mix=', la scamorza a cubetti', prep=''),
            ],
        },
        steps=[
            'Scalda il forno a 200 °C.',
            "{v.cut}; salta{v.pron} in padella con l'olio e l'aglio per {v.saute} minuti.",
            '{p.prep}',
            '{v.sauce}',
            'Lessa gli gnocchi in acqua salata solo finché vengono a galla, scolali e mescolali con il condimento{p.mix} e metà della mozzarella a cubetti.',
            'Trasferisci in una pirofila, completa con la mozzarella rimasta e il parmigiano e gratina in forno per 15-20 minuti.',
        ],
        fridge=3, minutes=40, tags=['forno'], max=10,
    ),
    # ------------------------------------------------------- risotti e farrotti
    Template(
        key='p_risotto_carne', type=MAIN,
        name='Risotto con {v.label} e {p.label}',
        base={'f_riso_carnaroli': 80, 'f_brodo': 350, 'f_cipolla': 30, 'f_olio': 6, 'f_parmigiano': 15},
        slots={
            'v': veg(['zucca', 'asparagi', 'funghi', 'porcini', 'radicchio', 'zucchine', 'carciofi',
                      'piselli_freschi', 'porri', 'cavolo_nero', 'peperoni', 'broccoli', 'spinaci'], scale=0.7),
            'p': [RISO_PROT['salsiccia'], RISO_PROT['speck'], RISO_PROT['pollo']],
        },
        exclude=lambda c: c['p'].key == 'speck' and c['v'].key in ('peperoni', 'spinaci'),
        steps=[
            'Trita la cipolla; {v.cut}; {p.cut}.',
            "In una casseruola scalda l'olio e rosola {p.the} per {p.pan} minuti, poi togli{p.pron} e tieni{p.pron} da parte.",
            'Nella stessa casseruola fai appassire la cipolla per 3 minuti, aggiungi {v.the} e lascia insaporire per 3-4 minuti.',
            'Unisci il riso, tostalo per 2 minuti e cuocilo per 17-18 minuti aggiungendo il brodo caldo un mestolo alla volta; a metà cottura rimetti in pentola {p.the}.',
            'Spegni il fuoco, manteca con il parmigiano e lascia riposare coperto per 2 minuti. Per il meal prep tieni il risotto morbido e riscaldalo con un goccio di brodo.',
        ],
        fridge=3, minutes=40, tags=['risotto'], max=14,
    ),
    Template(
        key='p_risotto_pesce', type=MAIN,
        name='Risotto con {p.label} e {v.label}',
        base={'f_riso_carnaroli': 80, 'f_brodo': 350, 'f_cipolla': 25, 'f_olio': 10, 'f_limone': 10,
              'f_prezzemolo': 5},
        slots={
            'p': prot(['gamberi', 'salmone', 'calamari'], scale=0.95),
            'v': veg(['zucchine', 'asparagi', 'zucca', 'carciofi', 'piselli_freschi', 'porri', 'finocchi'],
                     scale=0.7),
        },
        steps=[
            'Trita la cipolla; {v.cut}; {p.cut}.',
            "In una casseruola scalda metà dell'olio, fai appassire la cipolla per 3 minuti, aggiungi {v.the} e lascia insaporire per 3-4 minuti.",
            'Unisci il riso, tostalo per 2 minuti e cuocilo per 17-18 minuti aggiungendo il brodo caldo un mestolo alla volta.',
            'Negli ultimi {p.pan} minuti aggiungi {p.the} e regola di sale.',
            "Spegni il fuoco e manteca con l'olio rimasto, la scorza grattugiata e un po' di succo di limone e il prezzemolo tritato.",
        ],
        fridge=2, minutes=40, tags=['risotto'], max=10,
    ),
    Template(
        key='p_farrotto', type=MAIN,
        name='{c.label} con {v.label} e {p.label}',
        base={'f_brodo': 450, 'f_cipolla': 30, 'f_olio': 8, 'f_parmigiano': 12, 'f_erbe': 2},
        slots={
            'c': [opt('farro', 'farrotto', {'f_farro': 80}, the='il farro', pron='lo', min=25, dish='il farrotto'),
                  opt('orzo', 'orzotto', {'f_orzo': 80}, the="l'orzo", pron='lo', min=30, dish="l'orzotto")],
            'v': veg(['zucca', 'cavolo_nero', 'funghi', 'porcini', 'radicchio', 'porri', 'broccoli',
                      'carciofi', 'zucchine', 'asparagi'], scale=0.8),
            'p': [RISO_PROT['pollo'], RISO_PROT['speck'], RISO_PROT['ceci'], RISO_PROT['salsiccia']],
        },
        steps=[
            'Sciacqua {c.the}; trita la cipolla; {v.cut}; {p.cut}.',
            "In una casseruola scalda l'olio e rosola {p.the} per {p.pan} minuti, poi togli{p.pron} e tieni{p.pron} da parte.",
            'Nella stessa casseruola fai appassire la cipolla con le erbe tritate per 3 minuti, aggiungi {v.the} e lascia insaporire per 3-4 minuti.',
            'Unisci {c.the}, tosta{c.pron} per 2 minuti e cuoci{c.pron} per {c.min} minuti aggiungendo il brodo caldo poco alla volta, come un risotto.',
            'Negli ultimi 5 minuti rimetti in pentola {p.the}; spegni e manteca con il parmigiano.',
            '{c.dish} si riscalda benissimo: per il meal prep aggiungi un goccio di brodo quando lo scaldi.',
        ],
        fridge=4, minutes=45, tags=['risotto'], max=10,
    ),
    # ----------------------------------------------------- cous cous e bulgur
    Template(
        key='p_couscous', type=MAIN,
        name='{c.label} speziato con {p.label} e {v.label}',
        base={'f_olio': 10, 'f_cipolla': 40, 'f_carote': 40, 'f_aglio': 3, 'f_cumino': 1, 'f_curcuma': 1,
              'f_paprika': 1, 'f_brodo': 200, 'f_prezzemolo': 5, 'f_limone': 10, 'f_mandorle': 8},
        slots={
            'c': [opt('couscous', 'cous cous', {'f_couscous': 75}, the='il cous cous',
                      cook='Versa sul cous cous lo stesso peso di acqua bollente salata, copri per 5 minuti e sgranalo con una forchetta'),
                  opt('bulgur', 'bulgur', {'f_bulgur': 75}, the='il bulgur',
                      cook='Cuoci il bulgur nel doppio del suo volume di acqua salata per 12 minuti, poi sgranalo con una forchetta')],
            'p': prot(['pollo', 'sovracosce', 'tacchino', 'ceci']),
            'v': COUSCOUS_VEG,
        },
        steps=[
            'Affetta la cipolla e taglia le carote a rondelle; {v.cut}; {p.cut}.',
            "In una padella ampia scalda l'olio e rosola {p.the} per 4-5 minuti con cumino, curcuma e paprika.",
            "Aggiungi la cipolla, le carote, l'aglio tritato e {v.the}, bagna con il brodo e cuoci coperto a fuoco medio per {v.saute} minuti, finché le verdure sono tenere.",
            '{c.cook}.',
            'Tosta le mandorle a lamelle in un padellino asciutto per 2 minuti.',
            'Distribuisci {c.the} nei contenitori, copri con lo spezzatino di verdure e completa con mandorle, prezzemolo tritato e succo di limone.',
        ],
        fridge=4, minutes=35, tags=['piatto unico'], max=10,
    ),
    Template(
        key='p_bulgur_pilaf', type=MAIN,
        name='Pilaf di bulgur con {p.label}, {v.label} e yogurt',
        base={'f_bulgur': 75, 'f_cipolla': 40, 'f_olio': 10, 'f_concentrato': 15, 'f_brodo': 180,
              'f_paprika': 1, 'f_cumino': 0.5, 'f_yogurt_greco': 60, 'f_prezzemolo': 5},
        slots={
            'p': prot(['tacchino', 'manzo', 'pollo']) + [
                opt('lenticchie', 'lenticchie', {'f_lenticchie': 50}, 'legumi', the='le lenticchie', pron='le',
                    cut='lessa le lenticchie in acqua per 20 minuti e scolale', pan=2)],
            'v': veg(['peperoni', 'melanzane', 'zucchine', 'cavolfiore', 'spinaci', 'carote'], scale=0.8),
        },
        steps=[
            "{p.cut}; rosola{p.pron} in una casseruola con metà dell'olio per {p.pan} minuti, poi togli{p.pron} e tieni{p.pron} da parte.",
            '{v.cut}; affetta la cipolla.',
            "Nella stessa casseruola scalda l'olio rimasto, fai appassire la cipolla per 4 minuti, aggiungi {v.the} con paprika e cumino e cuoci per {v.saute} minuti.",
            'Unisci il bulgur e il concentrato di pomodoro, mescola, versa il brodo caldo, copri e cuoci a fuoco basso per 12 minuti.',
            'Rimetti in pentola {p.the}, spegni e lascia riposare coperto per 10 minuti, poi sgrana con una forchetta.',
            'Servi con lo yogurt greco e il prezzemolo tritato; per il meal prep conserva lo yogurt a parte.',
        ],
        fridge=4, minutes=35, tags=['piatto unico'], max=8,
    ),
    # ------------------------------------------------------------------- noodles
    Template(
        key='p_noodles', type=MAIN,
        name='Noodles di riso saltati con {p.label} e {v.label}',
        base={'f_noodles_riso': 80, 'f_olio': 10, 'f_soia': 15, 'f_zenzero': 5, 'f_aglio': 4, 'f_sesamo': 5},
        slots={
            'p': prot(['pollo', 'manzo', 'maiale', 'tofu', 'tempeh']),
            'v': veg(['broccoli', 'peperoni', 'zucchine', 'carote', 'funghi', 'verza', 'fagiolini', 'asparagi',
                      'cavolo_rosso']),
        },
        steps=[
            "Metti in ammollo i noodles in acqua bollente per 5-8 minuti (o come indicato sulla confezione), scolali e passali sotto l'acqua fredda.",
            '{p.cut}; {v.cut}; trita aglio e zenzero.',
            "Scalda metà dell'olio nel wok a fuoco vivace e salta {p.the} per {p.pan} minuti, poi togli{p.pron} e tieni{p.pron} da parte.",
            "Nello stesso wok scalda l'olio rimasto, salta aglio e zenzero per 30 secondi, poi aggiungi {v.the} e salta{v.pron} a fuoco vivace per {v.saute} minuti.",
            'Unisci i noodles, {p.the} e la salsa di soia diluita con 2 cucchiai di acqua e salta tutto per 2 minuti.',
            "Completa con i semi di sesamo tostati. Per il meal prep riscalda le porzioni in padella con un goccio d'acqua.",
        ],
        fridge=3, minutes=25, tags=['wok'], max=12,
    ),
    Template(
        key='p_padthai', type=MAIN,
        name='Pad thai con {p.label} e {v.label}',
        base={'f_noodles_riso': 75, 'f_uova': 55, 'f_arachidi': 15, 'f_soia': 12, 'f_limone': 15,
              'f_aglio': 3, 'f_cipolla': 20, 'f_olio': 8, 'f_zucchero_canna': 5},
        slots={
            'p': prot(['gamberi', 'pollo', 'tofu'], scale=0.85),
            'v': veg(['carote', 'zucchine', 'peperoni', 'verza', 'broccoli'], scale=0.7),
        },
        steps=[
            'Metti in ammollo i noodles in acqua calda per 8 minuti e scolali.',
            'Per la salsa mescola la salsa di soia, il succo di limone, lo zucchero di canna e 2 cucchiai di acqua.',
            "{p.cut}; {v.cut}; trita la cipolla e l'aglio.",
            "Nel wok scalda l'olio, salta cipolla e aglio per 1 minuto, aggiungi {p.the} e cuoci{p.pron} per {p.pan} minuti, poi unisci {v.the} e salta tutto per 3-4 minuti.",
            "Sposta tutto su un lato, rompi l'uovo nel wok e strapazzalo, poi unisci i noodles e la salsa e salta per 2 minuti.",
            'Completa con le arachidi tritate grossolanamente; per il meal prep tienile a parte, così restano croccanti.',
        ],
        fridge=2, minutes=30, tags=['wok'], max=8,
    ),
    # ------------------------------------------------------------- piatti freddi
    Template(
        key='p_pasta_fredda', type=MAIN,
        name='Pasta fredda con {p.label} e {v.label}',
        base={'f_pasta': 80, 'f_olio': 10, 'f_basilico': 5, 'f_olive': 15, 'f_capperi': 5, 'f_cipolla_rossa': 15},
        slots={'p': COLD_PROT, 'v': COLD_VEG},
        steps=[
            "Cuoci la pasta corta (fusilli o farfalle) in abbondante acqua salata, scolala al dente, passala sotto l'acqua fredda e condiscila subito con un cucchiaino di olio perché non si attacchi.",
            '{v.prep}.',
            '{p.prep}.',
            'Affetta sottilmente la cipolla rossa e taglia le olive a rondelle.',
            "Unisci tutto in una ciotola con il basilico spezzettato, i capperi e l'olio rimasto; regola di sale e pepe e lascia insaporire in frigo per almeno 30 minuti.",
        ],
        fridge=3, minutes=30, tags=['freddo', 'insalata'], max=10,
    ),
    Template(
        key='p_insalata_riso', type=MAIN,
        name='Insalata di {c.label} con {p.label} e {v.label}',
        base={'f_olio': 10, 'f_mais': 30, 'f_olive': 10, 'f_basilico': 3, 'f_limone': 10},
        slots={
            'c': [opt('riso', 'riso', {'f_riso': 75}, cook='Lessa il riso in abbondante acqua salata per 12 minuti'),
                  opt('venere', 'riso Venere', {'f_riso_venere': 75},
                      cook='Lessa il riso Venere in abbondante acqua salata per 18 minuti')],
            'p': [
                opt('tonno', 'tonno', {'f_tonno': 90}, 'pesce', prep='Sgocciola il tonno e sbriciolalo'),
                opt('uova', 'uova sode', {'f_uova': 110, 'f_prosciutto_cotto': 40}, 'uova',
                    prep='Rassoda le uova in acqua bollente per 9 minuti, raffreddale, sgusciale e tagliale a spicchi; taglia il prosciutto cotto a dadini'),
                opt('pollo', 'pollo', {'f_pollo': 120}, 'pollo',
                    prep='Cuoci il petto di pollo su una piastra rovente per 5 minuti per lato e taglialo a dadini'),
                opt('mozzarella', 'mozzarella', {'f_mozzarella_light': 110}, 'latticini',
                    prep='Taglia la mozzarella a dadini e lasciala sgocciolare in un colino'),
            ],
            'v': [
                opt('pomodorini', 'pomodorini', {'f_pomodorini': 120}, prep='taglia i pomodorini in quattro'),
                opt('peperoni', 'peperoni', {'f_peperoni': 120}, prep='taglia i peperoni a dadini'),
                opt('zucchine', 'zucchine', {'f_zucchine': 150},
                    prep="taglia le zucchine a dadini e saltale in padella con un cucchiaino di olio per 5 minuti"),
                opt('piselli', 'piselli', {'f_piselli': 100}, prep='lessa i piselli surgelati per 5 minuti e raffreddali'),
                opt('cetrioli', 'cetrioli', {'f_cetrioli': 150}, prep='taglia i cetrioli a dadini'),
            ],
        },
        steps=[
            "{c.cook}, scolalo, passalo sotto l'acqua fredda e allargalo su un vassoio a raffreddare.",
            '{p.prep}.',
            'Sgocciola il mais e taglia le olive a rondelle; {v.prep}.',
            "Unisci tutto in una ciotola e condisci con l'olio, il succo di limone e il basilico spezzettato; regola di sale e pepe.",
            'Lascia insaporire in frigo per almeno 30 minuti prima di servire.',
        ],
        fridge=3, minutes=30, tags=['freddo', 'insalata'], max=8,
    ),
    # --------------------------------------------------------- pasta di legumi
    Template(
        key='p_pasta_lenticchie', type=MAIN,
        name='Pasta di lenticchie rosse con {v.label} e {p.label}',
        base={'f_pasta_legumi': 80, 'f_olio': 10, 'f_aglio': 3, 'f_basilico': 3},
        slots={
            'v': veg(['zucchine', 'broccoli', 'zucca', 'spinaci', 'peperoni', 'asparagi', 'carciofi',
                      'cavolo_nero', 'melanzane'], scale=0.9),
            'p': [
                opt('feta', 'feta', {'f_feta': 40}, 'latticini', the='la feta sbriciolata', cook=''),
                opt('tonno', 'tonno', {'f_tonno': 70}, 'pesce', the='il tonno sgocciolato', cook=''),
                opt('pollo', 'pollo', {'f_pollo': 100}, 'pollo', the='il pollo',
                    cook="Taglia il pollo a bocconcini, rosolalo in padella con un cucchiaino dell'olio per 8 minuti e tienilo da parte."),
                opt('tofu', 'tofu', {'f_tofu': 120}, 'vegetale', the='il tofu',
                    cook="Taglia il tofu a cubetti, rosolalo in padella con un cucchiaino dell'olio per 8 minuti finché è dorato e tienilo da parte."),
            ],
        },
        steps=[
            '{p.cook}',
            "{v.cut}; salta{v.pron} in padella con l'olio e l'aglio per {v.saute} minuti.",
            'Cuoci la pasta di lenticchie in acqua salata per il tempo indicato (di solito 6-8 minuti) senza superarlo, perché tende a sfaldarsi, e scolala delicatamente.',
            'Unisci la pasta alle verdure, aggiungi {p.the} e mescola con delicatezza; completa con il basilico spezzettato.',
        ],
        fridge=3, minutes=25, max=8,
    ),
    # ------------------------------------------------------------- con le uova
    Template(
        key='p_carbonara_verdure', type=MAIN,
        name='{f.label} alla carbonara di {v.label}',
        base={'f_uova': 55, 'f_albume': 60, 'f_pecorino': 15, 'f_olio': 10, 'f_aglio': 3},
        slots={
            'f': pasta(['spaghetti', 'mezze_maniche', 'rigatoni', 'spaghetti_int']),
            'v': veg(['zucchine', 'asparagi', 'carciofi', 'funghi', 'piselli_freschi', 'porri', 'fave'], scale=0.9),
        },
        protein='uova',
        steps=[
            "{v.cut}; salta{v.pron} in padella con l'olio e l'aglio per {v.saute} minuti, poi elimina l'aglio.",
            "In una ciotola sbatti l'uovo con l'albume, il pecorino grattugiato e abbondante pepe.",
            'Cuoci {f.the} in abbondante acqua salata e scola{f.pron} al dente, tenendo da parte un mestolo di acqua di cottura.',
            "Versa {f.the} nella padella con le verdure, togli dal fuoco e aggiungi il composto di uova con un po' di acqua di cottura, mescolando velocemente finché diventa cremoso senza rapprendersi.",
            'Per il meal prep tieni la pasta più cremosa del solito e riscaldala a fuoco dolce con un cucchiaio di acqua, mescolando.',
        ],
        fridge=2, minutes=25, max=8,
    ),
    Template(
        key='p_frittata_pasta', type=MAIN,
        name='Frittata di pasta con {v.label} e {p.label}',
        base={'f_pasta': 70, 'f_uova': 110, 'f_albume': 60, 'f_parmigiano': 15, 'f_olio': 8},
        slots={
            'v': veg(['zucchine', 'spinaci', 'asparagi', 'piselli_freschi', 'carciofi', 'funghi', 'broccoli',
                      'peperoni'], scale=0.8),
            'p': [
                opt('prosciutto', 'prosciutto cotto', {'f_prosciutto_cotto': 40}, the='il prosciutto cotto a dadini'),
                opt('speck', 'speck', {'f_speck': 30}, the='lo speck a listarelle'),
                opt('scamorza', 'scamorza', {'f_scamorza': 30}, the='la scamorza a cubetti'),
                opt('mozzarella', 'mozzarella', {'f_mozzarella_light': 50}, the='la mozzarella a cubetti ben sgocciolata'),
            ],
        },
        protein='uova',
        steps=[
            'Cuoci gli spaghetti in acqua salata, scolali al dente e lasciali intiepidire.',
            "{v.cut}; salta{v.pron} in padella con metà dell'olio per {v.saute} minuti.",
            "In una ciotola sbatti le uova con l'albume e il parmigiano; unisci gli spaghetti, {v.the} e {p.the}.",
            "Scalda l'olio rimasto in una padella antiaderente da 20 cm, versa il composto e cuoci coperto a fuoco medio-basso per 8 minuti; gira la frittata aiutandoti con un coperchio e cuoci per altri 5 minuti.",
            'Lasciala intiepidire e tagliala a spicchi: si mangia anche fredda o a temperatura ambiente.',
        ],
        fridge=3, minutes=35, max=8,
    ),
    # --------------------------------------------------------------- orecchiette
    Template(
        key='p_orecchiette', type=MAIN,
        name='Orecchiette con {v.label} e {p.label}',
        base={'f_pasta': 80, 'f_olio': 10, 'f_aglio': 4, 'f_spezie': 0.5, 'f_pangrattato': 10, 'f_pecorino': 10},
        slots={
            'v': veg(['cime_rapa', 'broccoli', 'cavolfiore', 'cavolo_nero', 'fagiolini', 'verza']),
            'p': [
                opt('salsiccia', 'salsiccia', {'f_salsiccia': 70}, 'maiale',
                    how='spella la salsiccia, sbriciolala nella padella e rosolala per 6 minuti'),
                opt('ceci', 'ceci', {'f_ceci': 200}, 'legumi',
                    how='aggiungi i ceci sciacquati e sgocciolati e lasciali insaporire per 4 minuti'),
                opt('tonno', 'tonno', {'f_tonno': 80}, 'pesce',
                    how='spegni il fuoco e aggiungi il tonno sgocciolato e sbriciolato'),
            ],
        },
        steps=[
            '{v.cut}.',
            "In una padella ampia scalda l'olio con l'aglio schiacciato e il peperoncino, poi {p.how}.",
            'Cuoci le orecchiette in abbondante acqua salata; {v.boil} minuti prima della fine aggiungi {v.the} nella stessa pentola.',
            'Scola orecchiette e verdure al dente, versale nella padella ed elimina l\'aglio; salta tutto a fuoco vivace per 2 minuti con un mestolo di acqua di cottura.',
            'Tosta il pangrattato in un padellino asciutto per 2 minuti e completa con il pecorino grattugiato e il pangrattato; per il meal prep tieni il pangrattato a parte.',
        ],
        fridge=3, minutes=30, max=8,
    ),
]
