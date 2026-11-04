"""Secondi completi di carne e pesce per il meal prep: proteina, contorno di
verdura e fonte di carboidrati (cereale, patate, pane o polenta)."""

from engine import MAIN, Template, opt
from lib import veg

# --- Contorni di carboidrati ----------------------------------------------

_SIDES = {
    'polenta': opt('polenta', 'polenta', {'f_polenta': 70}, the='la polenta',
                   cook='porta a bollore acqua salata pari a quattro volte il peso della farina di mais, versala '
                        'a pioggia e cuoci la polenta per 40 minuti mescolando spesso (8 minuti se è istantanea)'),
    'pure': opt('pure', 'purè', {'f_patate': 250, 'f_latte': 50}, the='il purè',
                cook='lessa le patate sbucciate e tagliate a tocchi per 20 minuti, schiacciale e lavorale '
                     'sul fuoco con il latte caldo fino a ottenere un purè morbido'),
    'patate': opt('patate', 'patate al forno', {'f_patate': 250}, the='le patate',
                  cook="taglia le patate a spicchi, condiscile con un filo d'olio, sale e pepe e cuocile "
                       "in forno a 200 °C per 35-40 minuti"),
    'riso': opt('riso', 'riso basmati', {'f_riso': 70}, the='il riso',
                cook='lessa il riso basmati in abbondante acqua salata per 12 minuti e scolalo'),
    'riso_int': opt('riso_int', 'riso integrale', {'f_riso_int': 70}, the='il riso',
                    cook='lessa il riso integrale in acqua salata per 35-40 minuti e scolalo'),
    'riso_venere': opt('riso_venere', 'riso Venere', {'f_riso_venere': 70}, the='il riso',
                       cook='lessa il riso Venere in acqua salata per 18 minuti e scolalo'),
    'pane': opt('pane', 'pane integrale', {'f_pane_int': 90}, the='il pane',
                cook='taglia il pane a fette e tostalo in forno o in padella al momento di servire'),
    'couscous': opt('couscous', 'cous cous', {'f_couscous': 70}, the='il cous cous',
                    cook='versa sul cous cous lo stesso peso di acqua bollente salata, copri per 5 minuti '
                         'e sgranalo con una forchetta'),
    'bulgur': opt('bulgur', 'bulgur', {'f_bulgur': 70}, the='il bulgur',
                  cook='cuoci il bulgur nel doppio del suo volume di acqua salata per 12 minuti, poi sgranalo'),
    'farro': opt('farro', 'farro', {'f_farro': 70}, the='il farro',
                 cook='lessa il farro perlato in acqua salata per 20-25 minuti e scolalo'),
    'quinoa': opt('quinoa', 'quinoa', {'f_quinoa': 65}, the='la quinoa',
                  cook="sciacqua la quinoa e cuocila nel doppio del suo volume di acqua salata per 15 minuti, "
                       "finché assorbe tutta l'acqua"),
    'noodles': opt('noodles', 'noodles di riso', {'f_noodles_riso': 70}, the='i noodles',
                   cook='ammolla i noodles di riso in acqua bollente per 5 minuti e scolali'),
}


def sides(*keys):
    return [_SIDES[k] for k in keys]


# Verdure da contorno saltate in padella, disponibili in tutte le stagioni.
CONTORNO = ['spinaci', 'bietole', 'cime_rapa', 'broccoli', 'fagiolini', 'zucchine', 'cavolo_nero',
            'piselli_freschi', 'carciofi', 'asparagi', 'peperoni', 'funghi', 'verza', 'finocchi']
GRILL = ['zucchine', 'melanzane', 'peperoni', 'radicchio', 'funghi', 'finocchi', 'zucca']
FORNO = ['zucchine', 'peperoni', 'carote', 'finocchi', 'cavolfiore', 'broccoli', 'cavolini', 'zucca',
         'funghi', 'carciofi', 'porri', 'radicchio', 'melanzane', 'pomodorini', 'fagiolini', 'asparagi']


TEMPLATES = [
    # --- Stufati e spezzatini ---------------------------------------------
    Template(
        key='s_spezzatino', type=MAIN,
        name='Spezzatino di {p.label} con patate e {v.label}',
        base={'f_patate': 220, 'f_carote': 50, 'f_cipolla': 40, 'f_sedano': 30, 'f_passata': 80,
              'f_brodo': 200, 'f_olio': 10, 'f_farina': 5, 'f_erbe': 2},
        slots={
            'p': [
                opt('manzo', 'manzo', {'f_spezzatino': 150}, 'manzo', stew=90),
                opt('vitello', 'vitello', {'f_vitello': 150}, 'manzo', stew=60),
                opt('maiale', 'maiale', {'f_lonza': 140}, 'maiale', stew=50),
                opt('tacchino', 'tacchino', {'f_tacchino': 150}, 'tacchino', stew=40),
            ],
            'v': veg(['piselli_freschi', 'funghi', 'porcini', 'carciofi', 'fagiolini', 'peperoni',
                      'zucca', 'verza'], scale=0.7),
        },
        steps=[
            'Trita cipolla, sedano e carota; pela le patate e tagliale a tocchi.',
            'Taglia la carne a cubotti di 3 cm e infarinala leggermente.',
            "In una casseruola scalda l'olio, rosola la carne a fuoco vivo per 5 minuti, poi aggiungi il trito "
            'e fallo appassire per 5 minuti.',
            'Unisci la passata, le erbe e il brodo caldo, copri e cuoci a fuoco basso per {p.stew} minuti.',
            '{v.cut}; aggiungi{v.pron} insieme alle patate negli ultimi 25 minuti e prosegui finché la carne è '
            'tenera e il sugo ristretto. Regola di sale e pepe.',
        ],
        fridge=4, freeze=True, minutes=100, tags=['stufato', 'piatto unico'], max=12,
    ),
    Template(
        key='s_gulasch', type=MAIN,
        name='Gulasch di {p.label} con {v.label} e {c.label}',
        base={'f_cipolla': 80, 'f_paprika': 5, 'f_cumino': 1, 'f_concentrato': 15, 'f_brodo': 250,
              'f_olio': 10, 'f_aglio': 3, 'f_farina': 5},
        slots={
            'p': [
                opt('manzo', 'manzo', {'f_spezzatino': 150}, 'manzo', stew=90),
                opt('maiale', 'maiale', {'f_lonza': 140}, 'maiale', stew=50),
            ],
            'v': veg(['peperoni', 'funghi', 'porcini', 'carote', 'cavolo_rosso', 'verza'], scale=0.7),
            'c': sides('polenta', 'pure', 'pane'),
        },
        steps=[
            "Affetta finemente le cipolle e falle appassire nell'olio a fuoco dolce per 10 minuti.",
            'Taglia la carne a cubotti, infarinala e rosolala con le cipolle per 5 minuti; aggiungi aglio '
            'tritato, paprika, cumino e concentrato e mescola per 1 minuto.',
            'Bagna con il brodo caldo, copri e cuoci a fuoco basso per {p.stew} minuti.',
            '{v.cut}; aggiungi{v.pron} al gulasch negli ultimi 20 minuti e lascia restringere il sugo.',
            '{c.cook}.',
            'Servi il gulasch con {c.the}.',
        ],
        fridge=4, freeze=True, minutes=110, tags=['stufato', 'paprika'], max=8,
    ),
    Template(
        key='s_cacciatora', type=MAIN, protein='pollo',
        name='Pollo alla cacciatora con {v.label} e {c.label}',
        base={'f_cosce_pollo': 170, 'f_cipolla': 40, 'f_carote': 30, 'f_sedano': 30, 'f_aglio': 3,
              'f_pelati': 150, 'f_olive': 15, 'f_erbe': 2, 'f_olio': 10, 'f_brodo': 100},
        slots={
            'v': veg(['peperoni', 'funghi', 'porcini', 'carciofi'], scale=0.7),
            'c': sides('polenta', 'pure', 'pane', 'patate'),
        },
        steps=[
            "Elimina il grasso visibile dalle sovracosce e rosolale nell'olio in una casseruola per 6 minuti, "
            'finché sono dorate.',
            'Aggiungi cipolla, carota, sedano e aglio tritati e le erbe e fai appassire per 5 minuti.',
            '{v.cut}; unisci{v.pron} al pollo con i pelati schiacciati, le olive e il brodo.',
            'Copri e cuoci a fuoco dolce per 35 minuti, finché il sugo è denso.',
            '{c.cook}.',
            'Servi il pollo con il suo sugo e {c.the}.',
        ],
        fridge=4, freeze=True, minutes=60, tags=['stufato'], max=8,
    ),
    Template(
        key='s_tajine', type=MAIN,
        name='Tajine di {p.label} con {v.label} e {c.label}',
        base={'f_cipolla': 50, 'f_aglio': 3, 'f_zenzero': 3, 'f_cumino': 2, 'f_cannella': 1, 'f_curcuma': 1,
              'f_passata': 60, 'f_brodo': 200, 'f_olive': 15, 'f_ceci': 60, 'f_albicocche_secche': 15,
              'f_limone': 10, 'f_prezzemolo': 5, 'f_olio': 10},
        slots={
            'p': [
                opt('pollo', 'pollo', {'f_cosce_pollo': 150}, 'pollo', taj=35),
                opt('tacchino', 'tacchino', {'f_tacchino': 140}, 'tacchino', taj=25),
                opt('manzo', 'manzo', {'f_spezzatino': 140}, 'manzo', taj=80),
            ],
            'v': veg(['zucca', 'carote', 'zucchine', 'melanzane', 'patate_dolci', 'finocchi', 'peperoni',
                      'carciofi', 'cavolfiore'], scale=0.9),
            'c': sides('couscous', 'bulgur'),
        },
        steps=[
            "Taglia la carne a pezzi di 4 cm e rosolala nell'olio in una casseruola (o nel tajine) per 5 minuti.",
            'Aggiungi la cipolla affettata, aglio e zenzero tritati, cumino, cannella e curcuma e fai insaporire '
            'per 3 minuti.',
            'Unisci la passata e il brodo caldo, copri e cuoci a fuoco basso per {p.taj} minuti.',
            '{v.cut}; aggiungi{v.pron} con i ceci sciacquati, le albicocche secche a pezzetti e le olive e '
            'prosegui per {v.saute} minuti.',
            '{c.cook}.',
            'Completa il tajine con prezzemolo tritato e succo di limone e servilo con {c.the}.',
        ],
        fridge=4, freeze=True, minutes=70, tags=['spezie', 'stufato'], max=10,
    ),
    Template(
        key='s_curry', type=MAIN,
        name='Curry di {p.label} con {v.label} e {c.label}',
        base={'f_latte_cocco': 80, 'f_curry': 4, 'f_cipolla': 40, 'f_aglio': 3, 'f_zenzero': 5,
              'f_passata': 60, 'f_olio': 8},
        slots={
            'p': [
                opt('pollo', 'pollo', {'f_pollo': 140}, 'pollo', cut='taglia il pollo a bocconcini', pan=8,
                    pron='lo'),
                opt('sovracosce', 'sovracosce di pollo', {'f_cosce_pollo': 150}, 'pollo',
                    cut='taglia le sovracosce a pezzi', pan=14, pron='le'),
                opt('tacchino', 'tacchino', {'f_tacchino': 140}, 'tacchino',
                    cut='taglia il tacchino a bocconcini', pan=8, pron='lo'),
                opt('manzo', 'manzo', {'f_manzo': 130}, 'manzo',
                    cut='taglia il manzo a cubetti piccoli', pan=10, pron='lo'),
                opt('maiale', 'maiale', {'f_lonza': 130}, 'maiale',
                    cut='taglia la lonza di maiale a bocconcini', pan=10, pron='la'),
            ],
            'v': veg(['cavolfiore', 'zucca', 'spinaci', 'peperoni', 'piselli_freschi', 'patate_dolci',
                      'melanzane', 'broccoli', 'zucchine', 'carote'], scale=0.9),
            'c': sides('riso', 'riso_int'),
        },
        steps=[
            '{c.cook}.',
            "Trita cipolla, aglio e zenzero e falli appassire nell'olio per 4 minuti; aggiungi il curry e "
            'tostalo per 1 minuto.',
            '{v.cut}; aggiungi{v.pron} al soffritto con la passata e il latte di cocco, copri e cuoci a fuoco '
            'medio per {v.saute} minuti.',
            '{p.cut}, unisci{p.pron} al curry e cuoci per altri {p.pan} minuti, finché il sugo è denso.',
            'Servi il curry con {c.the}.',
        ],
        fridge=4, freeze=True, minutes=40, tags=['curry', 'spezie'], max=12,
    ),
    Template(
        key='s_chili', type=MAIN,
        name='Chili di {p.label} con {v.label} e {c.label}',
        base={'f_pelati': 150, 'f_fagioli_neri': 120, 'f_mais': 30, 'f_cipolla': 40, 'f_aglio': 3,
              'f_cumino': 2, 'f_paprika': 2, 'f_spezie': 1, 'f_olio': 8},
        slots={
            'p': [
                opt('manzo', 'manzo', {'f_macinato': 120}, 'manzo'),
                opt('tacchino', 'pollo e tacchino', {'f_macinato_pollo': 130}, 'tacchino'),
            ],
            'v': veg(['peperoni', 'zucchine', 'zucca', 'funghi', 'carote'], scale=0.6),
            'c': [
                _SIDES['riso'], _SIDES['riso_int'],
                opt('patate_dolci', 'patate dolci al forno', {'f_patate_dolci': 220}, the='le patate dolci',
                    cook="taglia le patate dolci a cubotti, condiscile con un filo d'olio e cuocile in forno a "
                         '200 °C per 30 minuti'),
            ],
        },
        exclude=lambda c: c['v'].key == 'zucca' and c['c'].key == 'patate_dolci',
        steps=[
            "Trita cipolla e aglio e falli appassire nell'olio per 4 minuti.",
            'Aggiungi il macinato e rosolalo a fuoco vivo per 5 minuti sgranandolo, poi unisci cumino, paprika '
            'e peperoncino.',
            '{v.cut}; unisci{v.pron} al macinato con i pelati schiacciati, copri e cuoci a fuoco basso per '
            '25 minuti.',
            'Aggiungi i fagioli neri sciacquati e il mais e prosegui per 10 minuti senza coperchio, finché il '
            'chili è denso.',
            '{c.cook}.',
            'Servi il chili con {c.the}.',
        ],
        fridge=4, freeze=True, minutes=55, tags=['spezie', 'piatto unico'], max=10,
    ),

    # --- Polpette, burger e polpettone -------------------------------------
    Template(
        key='s_polpette', type=MAIN,
        name='Polpette di {p.label} al sugo con {c.label} e {v.label}',
        base={'f_pangrattato': 15, 'f_uova': 20, 'f_parmigiano': 10, 'f_prezzemolo': 5, 'f_passata': 160,
              'f_cipolla': 30, 'f_aglio': 3, 'f_basilico': 3, 'f_olio': 10},
        slots={
            'p': [
                opt('manzo', 'manzo', {'f_macinato': 140}, 'manzo', mix='il macinato di manzo'),
                opt('pollo', 'pollo e tacchino', {'f_macinato_pollo': 150}, 'pollo',
                    mix='il macinato di pollo e tacchino'),
                opt('vitello', 'vitello', {'f_vitello': 150}, 'manzo',
                    mix='la fesa di vitello tritata finemente'),
            ],
            'c': sides('polenta', 'pure', 'pane', 'riso'),
            'v': veg(['spinaci', 'bietole', 'cime_rapa', 'broccoli', 'fagiolini', 'zucchine', 'cavolo_nero',
                      'piselli_freschi', 'carciofi']),
        },
        steps=[
            'Impasta {p.mix} con uovo, pangrattato, parmigiano e prezzemolo tritato e forma polpette di circa '
            '30 g.',
            "In una casseruola fai appassire la cipolla tritata con metà dell'olio per 3 minuti, aggiungi la "
            "passata e mezzo bicchiere d'acqua e porta a bollore.",
            'Adagia le polpette nel sugo, copri e cuoci a fuoco dolce per 20 minuti girandole a metà cottura; '
            'completa con il basilico.',
            '{c.cook}.',
            "{v.cut}; salta{v.pron} in padella con l'olio rimasto e l'aglio per {v.saute} minuti.",
            'Servi le polpette con il sugo, {c.the} e {v.the}.',
        ],
        fridge=4, freeze=True, minutes=50, tags=['polpette'], max=12,
    ),
    Template(
        key='s_polpette_pesce', type=MAIN, protein='pesce',
        name='Polpette di {p.label} al sugo con {c.label} e {v.label}',
        base={'f_patate': 80, 'f_pangrattato': 15, 'f_uova': 20, 'f_prezzemolo': 5, 'f_limone': 5,
              'f_passata': 150, 'f_cipolla': 20, 'f_aglio': 3, 'f_basilico': 3, 'f_olio': 10},
        slots={
            'p': [
                opt('merluzzo', 'merluzzo', {'f_merluzzo': 180}, the='il merluzzo'),
                opt('salmone', 'salmone', {'f_salmone': 120}, the='il salmone spellato'),
                opt('pesce_spada', 'pesce spada', {'f_pesce_spada': 160}, the='il pesce spada'),
            ],
            'c': sides('riso', 'couscous', 'pane'),
            'v': veg(['spinaci', 'bietole', 'fagiolini', 'zucchine', 'broccoli', 'piselli_freschi',
                      'finocchi', 'asparagi']),
        },
        steps=[
            'Lessa le patate per 20 minuti e schiacciale.',
            'Trita al coltello {p.the} e impastalo con le patate, uovo, pangrattato, prezzemolo e scorza di '
            'limone; forma polpette di circa 30 g.',
            "In una casseruola fai appassire la cipolla tritata con metà dell'olio, aggiungi la passata e "
            'cuoci 5 minuti; adagia le polpette nel sugo e cuoci coperto a fuoco dolce per 12 minuti.',
            '{c.cook}.',
            "{v.cut}; salta{v.pron} in padella con l'olio rimasto e l'aglio per {v.saute} minuti.",
            'Completa le polpette con il basilico e servile con {c.the} e {v.the}.',
        ],
        fridge=2, freeze=True, minutes=50, tags=['polpette'], max=6,
    ),
    Template(
        key='s_burger', type=MAIN,
        name='Burger di {p.label} con {v.label} alla piastra e {c.label}',
        base={'f_pangrattato': 10, 'f_erbe': 2, 'f_olio': 8, 'f_yogurt_greco': 40, 'f_senape': 5,
              'f_insalata': 30},
        slots={
            'p': [
                opt('manzo', 'manzo', {'f_macinato': 150}, 'manzo', mix='il macinato di manzo',
                    grill='4 minuti per lato'),
                opt('pollo', 'pollo e tacchino', {'f_macinato_pollo': 150}, 'pollo',
                    mix='il macinato di pollo e tacchino', grill='6 minuti per lato, finché è cotto al cuore'),
                opt('vitello', 'vitello', {'f_vitello': 150}, 'manzo',
                    mix='la fesa di vitello tritata', grill='4 minuti per lato'),
            ],
            'v': veg(GRILL, scale=0.9),
            'c': sides('pane', 'patate'),
        },
        steps=[
            '{c.cook}.',
            'Impasta {p.mix} con pangrattato, erbe tritate, sale e pepe e forma un burger alto 2 cm; fallo '
            'riposare in frigo per 15 minuti.',
            "{v.cut}; cuoci{v.pron} su una piastra rovente con metà dell'olio per {v.saute} minuti, "
            'girando{v.pron} a metà cottura.',
            "Spennella il burger con l'olio rimasto e cuocilo sulla stessa piastra per {p.grill}.",
            'Mescola lo yogurt greco con la senape e servi il burger con la salsa, le verdure, l\'insalata e '
            '{c.the}.',
        ],
        fridge=3, freeze=True, minutes=40, tags=['burger'], max=10,
    ),
    Template(
        key='s_polpettone', type=MAIN,
        name='Polpettone di {p.label} al forno con patate e {v.label}',
        base={'f_patate': 230, 'f_uova': 25, 'f_pangrattato': 15, 'f_parmigiano': 10, 'f_latte': 20,
              'f_prezzemolo': 5, 'f_olio': 10, 'f_erbe': 2, 'f_aglio': 3},
        slots={
            'p': [
                opt('manzo', 'manzo', {'f_macinato': 140}, 'manzo', mix='il macinato di manzo'),
                opt('pollo', 'pollo e tacchino', {'f_macinato_pollo': 150}, 'pollo',
                    mix='il macinato di pollo e tacchino'),
            ],
            'v': veg([k for k in FORNO if k not in ('radicchio', 'pomodorini')]),
        },
        steps=[
            'Scalda il forno a 180 °C.',
            'Impasta {p.mix} con uovo, pangrattato ammollato nel latte, parmigiano e prezzemolo tritato; forma '
            'un filone compatto e avvolgilo in carta forno.',
            "Pela le patate e tagliale a spicchi; mettile in teglia con il polpettone e condiscile con metà "
            "dell'olio, l'aglio e le erbe. Cuoci per 50 minuti, aprendo la carta forno dopo 30 minuti perché "
            'il polpettone si dori.',
            "{v.cut}; condisci{v.pron} con l'olio rimasto, sale e pepe e aggiungi{v.pron} alla teglia negli "
            'ultimi {v.roast} minuti.',
            'Lascia riposare il polpettone 10 minuti prima di affettarlo e servilo con patate e verdure.',
        ],
        fridge=4, freeze=True, minutes=75, tags=['forno'], max=10,
    ),

    # --- Carne in padella e al forno --------------------------------------
    Template(
        key='s_involtini', type=MAIN,
        name='Involtini di {p.label} ripieni di {f.label} con {c.label}',
        base={'f_olio': 10, 'f_brodo': 100, 'f_erbe': 2, 'f_insalata': 80, 'f_limone': 5},
        slots={
            'p': [
                opt('pollo', 'pollo', {'f_pollo': 140}, 'pollo', inv=12),
                opt('tacchino', 'tacchino', {'f_tacchino': 140}, 'tacchino', inv=12),
                opt('vitello', 'vitello', {'f_vitello': 140}, 'manzo', inv=10),
                opt('maiale', 'maiale', {'f_lonza': 130}, 'maiale', inv=15),
            ],
            'f': [
                opt('spinaci', 'spinaci e parmigiano', {'f_spinaci': 80, 'f_parmigiano': 10},
                    prep='sbollenta gli spinaci per 2 minuti, strizzali bene e tritali con il parmigiano'),
                opt('zucchine', 'zucchine e scamorza', {'f_zucchine': 80, 'f_scamorza': 20},
                    prep='grattugia le zucchine, strizzale e taglia la scamorza a bastoncini'),
                opt('asparagi', 'asparagi e prosciutto cotto', {'f_asparagi': 80, 'f_prosciutto_cotto': 20},
                    prep='elimina la parte legnosa degli asparagi e sbollentali per 4 minuti'),
                opt('radicchio', 'radicchio e speck', {'f_radicchio': 70, 'f_speck': 15},
                    prep='affetta il radicchio e fallo appassire in padella per 3 minuti'),
                opt('funghi', 'funghi e scamorza', {'f_funghi': 90, 'f_scamorza': 20},
                    prep='affetta i funghi, trifolali in padella per 5 minuti e taglia la scamorza a bastoncini'),
                opt('carciofi', 'carciofi e parmigiano', {'f_carciofi': 80, 'f_parmigiano': 10},
                    prep='pulisci i carciofi, affettali sottili e saltali in padella con un goccio d\'acqua per '
                         '8 minuti'),
            ],
            'c': sides('polenta', 'pure', 'patate'),
        },
        steps=[
            '{f.prep}.',
            'Batti le fettine di {p.label} fino a 3-4 mm di spessore, farciscile con il ripieno, arrotolale e '
            'fermale con uno stecchino.',
            '{c.cook}.',
            "Rosola gli involtini in padella con l'olio e la salvia per 5 minuti, poi bagna con il brodo, copri "
            'e cuoci per {p.inv} minuti.',
            "Servi gli involtini con il fondo di cottura ristretto, {c.the} e l'insalata mista condita con "
            'succo di limone.',
        ],
        fridge=3, freeze=True, minutes=50, tags=['involtini'], max=10,
    ),
    Template(
        key='s_arrosto', type=MAIN,
        name='{p.title} con patate e {v.label} al forno',
        base={'f_patate': 220, 'f_olio': 10, 'f_aglio': 4, 'f_erbe': 3, 'f_brodo': 80},
        slots={
            'p': [
                opt('maiale', 'arista', {'f_lonza': 150}, 'maiale', title='Arista di maiale',
                    the="l'arista", pron='la', roast=55, carve='poi affettala e'),
                opt('tacchino', 'tacchino', {'f_tacchino': 160}, 'tacchino', title='Arrosto di tacchino',
                    the='la fesa di tacchino', pron='la', roast=45, carve='poi affettala e'),
                opt('vitello', 'vitello', {'f_vitello': 160}, 'manzo', title='Arrosto di vitello',
                    the='il girello di vitello', pron='lo', roast=45, carve='poi affettalo e'),
                opt('pollo', 'pollo', {'f_cosce_pollo': 170}, 'pollo', title='Sovracosce di pollo arrosto',
                    the='le sovracosce', pron='le', roast=40, carve='poi'),
            ],
            'v': veg(FORNO),
        },
        steps=[
            "Scalda il forno a 190 °C. Massaggia {p.the} con metà dell'olio, l'aglio schiacciato, le erbe "
            'tritate, sale e pepe.',
            'Rosola{p.pron} in padella su tutti i lati per 5 minuti.',
            'Pela le patate, tagliale a spicchi e disponile in teglia intorno alla carne; bagna con il brodo e '
            'cuoci in forno per {p.roast} minuti.',
            "{v.cut}; condisci{v.pron} con l'olio rimasto e aggiungi{v.pron} alla teglia negli ultimi "
            '{v.roast} minuti.',
            'Fai riposare la carne 10 minuti, {p.carve} servi{p.pron} con il fondo di cottura, le '
            'patate e le verdure.',
        ],
        fridge=4, freeze=True, minutes=75, tags=['forno', 'arrosto'], max=12,
    ),
    Template(
        key='s_straccetti', type=MAIN,
        name='Straccetti di {p.label} con {v.label} in padella e {c.label}',
        base={'f_olio': 10, 'f_aglio': 3, 'f_erbe': 2, 'f_aceto': 5, 'f_farina': 5, 'f_brodo': 50},
        slots={
            'p': [
                opt('manzo', 'manzo', {'f_manzo': 140}, 'manzo', pan=3),
                opt('pollo', 'pollo', {'f_pollo': 140}, 'pollo', pan=6),
                opt('tacchino', 'tacchino', {'f_tacchino': 140}, 'tacchino', pan=6),
                opt('vitello', 'vitello', {'f_vitello': 140}, 'manzo', pan=4),
                opt('maiale', 'maiale', {'f_lonza': 130}, 'maiale', pan=5),
            ],
            'v': veg(['zucchine', 'peperoni', 'funghi', 'carciofi', 'asparagi', 'radicchio', 'spinaci',
                      'cime_rapa', 'cavolo_nero', 'broccoli', 'fagiolini', 'porri', 'zucca', 'porcini']),
            'c': sides('patate', 'riso', 'farro', 'pane'),
        },
        steps=[
            '{c.cook}.',
            "{v.cut}; salta{v.pron} in padella con metà dell'olio e l'aglio per {v.saute} minuti, poi "
            'tieni{v.pron} da parte.',
            'Taglia la carne a straccetti sottili e infarinala leggermente.',
            "Nella stessa padella scalda l'olio rimasto con il rosmarino, cuoci gli straccetti a fuoco vivo per "
            '{p.pan} minuti, poi sfuma con il brodo e l\'aceto balsamico e lascia restringere.',
            'Rimetti le verdure in padella, mescola per 1 minuto e servi con {c.the}.',
        ],
        fridge=3, minutes=30, tags=['padella'], max=14,
    ),
    Template(
        key='s_scaloppine', type=MAIN,
        name='Scaloppine di {p.label} {s.label} con {v.label} e {c.label}',
        base={'f_farina': 8, 'f_olio': 10, 'f_aglio': 3, 'f_brodo': 50},
        slots={
            'p': [
                opt('pollo', 'pollo', {'f_pollo': 140}, 'pollo', side=3),
                opt('tacchino', 'tacchino', {'f_tacchino': 140}, 'tacchino', side=3),
                opt('vitello', 'vitello', {'f_vitello': 140}, 'manzo', side=2),
                opt('maiale', 'maiale', {'f_lonza': 130}, 'maiale', side=3),
            ],
            's': [
                opt('limone', 'al limone', {'f_limone': 25, 'f_prezzemolo': 3},
                    sauce='sfuma con il succo di limone e il brodo e lascia addensare il fondo per 1 minuto; '
                          'completa con prezzemolo tritato'),
                opt('pizzaiola', 'alla pizzaiola', {'f_passata': 100, 'f_capperi': 5, 'f_spezie': 1},
                    sauce='aggiungi la passata, i capperi, l\'origano e il brodo e cuoci 6 minuti girando le '
                          'scaloppine nel sugo'),
                opt('balsamico', "all'aceto balsamico", {'f_aceto': 15, 'f_erbe': 2},
                    sauce="sfuma con l'aceto balsamico e il brodo, aggiungi il rosmarino e fai glassare per "
                          '2 minuti'),
                opt('senape', 'alla senape', {'f_senape': 12, 'f_latte': 40},
                    sauce='unisci la senape stemperata nel latte e nel brodo e cuoci 2 minuti, finché la salsa '
                          'si addensa'),
            ],
            'v': veg(['spinaci', 'bietole', 'cime_rapa', 'broccoli', 'fagiolini', 'zucchine', 'asparagi',
                      'carciofi', 'funghi', 'finocchi', 'piselli_freschi', 'cavolo_nero', 'radicchio']),
            'c': sides('pure', 'patate', 'riso', 'pane'),
        },
        steps=[
            '{c.cook}.',
            "{v.cut}; salta{v.pron} in padella con un filo d'olio e l'aglio per {v.saute} minuti.",
            'Batti le fettine di {p.label} fino a renderle sottili e infarinale leggermente.',
            "Rosola le scaloppine nell'olio rimasto per {p.side} minuti per lato.",
            '{s.sauce}.',
            'Servi le scaloppine con la salsa, {v.the} e {c.the}.',
        ],
        fridge=3, minutes=30, tags=['padella'], max=12,
    ),
    Template(
        key='s_wok', type=MAIN,
        name='Wok di {p.label} con {v.label} e {c.label}',
        base={'f_soia': 15, 'f_zenzero': 5, 'f_aglio': 3, 'f_cipolla': 30, 'f_olio': 10, 'f_sesamo': 5},
        slots={
            'p': [
                opt('pollo', 'pollo', {'f_pollo': 140}, 'pollo', the='il pollo', pron='lo',
                    cut='taglia il pollo a listarelle', pan=6),
                opt('manzo', 'manzo', {'f_manzo': 130}, 'manzo', the='il manzo', pron='lo',
                    cut='taglia il manzo a straccetti sottili', pan=3),
                opt('maiale', 'maiale', {'f_lonza': 130}, 'maiale', the='il maiale', pron='lo',
                    cut='taglia la lonza di maiale a listarelle', pan=6),
                opt('tacchino', 'tacchino', {'f_tacchino': 140}, 'tacchino', the='il tacchino', pron='lo',
                    cut='taglia il tacchino a straccetti', pan=5),
            ],
            'v': veg(['zucchine', 'peperoni', 'broccoli', 'carote', 'cavolo_rosso', 'verza', 'funghi',
                      'fagiolini', 'asparagi', 'porri', 'cavolfiore']),
            'c': sides('riso', 'riso_venere', 'noodles'),
        },
        steps=[
            '{c.cook}.',
            '{p.cut} e marina{p.pron} per 10 minuti con metà della salsa di soia e lo zenzero grattugiato.',
            "Scalda metà dell'olio nel wok a fuoco vivo, salta{p.pron} per {p.pan} minuti e tieni{p.pron} da "
            'parte.',
            "{v.cut}; salta{v.pron} nel wok con l'olio rimasto, l'aglio e la cipolla affettata per {v.saute} "
            'minuti a fuoco vivo.',
            'Rimetti {p.the} nel wok con la soia rimasta, salta per 1 minuto e completa con il sesamo; servi '
            'con {c.the}.',
        ],
        fridge=3, minutes=30, tags=['wok'], max=14,
    ),
    Template(
        key='s_wok_mare', type=MAIN, protein='pesce',
        name='Wok di {p.label} con {v.label} e {c.label}',
        base={'f_soia': 15, 'f_zenzero': 5, 'f_aglio': 3, 'f_cipolla': 30, 'f_olio': 10, 'f_limone': 10},
        slots={
            'p': [
                opt('gamberi', 'gamberi', {'f_gamberi': 170}, the='i gamberi', pron='li', pan=3,
                    cut='elimina il filo intestinale dai gamberi'),
                opt('calamari', 'calamari', {'f_calamari': 210}, the='i calamari', pron='li', pan=5,
                    cut='taglia i calamari ad anelli'),
                opt('misto', 'gamberi e calamari', {'f_gamberi': 90, 'f_calamari': 110}, the='il pesce',
                    pron='lo', pan=4, cut='elimina il filo intestinale dai gamberi e taglia i calamari ad anelli'),
            ],
            'v': veg(['zucchine', 'peperoni', 'broccoli', 'asparagi', 'fagiolini', 'piselli_freschi', 'carote',
                      'porri', 'verza']),
            'c': sides('riso', 'riso_venere', 'noodles'),
        },
        steps=[
            '{c.cook}.',
            "{v.cut}; salta{v.pron} nel wok con metà dell'olio, l'aglio, lo zenzero e la cipolla affettata "
            'per {v.saute} minuti a fuoco vivo, poi tieni{v.pron} da parte.',
            "{p.cut}; salta{p.pron} nel wok con l'olio rimasto per {p.pan} minuti.",
            'Rimetti le verdure nel wok, aggiungi la salsa di soia e il succo di limone e salta per 1 minuto; '
            'servi con {c.the}.',
        ],
        fridge=2, minutes=30, tags=['wok'], max=8,
    ),
    Template(
        key='s_fajitas', type=MAIN,
        name='Fajitas di {p.label} con {v.label} e fagioli neri',
        base={'f_tortilla': 124, 'f_cipolla': 50, 'f_fagioli_neri': 60, 'f_olio': 8, 'f_paprika': 2,
              'f_cumino': 1, 'f_limone': 10, 'f_yogurt_greco': 50, 'f_insalata': 30},
        slots={
            'p': [
                opt('pollo', 'pollo', {'f_pollo': 140}, 'pollo', pan=6),
                opt('manzo', 'manzo', {'f_manzo': 130}, 'manzo', pan=3),
                opt('tacchino', 'tacchino', {'f_tacchino': 140}, 'tacchino', pan=5),
                opt('maiale', 'maiale', {'f_lonza': 130}, 'maiale', pan=5),
            ],
            'v': veg(['peperoni', 'zucchine', 'funghi', 'cavolo_rosso', 'zucca'], scale=0.8),
        },
        steps=[
            'Taglia la carne a listarelle e condiscila con paprika, cumino, succo di limone, sale e pepe.',
            "Affetta la cipolla; {v.cut}. Salta le verdure in padella con metà dell'olio per {v.saute} minuti "
            'e tienile da parte.',
            "Nella stessa padella cuoci la carne a fuoco vivo con l'olio rimasto per {p.pan} minuti, poi "
            'unisci le verdure e i fagioli neri sciacquati e scalda per 2 minuti.',
            'Scalda le tortillas in padella per 30 secondi per lato.',
            'Farcisci le tortillas con il ripieno, l\'insalata e lo yogurt greco e arrotolale. Per il meal prep '
            'conserva il ripieno separato e farcisci al momento.',
        ],
        fridge=3, minutes=30, tags=['wrap'], max=8,
    ),
    Template(
        key='s_piadina', type=MAIN,
        name='Piadina con {p.label} alla piastra, {v.label} e formaggio fresco',
        base={'f_piadina': 100, 'f_spalmabile': 30, 'f_insalata': 20, 'f_olio': 6, 'f_erbe': 1},
        slots={
            'p': [
                opt('pollo', 'pollo', {'f_pollo': 120}, 'pollo', grill='5 minuti per lato'),
                opt('tacchino', 'tacchino', {'f_tacchino': 120}, 'tacchino', grill='4 minuti per lato'),
                opt('manzo', 'manzo', {'f_manzo': 110}, 'manzo', grill='2 minuti per lato'),
            ],
            'v': veg(['zucchine', 'melanzane', 'peperoni', 'radicchio', 'funghi', 'zucca'], scale=0.6),
        },
        steps=[
            "{v.cut}; cuoci{v.pron} su una piastra rovente con metà dell'olio per {v.saute} minuti.",
            "Batti la carne a fette sottili, spennellala con l'olio rimasto e le erbe tritate e cuocila sulla "
            'piastra per {p.grill}; tagliala a strisce.',
            'Scalda la piadina sulla piastra per 1 minuto per lato.',
            "Spalma il formaggio fresco sulla piadina, farciscila con la carne, le verdure e l'insalata e "
            'chiudila a metà. Per il meal prep conserva il ripieno a parte e farcisci al momento.',
        ],
        fridge=3, minutes=25, tags=['wrap'], max=8,
    ),

    # --- Pesce -------------------------------------------------------------
    Template(
        key='s_cartoccio', type=MAIN, protein='pesce',
        name='{p.label} al cartoccio con {v.label} e {c.label}',
        base={'f_olio': 10, 'f_limone': 15, 'f_aglio': 3, 'f_prezzemolo': 5, 'f_olive': 10},
        slots={
            'p': [
                opt('orata', 'Orata', {'f_orata': 170}, cart=18),
                opt('branzino', 'Branzino', {'f_branzino': 180}, cart=18),
                opt('merluzzo', 'Merluzzo', {'f_merluzzo': 200}, cart=15),
                opt('trota', 'Trota salmonata', {'f_trota': 170}, cart=15),
                opt('salmone', 'Salmone', {'f_salmone': 140}, cart=15),
                opt('pesce_spada', 'Pesce spada', {'f_pesce_spada': 170}, cart=12),
            ],
            'v': veg(['zucchine', 'pomodorini', 'finocchi', 'porri', 'carciofi', 'asparagi', 'peperoni'],
                     scale=0.9),
            'c': sides('riso_venere', 'farro', 'quinoa', 'couscous', 'patate'),
        },
        steps=[
            'Scalda il forno a 200 °C.',
            '{c.cook}.',
            "{v.cut}; condisci{v.pron} con metà dell'olio, l'aglio a fettine, sale e pepe.",
            'Disponi i filetti di pesce su un foglio di carta forno, aggiungi le verdure, le olive, qualche '
            "fetta di limone e il prezzemolo; irrora con l'olio rimasto e chiudi il cartoccio.",
            'Cuoci in forno per {p.cart} minuti, poi apri il cartoccio e lascia intiepidire.',
            'Servi il pesce con le verdure, il fondo di cottura e {c.the}. Per il meal prep conserva il pesce '
            'separato dal contorno.',
        ],
        fridge=2, minutes=35, tags=['forno'], max=14,
    ),
    Template(
        key='s_pesce_crosta', type=MAIN, protein='pesce',
        name='{p.label} in crosta di {k.label} con {v.label} al forno e {c.label}',
        base={'f_olio': 10, 'f_limone': 10},
        slots={
            'p': [
                opt('salmone', 'Salmone', {'f_salmone': 140}, oven=14),
                opt('merluzzo', 'Merluzzo', {'f_merluzzo': 200}, oven=12),
                opt('orata', 'Orata', {'f_orata': 170}, oven=12),
                opt('trota', 'Trota salmonata', {'f_trota': 170}, oven=12),
            ],
            'k': [
                opt('pistacchi', 'pistacchi', {'f_pistacchi': 12, 'f_pangrattato': 10},
                    step='trita grossolanamente i pistacchi e mescolali con il pangrattato'),
                opt('mandorle', 'mandorle', {'f_mandorle': 12, 'f_pangrattato': 10, 'f_erbe': 1},
                    step='trita le mandorle e mescolale con il pangrattato e il timo'),
                opt('erbe', 'erbe e parmigiano', {'f_pangrattato': 20, 'f_parmigiano': 8, 'f_prezzemolo': 5},
                    step='trita il prezzemolo e mescolalo con il pangrattato e il parmigiano'),
                opt('olive', 'olive', {'f_olive': 20, 'f_pangrattato': 15},
                    step='trita finemente le olive e mescolale con il pangrattato'),
            ],
            'v': veg(['zucchine', 'pomodorini', 'finocchi', 'cavolfiore', 'broccoli', 'cavolini', 'zucca',
                      'carote', 'asparagi', 'peperoni']),
            'c': sides('patate', 'quinoa', 'farro', 'riso_venere'),
        },
        steps=[
            'Scalda il forno a 200 °C.',
            '{c.cook}.',
            "{v.cut}; condisci{v.pron} con metà dell'olio, sale e pepe e cuoci{v.pron} in teglia per "
            '{v.roast} minuti.',
            '{k.step}.',
            "Spennella i filetti di pesce con l'olio rimasto, premi la panatura sulla superficie e cuocili in "
            'forno per {p.oven} minuti, finché la crosta è dorata.',
            'Servi il pesce con succo di limone, le verdure e {c.the}.',
        ],
        fridge=2, minutes=40, tags=['forno'], max=10,
    ),
    Template(
        key='s_pesce_estivo', type=MAIN, protein='pesce',
        name='{p.label} alla mediterranea con {v.label} e {c.label}',
        base={'f_pomodorini': 100, 'f_olive': 15, 'f_capperi': 5, 'f_spezie': 1, 'f_aglio': 3,
              'f_basilico': 3, 'f_olio': 10},
        slots={
            'p': [
                opt('sgombro', 'Sgombro', {'f_sgombro': 150}, pron='li', pan=6,
                    cut='sciacqua i filetti di sgombro ed elimina eventuali spine'),
                opt('alici', 'Alici', {'f_alici': 180}, pron='le', pan=4,
                    cut='apri le alici a libro eliminando testa e lisca'),
                opt('pesce_spada', 'Pesce spada', {'f_pesce_spada': 160}, pron='lo', pan=5,
                    cut='taglia il pesce spada a tranci di 2 cm'),
                opt('tonno', 'Tonno fresco', {'f_tonno_fresco': 140}, pron='lo', pan=4,
                    cut='taglia il tonno a tranci di 2 cm'),
            ],
            'v': veg(['zucchine', 'melanzane', 'peperoni', 'fagiolini']),
            'c': sides('couscous', 'bulgur', 'farro', 'quinoa', 'patate'),
        },
        steps=[
            '{c.cook}.',
            "{v.cut}; salta{v.pron} in padella con metà dell'olio e l'aglio per {v.saute} minuti, poi "
            'tieni{v.pron} da parte.',
            "Nella stessa padella scalda l'olio rimasto, aggiungi i pomodorini tagliati a metà, le olive e i "
            'capperi e cuoci per 5 minuti.',
            '{p.cut}; adagia{p.pron} nel sughetto, cospargi di origano e cuoci coperto per {p.pan} minuti.',
            'Unisci le verdure, completa con il basilico e servi con {c.the}.',
        ],
        fridge=2, minutes=35, tags=['estate'], max=10,
    ),
    Template(
        key='s_umido_merluzzo', type=MAIN, protein='pesce',
        name='{p.label} in umido con {v.label} e {c.label}',
        base={'f_pelati': 150, 'f_cipolla': 40, 'f_aglio': 3, 'f_olive': 15, 'f_capperi': 5,
              'f_prezzemolo': 5, 'f_olio': 10},
        slots={
            'p': [
                opt('baccala', 'Baccalà', {'f_baccala': 180}, the='il baccalà ammollato'),
                opt('merluzzo', 'Merluzzo', {'f_merluzzo': 200}, the='il merluzzo'),
            ],
            'v': veg(['peperoni', 'carciofi', 'porri', 'piselli_freschi', 'bietole', 'zucchine'], scale=0.7),
            'c': [
                _SIDES['polenta'],
                opt('pane', 'pane tostato', {'f_pane_int': 90}, the='il pane tostato',
                    cook='taglia il pane a fette e tostalo in forno al momento di servire'),
                opt('patate', 'patate', {'f_patate': 250}, the='le patate',
                    cook='pela le patate, tagliale a tocchetti e cuocile nel sugo coperto per 15 minuti'),
            ],
        },
        steps=[
            "Soffriggi cipolla e aglio tritati nell'olio per 4 minuti, aggiungi i pelati schiacciati, le olive "
            'e i capperi e cuoci per 10 minuti.',
            '{c.cook}.',
            '{v.cut}; aggiungi{v.pron} al sugo e cuoci per {v.saute} minuti.',
            'Taglia a tranci {p.the}, adagia i tranci nel sugo, copri e cuoci a fuoco dolce per 10 minuti '
            'senza mescolare.',
            'Completa con prezzemolo tritato e servi con {c.the}.',
        ],
        fridge=2, freeze=True, minutes=45, tags=['umido'], max=10,
    ),
    Template(
        key='s_polpo_patate', type=MAIN, protein='pesce',
        name='Insalata tiepida di polpo e patate con {v.label}',
        base={'f_polpo': 260, 'f_patate': 250, 'f_olio': 12, 'f_limone': 20, 'f_aglio': 2,
              'f_prezzemolo': 8},
        slots={
            'v': [
                opt('fagiolini', 'fagiolini', {'f_fagiolini': 120}, ai='ai fagiolini',
                    prep='spunta i fagiolini e lessali per 8 minuti'),
                opt('pomodorini', 'pomodorini', {'f_pomodorini': 120}, ai='ai pomodorini',
                    prep='taglia i pomodorini a metà'),
                opt('finocchi', 'finocchi', {'f_finocchi': 120}, ai='ai finocchi',
                    prep='affetta sottilmente i finocchi'),
                opt('rucola', 'rucola', {'f_rucola': 50}, ai='alla rucola', prep='lava e asciuga la rucola'),
                opt('sedano', 'sedano e olive', {'f_sedano': 80, 'f_olive': 15}, ai='al sedano e alle olive',
                    prep='affetta il sedano a rondelle sottili'),
            ],
        },
        steps=[
            'Immergi il polpo in acqua bollente per tre volte, poi cuocilo coperto a fuoco dolce per 45 minuti '
            'e lascialo intiepidire nella sua acqua.',
            'Lessa le patate con la buccia per 25 minuti, pelale e tagliale a tocchetti.',
            '{v.prep}.',
            'Taglia il polpo a pezzi e uniscilo alle patate e {v.ai}.',
            "Condisci con l'olio, il succo di limone, l'aglio e il prezzemolo tritati. Si mangia tiepida o fredda.",
        ],
        fridge=2, minutes=70, tags=['insalata'], max=5,
    ),
    Template(
        key='s_calamari_umido', type=MAIN, protein='pesce',
        name='Calamari in umido con {v.label} e {c.label}',
        base={'f_calamari': 220, 'f_pelati': 120, 'f_cipolla': 30, 'f_aglio': 3, 'f_olio': 10,
              'f_prezzemolo': 5},
        slots={
            'v': veg(['piselli_freschi', 'carciofi', 'zucchine', 'peperoni', 'bietole', 'fagiolini'], scale=0.8),
            'c': sides('riso', 'couscous', 'pane', 'polenta'),
        },
        steps=[
            'Taglia i calamari ad anelli e i ciuffi a pezzi.',
            "Soffriggi aglio e cipolla tritati nell'olio per 3 minuti, aggiungi i calamari e rosolali per "
            '3 minuti.',
            "Unisci i pelati schiacciati e mezzo bicchiere d'acqua, copri e cuoci a fuoco dolce per 25 minuti.",
            '{v.cut}; unisci{v.pron} ai calamari e prosegui per {v.saute} minuti.',
            '{c.cook}.',
            'Completa con prezzemolo tritato e servi con {c.the}.',
        ],
        fridge=2, freeze=True, minutes=50, tags=['umido'], max=8,
    ),
    Template(
        key='s_calamari_ripieni', type=MAIN, protein='pesce',
        name='Calamari ripieni al sugo con {v.label} e {c.label}',
        base={'f_calamari': 230, 'f_pangrattato': 20, 'f_uova': 15, 'f_pecorino': 8, 'f_prezzemolo': 5,
              'f_aglio': 3, 'f_passata': 130, 'f_olio': 10},
        slots={
            'v': veg(['spinaci', 'bietole', 'zucchine', 'fagiolini', 'broccoli', 'cime_rapa', 'carciofi',
                      'asparagi']),
            'c': sides('pane', 'patate', 'riso'),
        },
        steps=[
            'Separa i ciuffi dai calamari e tritali; mescolali con pangrattato, uovo, pecorino, prezzemolo e '
            "metà dell'aglio.",
            'Riempi le sacche dei calamari per due terzi e chiudile con uno stecchino.',
            "Rosola i calamari in una casseruola con metà dell'olio per 3 minuti, aggiungi la passata, copri e "
            'cuoci a fuoco dolce per 30 minuti.',
            '{c.cook}.',
            "{v.cut}; salta{v.pron} in padella con l'olio e l'aglio rimasti per {v.saute} minuti.",
            'Servi i calamari a fette con il sugo, {v.the} e {c.the}.',
        ],
        fridge=2, minutes=60, tags=['ripieni'], max=8,
    ),
    Template(
        key='s_zuppa_cozze', type=MAIN, protein='pesce',
        name='Zuppa di cozze e {l.label} con {v.label} e crostini',
        base={'f_cozze': 200, 'f_pane_int': 60, 'f_passata': 80, 'f_brodo': 150, 'f_aglio': 4,
              'f_spezie': 1, 'f_prezzemolo': 5, 'f_olio': 10},
        slots={
            'l': [
                opt('cannellini', 'cannellini', {'f_cannellini': 100}, the='i cannellini'),
                opt('ceci', 'ceci', {'f_ceci': 100}, the='i ceci'),
                opt('borlotti', 'borlotti', {'f_fagioli': 100}, the='i borlotti'),
            ],
            'v': veg(['pomodorini', 'zucchine', 'bietole', 'spinaci', 'cime_rapa'], scale=0.6),
        },
        steps=[
            "Se usi cozze fresche, falle aprire in padella coperta per 4 minuti, sgusciale e filtra il liquido "
            'da aggiungere al brodo.',
            "Soffriggi l'aglio e il peperoncino nell'olio per 1 minuto.",
            '{v.cut}; aggiungi{v.pron} con la passata e il brodo e cuoci per {v.saute} minuti.',
            'Unisci {l.the} sciacquati e prosegui per 5 minuti, schiacciandone una parte per addensare la '
            'zuppa.',
            'Aggiungi le cozze e scaldale per 2 minuti; completa con il prezzemolo e servi con il pane tostato.',
        ],
        fridge=2, minutes=30, tags=['zuppa'], max=8,
    ),
]
