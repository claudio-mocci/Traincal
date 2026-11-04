"""Piatti unici vegetariani e vegani: zuppe di legumi e cereali, vellutate,
dal e curry, chili, burger e polpette di legumi, frittate, torte salate,
tofu/tempeh/seitan, farinata, polenta e insalate tiepide."""

from engine import MAIN, Template, opt
from lib import carb, prot, veg

# --- Legumi -----------------------------------------------------------------

_LEG = {
    'ceci': dict(id='f_ceci', label='ceci', the='i ceci', pron='li', end='i'),
    'cannellini': dict(id='f_cannellini', label='fagioli cannellini', the='i cannellini', pron='li', end='i'),
    'borlotti': dict(id='f_fagioli', label='fagioli borlotti', the='i borlotti', pron='li', end='i'),
    'neri': dict(id='f_fagioli_neri', label='fagioli neri', the='i fagioli neri', pron='li', end='i'),
    'lenticchie': dict(id='f_lenticchie', label='lenticchie', the='le lenticchie', pron='le', end='e',
                       dry=True),
}


def leg(keys, g=220, dry=70):
    """Legumi in scatola (grammi sgocciolati) o lenticchie secche."""
    out = []
    for k in keys:
        o = _LEG[k]
        the, pron = o['the'], o['pron']
        if o.get('dry'):
            prep = 'sciacqua le lenticchie, lessale in acqua non salata per 20-25 minuti e scolale bene'
            warm = 'lessa le lenticchie in acqua salata per 20-25 minuti, tenendole al dente, e scolale'
            stew = ('sciacqua le lenticchie, uniscile al soffritto con la passata e 300 ml di acqua '
                    'e cuoci a fuoco basso per 30 minuti, finché sono tenere')
            grams = dry
        else:
            prep = f'sciacqua e sgocciola {the}'
            warm = f"sciacqua e sgocciola {the} e scalda{pron} 2 minuti in padella con un cucchiaio d'acqua"
            stew = (f"sciacqua e sgocciola {the}, unisci{pron} al soffritto con la passata e mezzo "
                    "bicchiere d'acqua e cuoci a fuoco basso per 15 minuti")
            grams = g
        out.append(opt(k, o['label'], {o['id']: grams}, 'legumi', the=the, pron=pron, end=o['end'],
                       prep=prep, warm=warm, stew=stew))
    return out


# Cereali da cuocere direttamente nella zuppa (minuti di cottura in brodo).
def soup_grain(keys, g=60):
    lib = {
        'orzo': ('orzo', 'f_orzo', "l'orzo perlato", 25),
        'farro': ('farro', 'f_farro', 'il farro perlato', 20),
        'riso': ('riso', 'f_riso_carnaroli', 'il riso', 15),
        'ditalini': ('ditalini', 'f_pasta', 'i ditalini', 10),
    }
    return [opt(k, lib[k][0], {lib[k][1]: g}, the=lib[k][2], soup=lib[k][3]) for k in keys]


PANE = opt('pane', 'pane integrale', {'f_pane_int': 70}, the='il pane integrale', pron='lo',
           cook='taglia il pane integrale a fette e tostalo in forno o in padella per 3 minuti')
PATATE_FORNO = opt('patate', 'patate al forno', {'f_patate': 250, 'f_olio': 4}, the='le patate', pron='le',
                   cook="taglia le patate a spicchi, condiscile con un filo d'olio e rosmarino e cuocile "
                        'in forno a 200 °C per 35 minuti')

# --- Template ---------------------------------------------------------------

TEMPLATES = [
    # Zuppe e minestre -------------------------------------------------------
    Template(
        key='v_minestrone', type=MAIN,
        name='Minestrone di {v.label} con {l.label} e {c.label}',
        base={'f_cipolla': 40, 'f_carote': 50, 'f_sedano': 40, 'f_olio': 10, 'f_pelati': 80,
              'f_brodo': 400, 'f_erbe': 2, 'f_parmigiano': 12},
        slots={
            'v': veg(['zucca', 'cavolfiore', 'broccoli', 'porri', 'piselli_freschi', 'asparagi', 'zucchine',
                      'spinaci', 'bietole', 'cavolo_nero', 'fagiolini', 'fave', 'carciofi', 'verza'], grams=150),
            'l': leg(['cannellini', 'borlotti', 'ceci'], g=200),
            'c': soup_grain(['orzo', 'farro', 'riso', 'ditalini']),
        },
        steps=[
            "Trita cipolla, carota e sedano e fai appassire il soffritto con l'olio in una pentola capiente "
            'per 6-7 minuti a fuoco medio.',
            '{v.cut}; unisci{v.pron} al soffritto con i pelati schiacciati e lascia insaporire per 3 minuti.',
            'Versa il brodo vegetale bollente, aggiungi il rosmarino tritato e cuoci a fuoco medio-basso '
            'per 20 minuti.',
            '{l.prep}; frullane un terzo con un mestolo di brodo e unisci tutto alla pentola.',
            'Aggiungi {c.the} e cuoci ancora {c.soup} minuti, mescolando spesso; se serve allunga con '
            'poca acqua calda.',
            'Regola di sale e pepe e completa con il parmigiano grattugiato. Per il meal prep tieni il '
            'minestrone un po\' più brodoso: il cereale continua ad assorbire liquido.',
        ],
        protein='legumi', fridge=4, freeze=True, minutes=55, tags=['zuppa', 'piatto unico'], max=12,
    ),
    Template(
        key='v_ribollita', type=MAIN,
        name='Ribollita con cavolo nero, {v.label} e {l.label}',
        base={'f_cavolo_nero': 120, 'f_cipolla': 40, 'f_carote': 40, 'f_sedano': 30, 'f_aglio': 3,
              'f_pelati': 60, 'f_olio': 10, 'f_brodo': 350, 'f_erbe': 2, 'f_pane': 60},
        slots={
            'v': veg(['verza', 'bietole', 'zucca', 'porri'], grams=100),
            'l': leg(['cannellini', 'borlotti'], g=230),
        },
        steps=[
            "Trita cipolla, carota, sedano e aglio e falli appassire nell'olio in una pentola capiente "
            'per 6 minuti.',
            'Elimina la costa centrale del cavolo nero e taglialo a strisce; {v.cut}.',
            'Unisci le verdure al soffritto con i pelati e il timo, copri con il brodo e cuoci a fuoco '
            'basso per 30 minuti.',
            '{l.prep}; frullane metà con un mestolo di brodo, aggiungi tutto alla zuppa e cuoci altri '
            '10 minuti.',
            'Taglia il pane raffermo a cubetti, uniscilo alla zuppa e cuoci ancora 5 minuti mescolando, '
            'finché si sfalda. Regola di sale e pepe: ripassata in pentola il giorno dopo è ancora più buona.',
        ],
        protein='legumi', fridge=4, freeze=True, minutes=60, tags=['zuppa', 'piatto unico'], max=7,
    ),
    Template(
        key='v_zuppa_cereali', type=MAIN,
        name='Zuppa di {c.label} e {l.label} con {v.label}',
        base={'f_cipolla': 40, 'f_sedano': 30, 'f_aglio': 3, 'f_erbe': 2, 'f_olio': 10,
              'f_concentrato': 10, 'f_brodo': 400},
        slots={
            'c': [opt('farro', 'farro', {'f_farro': 65}, the='il farro perlato', min=20),
                  opt('orzo', 'orzo', {'f_orzo': 65}, the="l'orzo perlato", min=25)],
            'l': leg(['borlotti', 'cannellini', 'ceci'], g=200),
            'v': veg(['funghi', 'porcini', 'zucca', 'cavolo_nero', 'spinaci', 'bietole', 'porri', 'carciofi',
                      'asparagi'], grams=150),
        },
        steps=[
            "Trita cipolla, sedano e aglio e falli appassire nell'olio con il rosmarino tritato per 5 minuti.",
            '{v.cut}; unisci{v.pron} al soffritto e lascia insaporire per 5 minuti.',
            'Aggiungi {c.the} sciacquato e il concentrato di pomodoro, copri con il brodo bollente e cuoci '
            'a fuoco medio-basso per {c.min} minuti.',
            '{l.prep}; schiacciane metà con una forchetta e uniscili tutti alla zuppa negli ultimi 10 minuti, '
            'così diventa cremosa.',
            "Regola di sale e pepe: la zuppa deve risultare densa. Si scalda in pentolino con un goccio d'acqua.",
        ],
        protein='legumi', fridge=4, freeze=True, minutes=50, tags=['zuppa', 'piatto unico'], max=10,
    ),
    Template(
        key='v_zuppa_lenticchie', type=MAIN,
        name='Zuppa di lenticchie e {v.label} con {c.label}',
        base={'f_lenticchie': 75, 'f_cipolla': 40, 'f_carote': 50, 'f_sedano': 30, 'f_aglio': 3,
              'f_olio': 10, 'f_pelati': 80, 'f_brodo': 450, 'f_erbe': 2},
        slots={
            'v': veg(['zucca', 'spinaci', 'bietole', 'cavolo_nero', 'porri', 'funghi', 'verza'], grams=150),
            'c': [opt('crostini', 'crostini integrali', {'f_pane_int': 60}, the='i crostini',
                      step='Taglia il pane integrale a cubetti e tostalo in forno a 200 °C per 8 minuti; '
                           'conservalo a parte fino al momento di servire.'),
                  opt('riso_int', 'riso integrale', {'f_riso_int': 55}, the='il riso integrale',
                      step='Lessa il riso integrale in acqua salata per 35 minuti e scolalo.'),
                  opt('farro', 'farro', {'f_farro': 55}, the='il farro',
                      step='Lessa il farro perlato in acqua salata per 20 minuti e scolalo.')],
        },
        steps=[
            "Sciacqua le lenticchie. Trita cipolla, carota, sedano e aglio e falli appassire nell'olio "
            'per 5 minuti.',
            'Aggiungi le lenticchie, i pelati schiacciati e il rosmarino, copri con il brodo e cuoci a '
            'fuoco basso per 25 minuti.',
            '{v.cut}; unisci{v.pron} alla zuppa e cuoci altri {v.boil} minuti, finché le lenticchie sono tenere.',
            '{c.step}',
            'Frulla un mestolo di zuppa e rimettilo in pentola per renderla più cremosa; regola di sale e '
            'pepe e servi con {c.the}.',
        ],
        protein='legumi', fridge=5, freeze=True, minutes=50, tags=['zuppa', 'piatto unico'], max=9,
    ),
    Template(
        key='v_pasta_legumi', type=MAIN,
        name='Pasta e {l.label} con {v.label}',
        base={'f_pasta': 70, 'f_cipolla': 30, 'f_aglio': 3, 'f_erbe': 2, 'f_olio': 10,
              'f_concentrato': 10, 'f_brodo': 350, 'f_parmigiano': 10},
        slots={
            'l': leg(['ceci', 'borlotti', 'cannellini'], g=200),
            'v': veg(['zucca', 'spinaci', 'bietole', 'cavolo_nero', 'broccoli', 'cime_rapa', 'carciofi',
                      'zucchine', 'funghi', 'porcini', 'cavolfiore'], grams=150),
        },
        steps=[
            "Trita cipolla e aglio e falli rosolare nell'olio con il rosmarino per 3 minuti.",
            '{v.cut}; unisci{v.pron} al soffritto e cuoci{v.pron} per {v.saute} minuti.',
            '{l.prep}; aggiungi{l.pron} con il concentrato di pomodoro, copri con il brodo bollente e cuoci '
            '10 minuti, poi frulla un terzo dei legumi con il mixer a immersione.',
            'Cala i ditalini direttamente nella minestra e cuocili per 10 minuti, mescolando spesso e '
            'aggiungendo brodo se si asciuga troppo. Per il meal prep spegni un minuto prima: la pasta '
            'finisce di ammorbidirsi riposando.',
            'Manteca con il parmigiano grattugiato e regola di sale e pepe.',
        ],
        protein='legumi', fridge=3, minutes=40, tags=['piatto unico'], max=10,
    ),
    Template(
        key='v_vellutata', type=MAIN,
        name='Vellutata di {v.label} e {l.label} con {t.label}',
        base={'f_patate': 100, 'f_cipolla': 40, 'f_olio': 10, 'f_brodo': 400, 'f_erbe': 2},
        slots={
            'v': veg(['zucca', 'cavolfiore', 'broccoli', 'porri', 'carote', 'asparagi', 'zucchine', 'funghi',
                      'patate_dolci', 'finocchi', 'spinaci'], grams=250)
                 + veg(['piselli_freschi'], grams=180),
            'l': leg(['cannellini', 'ceci'], g=180)
                 + [opt('rosse', 'lenticchie rosse', {'f_lenticchie_rosse': 50}, 'legumi',
                        the='le lenticchie rosse', pron='le', prep='sciacqua le lenticchie rosse')],
            't': [opt('parm', 'crostini al parmigiano', {'f_pane_int': 50, 'f_parmigiano': 12},
                      step="Taglia il pane integrale a cubetti e tostalo in forno a 200 °C per 8 minuti; "
                           "servi la vellutata con i crostini, il parmigiano a scaglie e l'olio rimasto a crudo."),
                  opt('semi', 'crostini e semi di zucca', {'f_pane_int': 50, 'f_semi_zucca': 15},
                      step="Taglia il pane integrale a cubetti e tostalo in forno a 200 °C per 8 minuti, "
                           "poi tosta i semi di zucca in padella per 2 minuti; servi la vellutata con "
                           "crostini, semi e l'olio rimasto a crudo.")],
        },
        steps=[
            "Affetta la cipolla e falla appassire in una pentola con metà dell'olio per 4 minuti.",
            '{v.cut}; pela la patata e tagliala a cubetti.',
            'Unisci le verdure al soffritto con il timo; {l.prep} e aggiungi{l.pron} in pentola.',
            'Copri con il brodo bollente e cuoci a fuoco medio per 20-25 minuti, finché tutto è tenero; '
            'frulla con il mixer a immersione fino a ottenere una crema liscia e regola di sale e pepe.',
            '{t.step} Tieni i crostini a parte, in un sacchetto, fino al consumo.',
        ],
        protein='legumi', fridge=4, freeze=True, minutes=40, tags=['zuppa'], max=12,
    ),

    # Dal, curry e chili ----------------------------------------------------
    Template(
        key='v_dal', type=MAIN,
        name='Dal di lenticchie rosse con {v.label} e {c.label}',
        base={'f_lenticchie_rosse': 75, 'f_cipolla': 50, 'f_aglio': 4, 'f_zenzero': 5, 'f_curcuma': 1,
              'f_cumino': 1, 'f_garam': 2, 'f_pelati': 100, 'f_latte_cocco': 60, 'f_olio': 8},
        slots={
            'v': veg(['spinaci', 'zucca', 'cavolfiore', 'patate_dolci', 'carote', 'zucchine', 'bietole',
                      'melanzane', 'broccoli'], grams=150),
            'c': carb(['riso', 'riso_int', 'quinoa', 'miglio'], grams=65),
        },
        steps=[
            '{c.cook}.',
            "Trita cipolla, aglio e zenzero e falli appassire nell'olio per 4 minuti; aggiungi curcuma, "
            'cumino e garam masala e tosta le spezie per 1 minuto.',
            '{v.cut}; unisci{v.pron} al soffritto con le lenticchie rosse sciacquate e i pelati schiacciati.',
            'Copri con 350 ml di acqua calda e cuoci a fuoco medio-basso per 20 minuti, mescolando spesso, '
            'finché le lenticchie si sfaldano.',
            'Aggiungi il latte di cocco, cuoci altri 3 minuti e regola di sale. Servi il dal con {c.the}.',
        ],
        protein='legumi', fridge=4, freeze=True, minutes=40, tags=['curry', 'piatto unico'], max=10,
    ),
    Template(
        key='v_curry_legumi', type=MAIN,
        name='Curry di {l.label} e {v.label} con {c.label}',
        base={'f_cipolla': 50, 'f_aglio': 4, 'f_zenzero': 5, 'f_curry': 3, 'f_pelati': 120,
              'f_latte_cocco': 80, 'f_olio': 8, 'f_prezzemolo': 3},
        slots={
            'l': leg(['ceci', 'cannellini'], g=240),
            'v': veg(['cavolfiore', 'zucca', 'patate_dolci', 'spinaci', 'melanzane', 'zucchine', 'peperoni',
                      'broccoli', 'carote', 'fagiolini', 'piselli_freschi'], grams=150),
            'c': carb(['riso', 'riso_int', 'quinoa'], grams=65),
        },
        steps=[
            '{c.cook}.',
            "Trita cipolla, aglio e zenzero e falli appassire nell'olio per 4 minuti, poi aggiungi il curry "
            'e tostalo per 1 minuto.',
            '{v.cut}; unisci{v.pron} al soffritto e lascia insaporire per 3 minuti.',
            "{l.prep}; aggiungi{l.pron} con i pelati e mezzo bicchiere d'acqua e cuoci coperto a fuoco "
            'medio-basso per 15-20 minuti, finché le verdure sono tenere.',
            'Versa il latte di cocco, cuoci 3 minuti scoperto perché il sugo si addensi e completa con '
            'prezzemolo tritato. Servi con {c.the}.',
        ],
        protein='legumi', fridge=4, freeze=True, minutes=40, tags=['curry', 'piatto unico'], max=10,
    ),
    Template(
        key='v_chili', type=MAIN,
        name='Chili sin carne di {l.label} e {v.label} con {c.label}',
        base={'f_cipolla': 50, 'f_aglio': 4, 'f_olio': 8, 'f_cumino': 1, 'f_paprika': 2, 'f_spezie': 1,
              'f_pelati': 200, 'f_mais': 40, 'f_limone': 10, 'f_prezzemolo': 3},
        slots={
            'l': [opt('neri', 'fagioli neri', {'f_fagioli_neri': 230}, 'legumi',
                      step="Sciacqua e sgocciola i fagioli neri; uniscili con i pelati schiacciati e il mais "
                           'sgocciolato e cuoci a fuoco basso per 20 minuti, finché il chili si addensa.'),
                  opt('borlotti', 'borlotti', {'f_fagioli': 230}, 'legumi',
                      step="Sciacqua e sgocciola i borlotti; uniscili con i pelati schiacciati e il mais "
                           'sgocciolato e cuoci a fuoco basso per 20 minuti, finché il chili si addensa.'),
                  opt('lenticchie', 'lenticchie', {'f_lenticchie': 70}, 'legumi',
                      step='Sciacqua le lenticchie e uniscile con i pelati schiacciati e 300 ml di acqua calda; '
                           'cuoci a fuoco basso per 30 minuti, poi aggiungi il mais sgocciolato e cuoci '
                           'altri 5 minuti.')],
            'v': veg(['peperoni', 'zucchine', 'zucca', 'patate_dolci', 'carote', 'melanzane', 'funghi'],
                     grams=150),
            'c': carb(['riso', 'riso_int', 'quinoa'], grams=65)
                 + [opt('tortillas', 'tortillas integrali', {'f_tortilla': 100}, the='le tortillas',
                        cook='al momento di servire scalda le tortillas in padella 30 secondi per lato')],
        },
        steps=[
            '{c.cook}.',
            "Trita cipolla e aglio e falli appassire nell'olio per 4 minuti; aggiungi cumino, paprika e "
            'peperoncino e tosta per 1 minuto.',
            '{v.cut}; unisci{v.pron} al soffritto e cuoci{v.pron} per 5 minuti.',
            '{l.step}',
            'Regola di sale e servi il chili con {c.the}, una spruzzata di succo di limone e prezzemolo tritato.',
        ],
        protein='legumi', fridge=5, freeze=True, minutes=45, tags=['piatto unico'], max=10,
    ),

    # Burger, polpette, falafel, hummus --------------------------------------
    Template(
        key='v_burger', type=MAIN,
        name='Burger di {l.label} con {v.label} al forno e {c.label}',
        base={'f_avena': 30, 'f_farina_ceci': 20, 'f_cipolla': 30, 'f_aglio': 3, 'f_prezzemolo': 5,
              'f_cumino': 1, 'f_paprika': 1, 'f_olio': 10},
        slots={
            'l': leg(['ceci', 'cannellini', 'borlotti', 'lenticchie'], g=200),
            'v': veg(['zucchine', 'melanzane', 'peperoni', 'zucca', 'cavolfiore', 'broccoli', 'finocchi',
                      'carote', 'funghi', 'cavolini', 'carciofi', 'fagiolini'], grams=200),
            'c': [opt('pane', 'pane integrale', {'f_pane_int': 60}, the='il pane integrale', step=''),
                  opt('patate', 'patate', {'f_patate': 250}, the='le patate',
                      step="Taglia le patate a spicchi e infornale in una teglia con un cucchiaino d'olio "
                           'presa dalla dose: cuoceranno 35 minuti in tutto.')],
        },
        steps=[
            '{l.prep}, poi asciuga{l.pron} con carta da cucina.',
            "Frulla {l.the} con cipolla, aglio, prezzemolo, cumino e paprika; aggiungi i fiocchi d'avena e la "
            "farina di ceci, sala e lascia riposare l'impasto 10 minuti perché si rassodi.",
            'Scalda il forno a 200 °C. {c.step}',
            'Con le mani umide forma 2 burger per porzione e disponili su una teglia con carta forno, '
            "spennellandoli con un po' d'olio.",
            "{v.cut}; condisci{v.pron} con il resto dell'olio, sale e pepe e disponi{v.pron} su un'altra teglia.",
            'Cuoci i burger per 25 minuti, girandoli a metà cottura, e {v.the} per {v.roast} minuti. '
            'Servi con {c.the}.',
        ],
        protein='legumi', fridge=4, freeze=True, minutes=50, tags=['forno'], max=10,
    ),
    Template(
        key='v_polpette', type=MAIN,
        name='Polpette di {l.label} e {v.label} al sugo con {c.label}',
        base={'f_pangrattato': 25, 'f_farina_ceci': 15, 'f_aglio': 3, 'f_prezzemolo': 5, 'f_cipolla': 20,
              'f_passata': 200, 'f_basilico': 3, 'f_olio': 10},
        slots={
            'l': leg(['ceci', 'cannellini', 'borlotti', 'lenticchie'], g=200, dry=65),
            'v': veg(['spinaci', 'zucchine', 'carote', 'bietole', 'zucca', 'funghi', 'cavolo_nero'], grams=100),
            'c': carb(['couscous', 'bulgur', 'riso_int', 'farro'], grams=55),
        },
        steps=[
            '{l.prep}.',
            "{v.cut}; salta{v.pron} in padella con un cucchiaino d'olio per {v.saute} minuti, poi "
            'trita{v.pron} finemente.',
            "Frulla {l.the} con le verdure, l'aglio e il prezzemolo; incorpora il pangrattato e la farina di "
            'ceci, regola di sale e forma polpette grandi come una noce.',
            'Disponi le polpette su una teglia con carta forno e cuocile in forno a 200 °C per 15 minuti, '
            'finché sono sode.',
            "Intanto rosola la cipolla tritata nel resto dell'olio, versa la passata con il basilico e cuoci "
            '10 minuti; aggiungi le polpette e cuoci altri 5 minuti.',
            '{c.cook}. Servi le polpette con il sugo e {c.the}.',
        ],
        protein='legumi', fridge=4, freeze=True, minutes=55, tags=['forno'], max=10,
    ),
    Template(
        key='v_hummus_bowl', type=MAIN,
        name='Bowl con hummus di {l.label}, {v.label} al forno e {c.label}',
        base={'f_tahina': 15, 'f_limone': 15, 'f_aglio': 2, 'f_cumino': 1, 'f_olio': 10, 'f_prezzemolo': 5,
              'f_paprika': 1},
        slots={
            'l': leg(['ceci', 'cannellini'], g=200)
                 + [opt('edamame', 'edamame', {'f_edamame': 150}, 'legumi', the='gli edamame', pron='li',
                        prep="lessa gli edamame per 4 minuti e raffreddali sotto l'acqua fredda")],
            'v': veg(['zucchine', 'melanzane', 'peperoni', 'zucca', 'cavolfiore', 'broccoli', 'carote',
                      'patate_dolci', 'finocchi', 'cavolini', 'pomodorini'], grams=200),
            'c': carb(['bulgur', 'couscous', 'quinoa', 'farro'], grams=60),
        },
        steps=[
            "{v.cut}; condisci{v.pron} con metà dell'olio, sale e paprika e cuoci{v.pron} in forno a "
            '200 °C per {v.roast} minuti.',
            '{c.cook}.',
            "{l.prep}; frulla{l.pron} con tahina, succo di limone, aglio, cumino, il resto dell'olio e "
            "2-3 cucchiai d'acqua fredda fino a ottenere una crema liscia; regola di sale.",
            "Componi le bowl con {c.the}, {v.the} e l'hummus; completa con prezzemolo tritato. "
            "Per il meal prep conserva l'hummus in un vasetto a parte.",
        ],
        protein='legumi', fridge=4, minutes=40, tags=['bowl'], max=10,
    ),
    Template(
        key='v_falafel', type=MAIN,
        name='Falafel al forno con {v.label}, {c.label} e salsa {y.label}',
        base={'f_ceci': 220, 'f_farina_ceci': 20, 'f_cipolla': 30, 'f_aglio': 3, 'f_prezzemolo': 10,
              'f_cumino': 2, 'f_olio': 10},
        slots={
            'v': [opt('pomodori', 'pomodori e cetrioli', {'f_pomodori': 120, 'f_cetrioli': 100},
                      the="l'insalata", step='Taglia pomodori e cetrioli a cubetti e condiscili con un pizzico di sale.'),
                  opt('cavolo', 'cavolo rosso e carote', {'f_cavolo_rosso': 100, 'f_carote': 60},
                      the='il cavolo rosso con le carote',
                      step='Affetta finemente il cavolo rosso, grattugia le carote e mescolali con un pizzico di sale.'),
                  opt('zucchine', 'zucchine grigliate', {'f_zucchine': 200}, the='le zucchine',
                      step='Taglia le zucchine a fette nel senso della lunghezza e grigliale su una piastra '
                           'rovente 2 minuti per lato.'),
                  opt('melanzane', 'melanzane al forno', {'f_melanzane': 200}, the='le melanzane',
                      step='Taglia le melanzane a cubetti e cuocile in forno insieme ai falafel per 25 minuti.'),
                  opt('finocchi', 'finocchi e arance', {'f_finocchi': 150, 'f_arancia': 100},
                      the="l'insalata di finocchi e arance",
                      step="Affetta sottilmente i finocchi, pela a vivo l'arancia, tagliala a spicchi e "
                           'uniscila ai finocchi.'),
                  opt('barbabietola', 'valeriana e barbabietola', {'f_valeriana': 50, 'f_barbabietola': 100},
                      the="l'insalata", step='Taglia la barbabietola a cubetti e uniscila alla valeriana lavata.')],
            'c': carb(['bulgur', 'couscous', 'quinoa'], grams=60) + [PANE],
            'y': [opt('yogurt', 'allo yogurt', {'f_yogurt_greco': 100, 'f_limone': 10},
                      step='Mescola lo yogurt greco con il succo di limone, sale e pepe.'),
                  opt('tahina', 'tahina', {'f_tahina': 15, 'f_limone': 15},
                      step="Diluisci la tahina con il succo di limone e 2-3 cucchiai d'acqua fino a ottenere "
                           'una salsa fluida; sala.')],
        },
        steps=[
            'Sciacqua e sgocciola i ceci e asciugali bene con carta da cucina.',
            "Frulla i ceci a scatti con cipolla, aglio, prezzemolo e cumino, lasciando l'impasto un po' "
            'granuloso; incorpora la farina di ceci, sala e fai riposare in frigo per 15 minuti.',
            'Scalda il forno a 200 °C. Forma delle palline leggermente schiacciate, disponile su una teglia '
            "con carta forno, spennellale con l'olio e cuocile per 25 minuti, girandole a metà.",
            '{c.cook}.',
            '{v.step}',
            '{y.step}',
            'Componi le porzioni con i falafel, {c.the} e {v.the}; tieni la salsa a parte fino al consumo.',
        ],
        protein='legumi', fridge=4, freeze=True, minutes=50, tags=['forno'], max=8,
    ),

    # Uova, torte salate, sformati ------------------------------------------
    Template(
        key='v_frittata_forno', type=MAIN,
        name='Frittata al forno di {v.label} e {k.label} con {c.label}',
        base={'f_uova': 110, 'f_albume': 100, 'f_latte': 30, 'f_olio': 8, 'f_cipolla': 30, 'f_prezzemolo': 3},
        slots={
            'v': veg(['zucchine', 'asparagi', 'carciofi', 'spinaci', 'bietole', 'porri', 'funghi', 'peperoni',
                      'cime_rapa', 'broccoli', 'zucca', 'piselli_freschi', 'cavolo_nero', 'radicchio'], grams=180),
            'k': [opt('parmigiano', 'parmigiano', {'f_parmigiano': 15}, the='il parmigiano grattugiato'),
                  opt('pecorino', 'pecorino', {'f_pecorino': 15}, the='il pecorino grattugiato'),
                  opt('feta', 'feta', {'f_feta': 40}, the='la feta sbriciolata'),
                  opt('scamorza', 'scamorza', {'f_scamorza': 30}, the='la scamorza a cubetti')],
            'c': [opt('pane', 'pane integrale', {'f_pane_int': 70}, the='il pane integrale', step=''),
                  opt('patate', 'patate arrosto', {'f_patate': 250, 'f_olio': 4}, the='le patate',
                      step="Taglia le patate a spicchi, condiscile con un filo d'olio e rosmarino e cuocile "
                           'su una seconda teglia per 35 minuti.')],
        },
        exclude=lambda c: c['v'].key == 'radicchio' and c['k'].key == 'feta',
        steps=[
            'Scalda il forno a 180 °C. {c.step}',
            "{v.cut}; salta{v.pron} in padella con la cipolla affettata e l'olio per {v.saute} minuti, poi "
            'lascia intiepidire.',
            'Sbatti le uova con gli albumi, il latte, {k.the} e il prezzemolo tritato; regola di sale e pepe.',
            'Unisci le verdure, versa il composto in una teglia rivestita di carta forno bagnata e strizzata '
            'e cuoci per 25 minuti, finché la superficie è dorata e il centro rappreso.',
            'Lascia intiepidire, taglia la frittata a quadrotti e servila con {c.the}.',
        ],
        protein='uova', fridge=3, minutes=45, tags=['forno'], max=12,
    ),
    Template(
        key='v_frittata_albumi', type=MAIN,
        name='Frittata di albumi con {v.label} e {c.label}',
        base={'f_albume': 200, 'f_uova': 55, 'f_parmigiano': 10, 'f_olio': 8, 'f_prezzemolo': 3},
        slots={
            'v': veg(['zucchine', 'spinaci', 'asparagi', 'funghi', 'peperoni', 'pomodorini', 'bietole',
                      'broccoli', 'porri', 'fagiolini'], grams=180),
            'c': carb(['quinoa', 'couscous'], grams=60) + [PANE, PATATE_FORNO],
        },
        steps=[
            '{c.cook}.',
            "{v.cut}; cuoci{v.pron} in una padella antiaderente da 24 cm con l'olio per {v.saute} minuti.",
            "Sbatti gli albumi con l'uovo, il parmigiano e il prezzemolo tritato; regola di sale e pepe.",
            'Versa il composto sulle verdure, copri e cuoci a fuoco basso per 8-10 minuti, finché la '
            'superficie è rappresa; gira la frittata aiutandoti con il coperchio e cuocila ancora 2 minuti.',
            'Taglia la frittata a spicchi e servila con {c.the}.',
        ],
        protein='uova', fridge=3, minutes=30, max=10,
    ),
    Template(
        key='v_uova_purgatorio', type=MAIN,
        name='Uova in purgatorio con {l.label} e {v.label}',
        base={'f_uova': 110, 'f_pelati': 250, 'f_cipolla': 30, 'f_aglio': 3, 'f_olio': 8, 'f_basilico': 3,
              'f_spezie': 1, 'f_pane_int': 60},
        slots={
            'l': leg(['ceci', 'cannellini', 'neri'], g=120),
            'v': veg(['peperoni', 'zucchine', 'melanzane', 'spinaci', 'bietole', 'cavolo_nero', 'funghi',
                      'carciofi'], grams=150),
        },
        steps=[
            "Trita cipolla e aglio e falli appassire nell'olio in una padella larga con coperchio per 4 minuti.",
            '{v.cut}; unisci{v.pron} al soffritto e cuoci{v.pron} per {v.saute} minuti.',
            '{l.prep}; aggiungi{l.pron} con i pelati schiacciati e il peperoncino e cuoci il sugo per '
            '10 minuti a fuoco medio; sala.',
            "Forma due incavi nel sugo, rompi in ciascuno un uovo, copri e cuoci a fuoco basso per 6-8 minuti, "
            "finché l'albume è rappreso. Per il meal prep cuoci le uova 1-2 minuti in più.",
            'Completa con il basilico spezzettato e servi con il pane integrale tostato.',
        ],
        protein='uova', fridge=3, minutes=30, max=8,
    ),
    Template(
        key='v_torta_salata', type=MAIN,
        name='Torta salata di {v.label} e {k.label}',
        base={'f_farina_int': 50, 'f_olio': 8, 'f_uova': 55, 'f_albume': 50, 'f_parmigiano': 10,
              'f_insalata': 80, 'f_limone': 5},
        slots={
            'v': veg(['spinaci', 'bietole', 'zucchine', 'carciofi', 'porri', 'asparagi', 'zucca', 'funghi',
                      'broccoli', 'cime_rapa', 'radicchio', 'piselli_freschi'], grams=180),
            'k': [opt('ricotta', 'ricotta', {'f_ricotta': 100}, the='la ricotta'),
                  opt('feta', 'feta', {'f_feta': 45}, the='la feta sbriciolata'),
                  opt('scamorza', 'scamorza', {'f_scamorza': 40}, the='la scamorza a cubetti')],
        },
        exclude=lambda c: c['v'].key == 'radicchio' and c['k'].key == 'feta',
        steps=[
            "Impasta la farina integrale con metà dell'olio, un pizzico di sale e 25-30 ml di acqua tiepida "
            'fino a ottenere una pasta liscia; coprila e lasciala riposare 15 minuti.',
            "{v.cut}; salta{v.pron} in padella con il resto dell'olio per {v.saute} minuti e lascia intiepidire.",
            "Mescola {k.the} con l'uovo, gli albumi e il parmigiano; aggiungi le verdure e regola di sale e pepe.",
            'Scalda il forno a 180 °C. Stendi la pasta sottile, fodera una teglia rivestita di carta forno, '
            'bucherella il fondo e versa il ripieno.',
            'Cuoci per 35-40 minuti, finché il ripieno è rappreso e il bordo dorato; lascia intiepidire '
            'prima di tagliare.',
            "Servi ogni fetta con l'insalata mista condita con succo di limone; tienila a parte e condiscila "
            'al momento.',
        ],
        protein='latticini', fridge=3, freeze=True, minutes=70, tags=['forno'], max=10,
    ),
    Template(
        key='v_parmigiana', type=MAIN,
        name='Parmigiana light di {v.label} con {k.label}',
        base={'f_passata': 150, 'f_parmigiano': 15, 'f_basilico': 5, 'f_aglio': 3, 'f_olio': 8,
              'f_pane_int': 60},
        slots={
            'v': [opt('melanzane', 'melanzane', {'f_melanzane': 300}, the='le melanzane', pron='le',
                      slice='taglia le melanzane a fette di mezzo centimetro', min=20),
                  opt('zucchine', 'zucchine', {'f_zucchine': 300}, the='le zucchine', pron='le',
                      slice='taglia le zucchine a fette sottili nel senso della lunghezza', min=15),
                  opt('zucca', 'zucca', {'f_zucca': 300}, the='la zucca', pron='la',
                      slice='sbuccia la zucca e tagliala a fette di mezzo centimetro', min=20),
                  opt('carciofi', 'carciofi', {'f_carciofi': 250}, the='i carciofi', pron='li',
                      slice='pulisci i carciofi, elimina le foglie dure e tagliali a fettine', min=20),
                  opt('finocchi', 'finocchi', {'f_finocchi': 300}, the='i finocchi', pron='li',
                      slice='elimina le foglie esterne dei finocchi e tagliali a fette di mezzo centimetro', min=25),
                  opt('peperoni', 'peperoni', {'f_peperoni': 300}, the='i peperoni', pron='li',
                      slice='elimina semi e filamenti dai peperoni e tagliali a falde', min=25)],
            'k': [opt('mozzarella', 'mozzarella', {'f_mozzarella_light': 90}, layer='mozzarella a cubetti'),
                  opt('scamorza', 'scamorza affumicata', {'f_scamorza': 50}, layer='scamorza a fettine')],
        },
        steps=[
            "{v.slice}; disponi{v.pron} su teglie con carta forno, spennella{v.pron} con metà dell'olio e "
            'cuoci{v.pron} in forno a 200 °C per {v.min} minuti, senza friggere.',
            "Intanto cuoci la passata con l'aglio schiacciato, il resto dell'olio e qualche foglia di basilico "
            'per 10 minuti; sala.',
            'In una pirofila alterna strati di sugo, verdure, {k.layer} e parmigiano grattugiato, finendo con '
            'sugo e parmigiano.',
            'Inforna a 190 °C per 25 minuti, poi lascia riposare 15 minuti prima di tagliare: a porzioni si '
            'conserva benissimo.',
            'Servi con il pane integrale.',
        ],
        protein='latticini', fridge=4, freeze=True, minutes=70, tags=['forno'], max=8,
    ),
    Template(
        key='v_sformato_patate', type=MAIN,
        name='Sformato di patate, {v.label} e {k.label}',
        base={'f_patate': 250, 'f_uova': 55, 'f_albume': 60, 'f_parmigiano': 15, 'f_latte': 50,
              'f_pangrattato': 10, 'f_olio': 6},
        slots={
            'v': veg(['spinaci', 'zucchine', 'broccoli', 'funghi', 'porcini', 'carciofi', 'cavolo_nero', 'porri',
                      'piselli_freschi', 'bietole', 'zucca'], grams=150),
            'k': [opt('mozzarella', 'mozzarella', {'f_mozzarella_light': 70}, the='la mozzarella a cubetti'),
                  opt('scamorza', 'scamorza', {'f_scamorza': 40}, the='la scamorza a cubetti'),
                  opt('ricotta', 'ricotta', {'f_ricotta': 100}, the='la ricotta a cucchiaiate')],
        },
        steps=[
            'Lessa le patate con la buccia per 30-35 minuti, sbucciale e schiacciale ancora calde con lo '
            'schiacciapatate.',
            "{v.cut}; salta{v.pron} in padella con l'olio per {v.saute} minuti, con sale e pepe.",
            "Mescola il purè con l'uovo, gli albumi, il latte e il parmigiano; regola di sale e pepe.",
            'Scalda il forno a 190 °C. In una pirofila stendi metà del purè, distribuisci {v.the} e {k.the}, '
            'copri con il purè rimasto e cospargi di pangrattato.',
            'Cuoci per 30 minuti, finché la superficie è dorata, e lascia riposare 10 minuti prima di '
            'tagliare a porzioni.',
        ],
        protein='latticini', fridge=3, freeze=True, minutes=75, tags=['forno'], max=9,
    ),

    # Tofu, tempeh e seitan --------------------------------------------------
    Template(
        key='v_saltato', type=MAIN,
        name='{p.label} saltato con {v.label} e {c.label}',
        base={'f_soia': 15, 'f_zenzero': 5, 'f_aglio': 3, 'f_cipolla': 30, 'f_olio': 10, 'f_sesamo': 5},
        slots={
            'p': prot(['tofu', 'tempeh', 'seitan']),
            'v': veg(['zucchine', 'peperoni', 'broccoli', 'fagiolini', 'asparagi', 'funghi', 'verza',
                      'cavolo_nero', 'porri', 'carote'], grams=200),
            'c': carb(['riso', 'riso_int', 'riso_venere', 'grano_saraceno', 'quinoa'], grams=65)
                 + [opt('noodles', 'noodles di riso', {'f_noodles_riso': 65}, the='i noodles',
                        cook="cuoci i noodles di riso in acqua bollente per 4 minuti, scolali e passali "
                             "sotto l'acqua fredda")],
        },
        steps=[
            '{c.cook}.',
            '{p.cut}; rosola{p.pron} nel wok o in una padella larga con metà dell\'olio per {p.pan} minuti, '
            'finché è dorato, poi tieni{p.pron} da parte.',
            '{v.cut}; affetta la cipolla e trita aglio e zenzero.',
            "Nella stessa padella scalda il resto dell'olio e salta le verdure con cipolla, aglio e zenzero a "
            'fuoco vivace per {v.saute} minuti, mantenendole croccanti.',
            "Rimetti in padella {p.the}, sfuma con la salsa di soia e un cucchiaio d'acqua e cuoci 1 minuto "
            'mescolando.',
            'Servi con {c.the} e completa con i semi di sesamo tostati.',
        ],
        fridge=4, minutes=35, max=12,
    ),
    Template(
        key='v_forno', type=MAIN,
        name='{p.label} al forno con {v.label} e {c.label}',
        base={'f_olio': 10, 'f_paprika': 2, 'f_erbe': 3, 'f_aglio': 3, 'f_limone': 10},
        slots={
            'p': prot(['tofu', 'tempeh', 'seitan']),
            'v': veg(['zucchine', 'melanzane', 'peperoni', 'zucca', 'cavolfiore', 'broccoli', 'cavolini',
                      'finocchi', 'carote', 'funghi', 'carciofi', 'fagiolini'], grams=220),
            'c': carb(['patate', 'farro', 'quinoa', 'bulgur', 'couscous'], grams=None),
        },
        steps=[
            '{p.cut} e marina{p.pron} per 15 minuti con metà dell\'olio, la paprika, l\'aglio schiacciato, '
            'il succo di limone e un pizzico di sale. Intanto scalda il forno a 200 °C.',
            '{c.cook}.',
            "{v.cut}; condisci{v.pron} con il resto dell'olio e il rosmarino tritato e disponi{v.pron} in teglia, "
            'poi aggiungi {p.the} con la sua marinata.',
            'Cuoci per 25 minuti, girando tutto a metà cottura, finché {p.the} è dorato e le verdure sono '
            'tenere. Servi con {c.the}.',
        ],
        fridge=4, minutes=45, tags=['forno'], max=12,
    ),

    # Farinata, polenta, insalate tiepide ------------------------------------
    Template(
        key='v_farinata', type=MAIN,
        name='Farinata di ceci con {v.label} e {k.label}',
        base={'f_farina_ceci': 80, 'f_olio': 10, 'f_erbe': 2, 'f_cipolla': 20},
        slots={
            'v': veg(['porri', 'carciofi', 'zucchine', 'radicchio', 'cavolo_nero', 'spinaci', 'funghi',
                      'cime_rapa', 'zucca', 'peperoni'], grams=180),
            'k': [opt('fiocchi', 'fiocchi di latte', {'f_fiocchi_latte': 100}, the='i fiocchi di latte'),
                  opt('feta', 'feta', {'f_feta': 40}, the='la feta sbriciolata'),
                  opt('semi', 'semi di zucca', {'f_semi_zucca': 15}, the='i semi di zucca tostati')],
        },
        exclude=lambda c: c['v'].key == 'zucca' and c['k'].key == 'semi',
        steps=[
            "Sbatti la farina di ceci con 240 ml di acqua fredda (3 parti d'acqua per 1 di farina) eliminando "
            'i grumi; copri e lascia riposare almeno 2 ore, togliendo la schiuma in superficie.',
            "Scalda il forno a 230 °C con dentro una teglia unta con metà dell'olio.",
            'Mescola la pastella, versala nella teglia calda (deve essere alta circa mezzo centimetro), '
            'cospargi di rosmarino e cuoci per 20-25 minuti, finché la superficie è dorata e croccante.',
            "{v.cut}; salta{v.pron} in padella con la cipolla affettata e il resto dell'olio per {v.saute} minuti.",
            'Servi la farinata a spicchi con {v.the} e {k.the}.',
        ],
        protein='legumi', fridge=3, minutes=40, tags=['forno'], max=9,
    ),
    Template(
        key='v_polenta', type=MAIN,
        name='Polenta con {l.label} in umido e {v.label}',
        base={'f_polenta': 75, 'f_parmigiano': 10, 'f_olio': 10, 'f_cipolla': 30, 'f_aglio': 3, 'f_erbe': 2,
              'f_passata': 120},
        slots={
            'l': leg(['borlotti', 'cannellini', 'ceci', 'lenticchie'], g=200, dry=65),
            'v': veg(['funghi', 'porcini', 'cavolo_nero', 'verza', 'cime_rapa', 'spinaci', 'bietole', 'zucca',
                      'radicchio'], grams=150),
        },
        steps=[
            'Porta a bollore 300 ml di acqua salata, versa a pioggia la farina di mais mescolando con una '
            'frusta e cuoci per 40 minuti, mescolando spesso; a fine cottura incorpora il parmigiano.',
            "Trita cipolla e aglio e falli appassire in metà dell'olio con il rosmarino per 4 minuti; {l.stew}.",
            "{v.cut}; salta{v.pron} in padella con il resto dell'olio per {v.saute} minuti, con sale e pepe.",
            'Servi la polenta con {l.the} in umido e {v.the}. Per il meal prep versa la polenta ancora calda '
            'in una pirofila: una volta rappresa si taglia a fette da scaldare in padella o in forno.',
        ],
        protein='legumi', fridge=4, minutes=55, tags=['piatto unico'], max=8,
    ),
    Template(
        key='v_insalata_tiepida', type=MAIN,
        name='Insalata tiepida di {l.label} con {v.label} e {k.label}',
        base={'f_cipolla_rossa': 20, 'f_aceto': 5, 'f_olio': 10, 'f_prezzemolo': 5, 'f_insalata': 40,
              'f_pane_int': 50},
        slots={
            'l': leg(['ceci', 'cannellini', 'borlotti', 'lenticchie'], g=220, dry=70),
            'v': veg(['zucca', 'cavolfiore', 'broccoli', 'peperoni', 'zucchine', 'melanzane', 'fagiolini',
                      'asparagi', 'finocchi', 'radicchio', 'cavolini', 'patate_dolci', 'barbabietola',
                      'pomodorini', 'carote'], grams=200),
            'k': [opt('feta', 'feta', {'f_feta': 40}, the='la feta', step='Sbriciola la feta.'),
                  opt('noci', 'noci', {'f_noci': 15}, the='le noci', step='Trita grossolanamente le noci.'),
                  opt('mandorle', 'mandorle tostate', {'f_mandorle': 15}, the='le mandorle',
                      step='Tosta le mandorle in padella per 3 minuti e tritale grossolanamente.'),
                  opt('parmigiano', 'scaglie di parmigiano', {'f_parmigiano': 20}, the='le scaglie di parmigiano',
                      step='Riduci il parmigiano a scaglie con un pelapatate.')],
        },
        steps=[
            "{v.cut}; condisci{v.pron} con metà dell'olio, sale e pepe e cuoci{v.pron} in teglia nel forno "
            'già caldo a 200 °C per {v.roast} minuti.',
            '{l.warm}.',
            "Affetta sottilmente la cipolla rossa e lasciala 10 minuti in una ciotola d'acqua con l'aceto "
            'per addolcirla.',
            '{k.step}',
            "Unisci {l.the} ancora tiepid{l.end}, {v.the}, la cipolla scolata, l'insalata e il prezzemolo "
            "tritato; condisci con l'olio rimasto, completa con {k.the} e servi con il pane integrale tostato. "
            "Per il meal prep tieni l'insalata verde a parte.",
        ],
        protein='legumi', fridge=4, minutes=35, tags=['insalata'], max=10,
    ),
]
