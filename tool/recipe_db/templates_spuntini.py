"""Spuntini da meal prep: yogurt e frutta, barrette, energy balls, muffin,
biscotti, creme di legumi, gallette farcite, frittatine, budini e smoothie."""

from engine import SNACK, Template, opt
from foods import P, Food
from lib import FRUIT, NUTS_WHOLE, fruit, nuts, veg

EXTRA_FOODS = [
    Food('f_amido_mais', 'Amido di mais (maizena)', P, 350, 0.3, 87, 0.1, pack=250),
]

# Forme "al/alla/ai..." della frutta per i titoli.
AL = {
    'banana': 'alla banana', 'mela': 'alla mela', 'pera': 'alla pera', 'kiwi': 'al kiwi',
    'arancia': "all'arancia", 'mandarini': 'ai mandarini', 'cachi': 'ai cachi',
    'melograno': 'al melograno', 'uva': "all'uva", 'fichi': 'ai fichi', 'fragole': 'alle fragole',
    'ciliegie': 'alle ciliegie', 'albicocche': 'alle albicocche', 'pesche': 'alle pesche',
    'prugne': 'alle prugne', 'melone': 'al melone', 'mirtilli': 'ai mirtilli',
    'lamponi': 'ai lamponi', 'frutti_bosco': 'ai frutti di bosco',
}


def fruit_al(keys, grams=None):
    out = fruit(keys, grams)
    for o in out:
        o.attrs['al'] = AL[o.key]
    return out


# Frutta secca da tritare (con "the" già al plurale).
NUT_OPTS = nuts(NUTS_WHOLE)

# Creme di frutta secca e semi.
CREME = [
    opt('arachidi', "burro d'arachidi", {'f_burro_arachidi': 12}, the="il burro d'arachidi"),
    opt('mandorle', 'crema di mandorle', {'f_crema_mandorle': 12}, the='la crema di mandorle'),
    opt('tahina', 'tahina', {'f_tahina': 12}, the='la tahina'),
]

# Verdure crude da accompagnare (e alternative croccanti).
CRUDI = {
    'carote': opt('carote', 'bastoncini di carote', {'f_carote': 150}, the='le carote',
                  prep='Pela le carote e tagliale a bastoncini.'),
    'sedano': opt('sedano', 'bastoncini di sedano', {'f_sedano': 150}, the='il sedano',
                  prep='Elimina i filamenti del sedano e taglialo a bastoncini.'),
    'finocchio': opt('finocchio', 'spicchi di finocchio', {'f_finocchi': 150}, the='il finocchio',
                     prep='Elimina le foglie esterne del finocchio e taglialo a spicchi sottili.'),
    'cetriolo': opt('cetriolo', 'bastoncini di cetriolo', {'f_cetrioli': 150}, the='il cetriolo',
                    prep='Taglia il cetriolo a bastoncini eliminando la parte centrale con i semi.'),
    'peperone': opt('peperone', 'falde di peperone', {'f_peperoni': 130}, the='il peperone',
                    prep='Elimina semi e filamenti dal peperone e taglialo a falde sottili.'),
    'cavolfiore': opt('cavolfiore', 'cimette di cavolfiore', {'f_cavolfiore': 130}, the='il cavolfiore',
                      prep='Dividi il cavolfiore in piccole cimette e lavale.'),
    'pomodorini': opt('pomodorini', 'pomodorini', {'f_pomodorini': 150}, the='i pomodorini',
                      prep='Lava e asciuga i pomodorini.'),
    'zucchine': opt('zucchine', 'bastoncini di zucchine', {'f_zucchine': 150}, the='le zucchine',
                    prep='Spunta le zucchine e tagliale a bastoncini.'),
    'cracker': opt('cracker', 'cracker integrali', {'f_crackers': 25}, the='i cracker', prep=''),
    'gallette': opt('gallette', 'gallette di riso', {'f_gallette': 16}, the='le gallette', prep=''),
}
CRUDI_VEG = ['carote', 'sedano', 'finocchio', 'cetriolo', 'peperone', 'cavolfiore', 'pomodorini',
             'zucchine']


def crudi(keys):
    return [CRUDI[k] for k in keys]


TEMPLATES = [
    # --- Yogurt e frutta ----------------------------------------------------
    Template(
        key='n_yogurt_frutta', type=SNACK,
        name='{b.label} con {f.label} e {n.label}',
        base={'f_miele': 5},
        slots={
            'b': [
                opt('greco', 'yogurt greco', {'f_yogurt_greco': 170}, 'latticini', the='lo yogurt greco'),
                opt('skyr', 'skyr', {'f_skyr': 170}, 'latticini', the='lo skyr'),
                opt('fiocchi', 'fiocchi di latte', {'f_fiocchi_latte': 150}, 'latticini',
                    the='i fiocchi di latte'),
            ],
            'f': fruit(),
            'n': NUT_OPTS,
        },
        steps=[
            '{f.cut}; conserva la frutta in un contenitore a parte.',
            'Dividi {b.the} in vasetti con un filo di miele.',
            'Al momento di mangiare unisci la frutta e completa con {n.the}, così restano croccanti.',
        ],
        fridge=3, minutes=5, tags=['senza cottura'], max=20,
    ),
    Template(
        key='n_frutta_formaggio', type=SNACK,
        name='{f.label} con {n.label} e {c.label}',
        slots={
            'f': [
                opt('pera', 'pera', {'f_pera': 150}, the='la pera', pron='la'),
                opt('mela', 'mela', {'f_mela': 150}, the='la mela', pron='la'),
                opt('uva', 'uva', {'f_uva': 130}, the="l'uva", pron='la'),
                opt('fichi', 'fichi', {'f_fichi': 120}, the='i fichi', pron='li'),
                opt('prugne', 'prugne', {'f_prugne': 150}, the='le prugne', pron='le'),
            ],
            'n': nuts(['noci', 'mandorle', 'nocciole', 'pistacchi', 'anacardi']),
            'c': [
                opt('parmigiano', 'parmigiano', {'f_parmigiano': 20}, 'latticini', the='il parmigiano'),
                opt('pecorino', 'pecorino', {'f_pecorino': 20}, 'latticini', the='il pecorino'),
            ],
        },
        steps=[
            'Taglia {c.the} a scaglie e porzionalo in contenitori ermetici; aggiungi {n.the}.',
            'Lava {f.the} e conserva{f.pron} a parte fino al momento dello spuntino.',
        ],
        fridge=5, minutes=5, tags=['senza cottura'], max=8,
    ),
    Template(
        key='n_frutta_forno', type=SNACK,
        name='{f.dish} con {b.label} e {n.label}',
        base={'f_cannella': 1, 'f_miele': 5},
        slots={
            'f': [
                opt('mela', 'mela', {'f_mela': 180}, dish='Mela al forno', pron='la', oven=30,
                    prep='Lava la mela, eliminane il torsolo e tagliala in quarti'),
                opt('pera', 'pera', {'f_pera': 180}, dish='Pera al forno', pron='la', oven=30,
                    prep='Lava la pera, eliminane il torsolo e tagliala in quarti'),
                opt('pesche', 'pesche', {'f_pesche': 200}, dish='Pesche al forno', pron='le', oven=20,
                    prep='Lava le pesche, tagliale a metà ed elimina il nocciolo'),
                opt('albicocche', 'albicocche', {'f_albicocche': 180}, dish='Albicocche al forno', pron='le',
                    oven=15, prep='Lava le albicocche, tagliale a metà ed elimina il nocciolo'),
                opt('prugne', 'prugne', {'f_prugne': 180}, dish='Prugne al forno', pron='le', oven=15,
                    prep='Lava le prugne, tagliale a metà ed elimina il nocciolo'),
                opt('fichi', 'fichi', {'f_fichi': 150}, dish='Fichi al forno', pron='li', oven=12,
                    prep='Lava i fichi e incidili a croce sulla sommità'),
            ],
            'b': [
                opt('greco', 'yogurt greco', {'f_yogurt_greco': 150}, 'latticini', the='lo yogurt greco'),
                opt('skyr', 'skyr', {'f_skyr': 150}, 'latticini', the='lo skyr'),
                opt('ricotta', 'ricotta', {'f_ricotta': 80}, 'latticini', the='la ricotta'),
            ],
            'n': nuts(['noci', 'mandorle', 'nocciole', 'pistacchi'], grams=12),
        },
        steps=[
            'Scalda il forno a 180 °C.',
            '{f.prep}, disponi{f.pron} in una pirofila, spolverizza con la cannella, aggiungi il miele '
            'e cuoci per {f.oven} minuti.',
            'Trita grossolanamente {n.the}.',
            'Lascia intiepidire la frutta e porzionala con {b.the}; aggiungi la frutta secca al momento di mangiare.',
        ],
        fridge=4, minutes=35, tags=['forno'], max=14,
    ),
    Template(
        key='n_crostini_dolci', type=SNACK,
        name='{b.label} con {c.label}, {f.label} e miele',
        base={'f_miele': 6},
        slots={
            'b': [
                opt('pane', 'crostini integrali', {'f_pane_int': 40}, su='sulle fette di pane',
                    prep='Taglia il pane a fette sottili e tostalo in forno a 200 °C per 6-8 minuti.'),
                opt('gallette', 'gallette di riso', {'f_gallette': 24}, su='sulle gallette', prep=''),
            ],
            'c': [
                opt('ricotta', 'ricotta', {'f_ricotta': 70}, 'latticini', the='la ricotta'),
                opt('fiocchi', 'fiocchi di latte', {'f_fiocchi_latte': 90}, 'latticini',
                    the='i fiocchi di latte'),
            ],
            'f': [
                opt('fichi', 'fichi', {'f_fichi': 80}, prep='Taglia i fichi a fette'),
                opt('pera', 'pera', {'f_pera': 100}, prep='Taglia la pera a fettine sottili'),
                opt('fragole', 'fragole', {'f_fragole': 100}, prep='Lava le fragole e tagliale a fettine'),
                opt('pesche', 'pesche', {'f_pesche': 100}, prep='Taglia le pesche a fettine sottili'),
                opt('kiwi', 'kiwi', {'f_kiwi': 100}, prep='Sbuccia il kiwi e taglialo a rondelle'),
                opt('albicocche', 'albicocche', {'f_albicocche': 100},
                    prep='Snocciola le albicocche e tagliale a spicchi'),
                opt('mirtilli', 'mirtilli', {'f_mirtilli': 80}, prep='Lava e asciuga i mirtilli'),
                opt('cachi', 'cachi', {'f_cachi': 100}, prep='Preleva la polpa del caco con un cucchiaio'),
            ],
        },
        steps=[
            '{b.prep}',
            '{f.prep}; conserva la frutta in un contenitore a parte.',
            'Porziona {c.the} in un vasetto.',
            'Al momento dello spuntino spalma {c.the} {b.su}, aggiungi la frutta e completa con il miele.',
        ],
        fridge=2, minutes=10, tags=[], max=12,
    ),

    # --- Barrette, energy balls, muffin, biscotti --------------------------
    Template(
        key='n_barrette_avena', type=SNACK,
        name='Barrette di avena con {n.label}, {d.label} e {x.label}',
        base={'f_avena': 40, 'f_whey': 12, 'f_miele': 8, 'f_albume': 20},
        slots={
            'n': nuts(NUTS_WHOLE, grams=12),
            'd': [
                opt('datteri', 'datteri', {'f_datteri': 15}, the='i datteri'),
                opt('uvetta', 'uvetta', {'f_uvetta': 15}, the="l'uvetta"),
                opt('albicocche', 'albicocche secche', {'f_albicocche_secche': 15}, the='le albicocche secche'),
                opt('fichi', 'fichi secchi', {'f_fichi_secchi': 15}, the='i fichi secchi'),
            ],
            'x': [
                opt('cacao', 'cacao', {'f_cacao': 5}, the='il cacao'),
                opt('cannella', 'cannella', {'f_cannella': 1}, the='la cannella'),
                opt('cocco', 'cocco', {'f_cocco_rape': 6}, the='il cocco rapé'),
            ],
        },
        steps=[
            'Scalda il forno a 180 °C e fodera una teglia con carta forno.',
            'Trita grossolanamente {n.the} e {d.the}.',
            "In una ciotola mescola l'avena, le proteine in polvere, {x.the} e la frutta tritata; "
            'aggiungi il miele e gli albumi e amalgama fino a ottenere un impasto compatto.',
            "Stendi l'impasto nella teglia in uno strato di 1,5 cm, pressalo bene e cuoci per 20 minuti.",
            'Lascia raffreddare completamente e taglia in barrette.',
        ],
        protein='latticini', fridge=7, freeze=True, minutes=35, tags=['forno', 'pre-allenamento'], max=16,
    ),
    Template(
        key='n_barrette_crude', type=SNACK,
        name='Barrette proteiche senza cottura con {c.label} e {d.label}',
        base={'f_avena': 30, 'f_whey': 20, 'f_miele': 10, 'f_latte': 20},
        slots={
            'c': CREME,
            'd': [
                opt('datteri', 'datteri', {'f_datteri': 15}, the='i datteri tritati'),
                opt('cioccolato', 'cioccolato fondente', {'f_cioccolato': 8},
                    the='il cioccolato fondente tritato'),
                opt('uvetta', 'uvetta', {'f_uvetta': 15}, the="l'uvetta"),
                opt('albicocche', 'albicocche secche', {'f_albicocche_secche': 15},
                    the='le albicocche secche tritate'),
                opt('cocco', 'cocco', {'f_cocco_rape': 8}, the='il cocco rapé'),
            ],
        },
        steps=[
            "In una ciotola mescola l'avena, le proteine in polvere e {c.the}.",
            'Aggiungi il miele e il latte poco alla volta fino a ottenere un impasto compatto, poi incorpora {d.the}.',
            "Pressa l'impasto in uno stampo foderato con carta forno, livellalo e mettilo in frigo per almeno 2 ore.",
            'Taglia in barrette e avvolgile singolarmente nella carta forno.',
        ],
        protein='latticini', fridge=7, freeze=True, minutes=15, tags=['senza cottura', 'post-allenamento'],
        max=12,
    ),
    Template(
        key='n_energy_balls', type=SNACK,
        name='Energy balls di datteri, {n.label} e {x.label}',
        base={'f_datteri': 30, 'f_avena': 10},
        slots={
            'n': nuts(['mandorle', 'anacardi', 'nocciole', 'noci', 'pistacchi', 'semi_zucca'], grams=20),
            'x': [
                opt('cacao', 'cacao', {'f_cacao': 5}, the='il cacao'),
                opt('cocco', 'cocco', {'f_cocco_rape': 6}, the='il cocco rapé'),
                opt('cannella', 'cannella', {'f_cannella': 1}, the='la cannella'),
            ],
        },
        steps=[
            'Se i datteri sono duri, ammollali in acqua tiepida per 10 minuti; poi snocciolali.',
            "Frulla {n.the} con l'avena fino a ottenere una farina grossolana.",
            'Aggiungi i datteri e {x.the} e frulla fino a ottenere un impasto compatto e appiccicoso.',
            'Con le mani umide forma 3 palline per porzione.',
        ],
        protein='vegetale', fridge=7, freeze=True, minutes=15,
        tags=['senza cottura', 'pre-allenamento'], max=10,
    ),
    Template(
        key='n_energy_proteiche', type=SNACK,
        name='Energy balls proteiche con {c.label} e {x.label}',
        base={'f_datteri': 20, 'f_avena': 20, 'f_whey': 15, 'f_latte': 15},
        slots={
            'c': CREME,
            'x': [
                opt('cacao', 'cacao', {'f_cacao': 5}, the='il cacao'),
                opt('cocco', 'cocco', {'f_cocco_rape': 6}, the='il cocco rapé'),
                opt('cannella', 'cannella', {'f_cannella': 1}, the='la cannella'),
                opt('cioccolato', 'cioccolato fondente', {'f_cioccolato': 8}, the='il cioccolato fondente tritato'),
            ],
        },
        steps=[
            "Frulla l'avena con i datteri snocciolati fino a ottenere un composto granuloso.",
            'Aggiungi le proteine in polvere, {c.the}, {x.the} e il latte e frulla ancora fino a ottenere '
            'un impasto compatto.',
            'Con le mani umide forma 3 palline per porzione e lasciale rassodare in frigo per 30 minuti.',
        ],
        protein='latticini', fridge=7, freeze=True, minutes=15,
        tags=['senza cottura', 'post-allenamento'], max=10,
    ),
    Template(
        key='n_muffin', type=SNACK,
        name='Muffin proteici {f.al} e {x.label}',
        base={'f_avena': 30, 'f_yogurt_greco': 50, 'f_uova': 25, 'f_whey': 10, 'f_miele': 8, 'f_lievito': 2},
        slots={
            'f': [
                opt('mela', 'mela', {'f_mela': 50}, al='alla mela', the='la mela',
                    prep='Grattugia la mela con la buccia'),
                opt('pera', 'pera', {'f_pera': 50}, al='alla pera', the='la pera', prep='Grattugia la pera'),
                opt('banana', 'banana', {'f_banana': 50}, al='alla banana', the='la banana',
                    prep='Schiaccia la banana con una forchetta'),
                opt('mirtilli', 'mirtilli', {'f_mirtilli': 50}, al='ai mirtilli', the='i mirtilli',
                    prep='Lava e asciuga i mirtilli'),
                opt('lamponi', 'lamponi', {'f_lamponi': 50}, al='ai lamponi', the='i lamponi',
                    prep='Sciacqua delicatamente i lamponi e asciugali'),
                opt('albicocche', 'albicocche', {'f_albicocche': 50}, al='alle albicocche',
                    the='le albicocche', prep='Snocciola le albicocche e tagliale a cubetti'),
                opt('pesche', 'pesche', {'f_pesche': 50}, al='alle pesche', the='le pesche',
                    prep='Taglia le pesche a cubetti'),
                opt('prugne', 'prugne', {'f_prugne': 50}, al='alle prugne', the='le prugne',
                    prep='Snocciola le prugne e tagliale a cubetti'),
                opt('fragole', 'fragole', {'f_fragole': 50}, al='alle fragole', the='le fragole',
                    prep='Lava le fragole e tagliale a cubetti'),
                opt('carote', 'carote', {'f_carote': 50}, al='alle carote', the='le carote',
                    prep='Pela le carote e grattugiale finemente'),
                opt('zucca', 'zucca', {'f_zucca': 50}, al='alla zucca', the='la zucca',
                    prep='Grattugia finemente la zucca cruda'),
                opt('frutti_bosco', 'frutti di bosco', {'f_frutti_bosco': 50}, al='ai frutti di bosco',
                    the='i frutti di bosco', prep='Tieni i frutti di bosco in freezer fino al momento di usarli'),
            ],
            'x': [
                opt('cannella', 'cannella', {'f_cannella': 1}, the='la cannella'),
                opt('cacao', 'cacao', {'f_cacao': 5}, the='il cacao'),
                opt('noci', 'noci', {'f_noci': 10}, the='le noci tritate'),
                opt('mandorle', 'mandorle', {'f_mandorle': 10}, the='le mandorle tritate'),
                opt('cioccolato', 'cioccolato fondente', {'f_cioccolato': 8}, the='il cioccolato fondente tritato'),
            ],
        },
        exclude=lambda c: c['f'].key == 'carote' and c['x'].key in ('cacao', 'cioccolato'),
        steps=[
            'Scalda il forno a 180 °C e disponi i pirottini in uno stampo da muffin.',
            '{f.prep}.',
            "Frulla l'avena fino a ridurla in farina. In una ciotola sbatti l'uovo con lo yogurt e il miele, "
            "poi aggiungi la farina d'avena, le proteine in polvere e il lievito.",
            "Incorpora {f.the} e {x.the}, distribuisci l'impasto nei pirottini e cuoci per 20-22 minuti.",
            'Lascia raffreddare i muffin su una gratella prima di riporli.',
        ],
        protein='latticini', fridge=4, freeze=True, minutes=35, tags=['forno'], max=18,
    ),
    Template(
        key='n_biscotti', type=SNACK,
        name='Biscotti proteici di avena con {c.label} e {x.label}',
        base={'f_avena': 30, 'f_whey': 15, 'f_banana': 40, 'f_lievito': 1, 'f_cannella': 0.5},
        slots={
            'c': [
                opt('arachidi', "burro d'arachidi", {'f_burro_arachidi': 10}, the="il burro d'arachidi"),
                opt('mandorle', 'crema di mandorle', {'f_crema_mandorle': 10}, the='la crema di mandorle'),
                opt('tahina', 'tahina', {'f_tahina': 10}, the='la tahina'),
            ],
            'x': [
                opt('cioccolato', 'cioccolato fondente', {'f_cioccolato': 8}, the='il cioccolato fondente tritato'),
                opt('uvetta', 'uvetta', {'f_uvetta': 12}, the="l'uvetta"),
                opt('albicocche', 'albicocche secche', {'f_albicocche_secche': 12},
                    the='le albicocche secche tritate'),
                opt('cocco', 'cocco', {'f_cocco_rape': 6}, the='il cocco rapé'),
                opt('mirtilli', 'mirtilli', {'f_mirtilli': 25}, the='i mirtilli freschi'),
            ],
        },
        steps=[
            'Scalda il forno a 180 °C e fodera una teglia con carta forno.',
            'Schiaccia la banana con una forchetta e mescolala con {c.the}.',
            "Aggiungi l'avena, le proteine in polvere, il lievito e la cannella, poi incorpora {x.the}.",
            'Forma 3 biscotti per porzione, schiacciali sulla teglia e cuoci per 12-14 minuti.',
            'Lascia raffreddare completamente prima di riporli.',
        ],
        protein='latticini', fridge=5, freeze=True, minutes=25, tags=['forno'], max=12,
    ),

    # --- Creme di legumi, gallette e toast ---------------------------------
    Template(
        key='n_hummus', type=SNACK,
        name='{l.name} con {v.label}',
        base={'f_tahina': 10, 'f_olio': 5, 'f_limone': 10, 'f_cumino': 0.5},
        slots={
            'l': [
                opt('ceci', 'ceci', {'f_ceci': 110}, 'legumi', name='Hummus di ceci', the='i ceci',
                    prep='Sciacqua e sgocciola i ceci'),
                opt('cannellini', 'cannellini', {'f_cannellini': 120}, 'legumi', name='Crema di cannellini',
                    the='i cannellini', prep='Sciacqua e sgocciola i cannellini'),
                opt('borlotti', 'borlotti', {'f_fagioli': 120}, 'legumi', name='Crema di borlotti',
                    the='i borlotti', prep='Sciacqua e sgocciola i borlotti'),
                opt('neri', 'fagioli neri', {'f_fagioli_neri': 120}, 'legumi', name='Crema di fagioli neri',
                    the='i fagioli neri', prep='Sciacqua e sgocciola i fagioli neri'),
                opt('lenticchie', 'lenticchie rosse', {'f_lenticchie_rosse': 35}, 'legumi',
                    name='Hummus di lenticchie rosse', the='le lenticchie',
                    prep='Cuoci le lenticchie rosse in acqua per 12-15 minuti, scolale e lasciale raffreddare'),
                opt('edamame', 'edamame', {'f_edamame': 90}, 'legumi', name='Hummus di edamame',
                    the='gli edamame', prep="Lessa gli edamame per 4 minuti, scolali e passali sotto l'acqua fredda"),
                opt('fave', 'fave', {'f_fave_fresche': 130}, 'legumi', name='Crema di fave fresche',
                    the='le fave', prep="Sbollenta le fave per 3 minuti, raffreddale in acqua fredda ed elimina la pellicina"),
                opt('piselli', 'piselli', {'f_piselli_freschi': 120}, 'legumi', name='Crema di piselli freschi',
                    the='i piselli', prep='Lessa i piselli per 5 minuti e raffreddali in acqua fredda'),
                opt('zucca', 'zucca', {'f_ceci': 90, 'f_zucca': 70}, 'legumi', name='Hummus di ceci e zucca',
                    the='i ceci e la zucca',
                    prep='Taglia la zucca a cubetti e cuocila al vapore per 12 minuti; sciacqua e sgocciola i ceci'),
                opt('peperoni', 'peperoni', {'f_ceci': 90, 'f_peperoni': 70}, 'legumi',
                    name='Hummus di ceci e peperoni', the='i ceci e il peperone',
                    prep='Arrostisci il peperone in forno a 220 °C per 25 minuti, pelalo ed elimina i semi; '
                         'sciacqua e sgocciola i ceci'),
                opt('barbabietola', 'barbabietola', {'f_ceci': 90, 'f_barbabietola': 60}, 'legumi',
                    name='Hummus di ceci e barbabietola', the='i ceci e la barbabietola',
                    prep='Taglia a pezzi la barbabietola cotta; sciacqua e sgocciola i ceci'),
            ],
            'v': crudi(CRUDI_VEG + ['cracker', 'gallette']),
        },
        exclude=lambda c: c['l'].key == 'peperoni' and c['v'].key == 'peperone',
        steps=[
            '{l.prep}.',
            "Frulla {l.the} con la tahina, l'olio, il succo di limone, il cumino e un pizzico di sale, "
            "aggiungendo 2-3 cucchiai di acqua fredda fino a ottenere una crema liscia.",
            '{v.prep}',
            'Dividi la crema in vasetti e conserva {v.the} in un contenitore a parte.',
        ],
        fridge=4, minutes=15, tags=[], max=16,
    ),
    Template(
        key='n_gallette_salate', type=SNACK,
        name='{b.label} con {p.label} e {v.label}',
        base={'f_olio': 3},
        slots={
            'b': [
                opt('gallette', 'Gallette di riso', {'f_gallette': 24}, su='sulle gallette', prep=''),
                opt('pane', 'Crostini integrali', {'f_pane_int': 45}, su='sulle fette di pane',
                    prep='Taglia il pane a fette sottili e tostalo in forno a 200 °C per 6-8 minuti.'),
            ],
            'p': [
                opt('bresaola', 'bresaola', {'f_bresaola': 40}, 'manzo', the='la bresaola'),
                opt('crudo', 'prosciutto crudo', {'f_prosciutto_crudo': 35}, 'maiale', the='il prosciutto crudo'),
                opt('cotto', 'prosciutto cotto', {'f_prosciutto_cotto': 50}, 'maiale', the='il prosciutto cotto'),
                opt('tonno', 'tonno', {'f_tonno': 60}, 'pesce', the='il tonno sgocciolato'),
                opt('salmone', 'salmone affumicato', {'f_salmone_affumicato': 40}, 'pesce',
                    the='il salmone affumicato'),
                opt('ricotta', 'ricotta', {'f_ricotta': 80}, 'latticini', the='la ricotta'),
                opt('fiocchi', 'fiocchi di latte', {'f_fiocchi_latte': 90}, 'latticini', the='i fiocchi di latte'),
            ],
            'v': [
                opt('rucola', 'rucola', {'f_rucola': 20}, prep='Lava e asciuga la rucola'),
                opt('pomodorini', 'pomodorini', {'f_pomodorini': 70}, prep='Lava i pomodorini e tagliali a fette'),
                opt('cetrioli', 'cetrioli', {'f_cetrioli': 70}, prep='Taglia i cetrioli a rondelle sottili'),
                opt('valeriana', 'valeriana', {'f_valeriana': 20}, prep='Lava e asciuga la valeriana'),
                opt('finocchio', 'finocchio', {'f_finocchi': 60}, prep='Affetta finemente il finocchio'),
            ],
        },
        steps=[
            '{b.prep}',
            '{v.prep}; conserva le verdure in un contenitore a parte.',
            'Porziona {p.the} in contenitori ermetici.',
            "Al momento dello spuntino distribuisci {p.the} e le verdure {b.su} e completa con un filo d'olio e pepe.",
        ],
        fridge=3, minutes=10, tags=[], max=16,
    ),
    Template(
        key='n_affettato_frutta', type=SNACK,
        name='{p.label} con {f.label}',
        slots={
            'p': [
                opt('crudo', 'Prosciutto crudo', {'f_prosciutto_crudo': 50}, 'maiale', the='il prosciutto crudo'),
                opt('bresaola', 'Bresaola', {'f_bresaola': 50}, 'manzo', the='la bresaola'),
            ],
            'f': [
                opt('melone', 'melone', {'f_melone': 200},
                    prep='Elimina buccia e semi dal melone e taglialo a spicchi'),
                opt('fichi', 'fichi', {'f_fichi': 120}, prep='Lava i fichi e tagliali in quarti'),
                opt('pera', 'pera', {'f_pera': 150}, prep='Lava la pera e tagliala a spicchi'),
                opt('mela', 'mela', {'f_mela': 150}, prep='Lava la mela e tagliala a spicchi sottili'),
            ],
        },
        steps=[
            '{f.prep} e conservala in un contenitore ermetico con qualche goccia di limone.',
            'Porziona {p.the} in un contenitore a parte e abbinalo alla frutta al momento di mangiare.',
        ],
        base={'f_limone': 3},
        fridge=2, minutes=5, tags=['senza cottura'], max=6,
    ),
    Template(
        key='n_toast', type=SNACK,
        name='Toast integrale con {p.label} e {c.label}',
        base={'f_pane_int': 50},
        slots={
            'p': [
                opt('cotto', 'prosciutto cotto', {'f_prosciutto_cotto': 30}, 'maiale', the='il prosciutto cotto'),
                opt('crudo', 'prosciutto crudo', {'f_prosciutto_crudo': 25}, 'maiale', the='il prosciutto crudo'),
                opt('tonno', 'tonno', {'f_tonno': 40}, 'pesce', the='il tonno sgocciolato'),
            ],
            'c': [
                opt('mozzarella', 'mozzarella', {'f_mozzarella_light': 30}, the='la mozzarella light a fette'),
                opt('scamorza', 'scamorza', {'f_scamorza': 20}, the='la scamorza a fette'),
                opt('spalmabile', 'formaggio spalmabile', {'f_spalmabile': 25}, the='il formaggio spalmabile'),
            ],
        },
        steps=[
            'Taglia il pane integrale in due fette sottili e farciscile con {p.the} e {c.the}.',
            'Cuoci il toast in una piastra o in padella ben calda per 3-4 minuti per lato, finché il pane è dorato.',
            'Lascia raffreddare, avvolgi ogni toast nella carta forno e riscaldalo in padella o nel tostapane prima di mangiarlo.',
        ],
        fridge=3, freeze=True, minutes=10, tags=[], max=8,
    ),

    # --- Uova e torte salate mini -----------------------------------------
    Template(
        key='n_uova_sode', type=SNACK,
        name='Uova sode con {v.label} e salsa allo yogurt',
        base={'f_uova': 110, 'f_yogurt_greco': 50, 'f_senape': 5},
        slots={'v': crudi(CRUDI_VEG)},
        steps=[
            'Metti le uova in un pentolino, coprile di acqua fredda, porta a bollore e cuoci per 9 minuti.',
            'Raffreddale in acqua e ghiaccio e sgusciale.',
            '{v.prep}',
            'Mescola lo yogurt con la senape, un pizzico di sale e pepe e porziona la salsa in un vasetto.',
        ],
        protein='uova', fridge=4, minutes=15, tags=[], max=6,
    ),
    Template(
        key='n_frittatine', type=SNACK,
        name='Frittatine al forno con {v.label} e {c.label}',
        base={'f_uova': 55, 'f_albume': 60, 'f_olio': 3},
        slots={
            'v': veg(['zucchine', 'spinaci', 'asparagi', 'peperoni', 'broccoli', 'zucca', 'funghi', 'porri',
                      'carciofi', 'bietole', 'cavolo_nero', 'piselli_freschi', 'melanzane', 'cime_rapa'],
                     grams=70),
            'c': [
                opt('parmigiano', 'parmigiano', {'f_parmigiano': 10}, the='il parmigiano grattugiato'),
                opt('feta', 'feta', {'f_feta': 20}, the='la feta sbriciolata'),
                opt('pecorino', 'pecorino', {'f_pecorino': 10}, the='il pecorino grattugiato'),
                opt('scamorza', 'scamorza', {'f_scamorza': 15}, the='la scamorza a cubetti'),
            ],
        },
        steps=[
            "Scalda il forno a 180 °C e ungi uno stampo da muffin con un velo d'olio.",
            "{v.cut}; cuoci{v.pron} in padella con l'olio rimasto per {v.saute} minuti e lascia intiepidire.",
            'Sbatti le uova e gli albumi con {c.the}, sale e pepe, poi unisci le verdure.',
            'Versa il composto negli stampi e cuoci per 18-20 minuti, finché le frittatine sono gonfie e rapprese.',
        ],
        protein='uova', fridge=4, freeze=True, minutes=35, tags=['forno'], max=16,
    ),
    Template(
        key='n_tortine_ricotta', type=SNACK,
        name='Tortine di ricotta e {v.label}',
        base={'f_ricotta': 60, 'f_uova': 30, 'f_parmigiano': 8, 'f_pangrattato': 8, 'f_olio': 3},
        slots={
            'v': veg(['spinaci', 'bietole', 'zucchine', 'asparagi', 'carciofi', 'zucca', 'broccoli', 'porri',
                      'funghi', 'piselli_freschi', 'cime_rapa', 'cavolo_nero'], grams=70),
        },
        steps=[
            "{v.cut}; cuoci{v.pron} in padella con l'olio per {v.saute} minuti e lascia raffreddare.",
            "In una ciotola mescola la ricotta con l'uovo, il parmigiano e il pangrattato; regola di sale e pepe.",
            'Unisci le verdure, distribuisci il composto in pirottini da muffin e cuoci in forno a 180 °C per 25 minuti.',
            'Lascia raffreddare le tortine prima di sformarle.',
        ],
        protein='latticini', fridge=4, freeze=True, minutes=40, tags=['forno'], max=10,
    ),

    # --- Legumi croccanti --------------------------------------------------
    Template(
        key='n_legumi_tostati', type=SNACK,
        name='{l.label} tostati {s.label}',
        base={'f_olio': 5},
        slots={
            'l': [
                opt('ceci', 'Ceci', {'f_ceci': 150}, 'legumi', oven=35,
                    prep='Sciacqua i ceci, scolali e asciugali bene con un canovaccio eliminando le pellicine'),
                opt('edamame', 'Edamame', {'f_edamame': 130}, 'legumi', oven=25,
                    prep='Scongela gli edamame e asciugali bene con un canovaccio'),
            ],
            's': [
                opt('paprika', 'alla paprika', {'f_paprika': 2}, the='la paprika'),
                opt('curry', 'al curry', {'f_curry': 2}, the='il curry'),
                opt('rosmarino', 'al rosmarino', {'f_erbe': 3}, the='il rosmarino tritato'),
                opt('garam', 'al garam masala', {'f_garam': 2}, the='il garam masala'),
                opt('cumino', 'al cumino e limone', {'f_cumino': 2, 'f_limone': 5},
                    the='il cumino, la scorza grattugiata del limone'),
            ],
        },
        steps=[
            'Scalda il forno a 200 °C.',
            '{l.prep}.',
            "Condiscili con l'olio, {s.the} e un pizzico di sale e stendili in un solo strato su una teglia "
            'con carta forno.',
            'Cuoci per {l.oven} minuti, mescolando a metà cottura, finché sono croccanti.',
            'Lasciali raffreddare nel forno spento e conservali in un barattolo ben chiuso.',
        ],
        fridge=5, minutes=40, tags=['forno'], max=10,
    ),

    # --- Budini, pudding, smoothie ----------------------------------------
    Template(
        key='n_chia_pudding', type=SNACK,
        name='Chia pudding proteico {x.label} con {f.label}',
        base={'f_chia': 20, 'f_latte': 150, 'f_whey': 15},
        slots={
            'x': [
                opt('cacao', 'al cacao', {'f_cacao': 5}, the='il cacao'),
                opt('cannella', 'alla cannella', {'f_cannella': 1}, the='la cannella'),
                opt('cocco', 'al cocco', {'f_cocco_rape': 8}, the='il cocco rapé'),
            ],
            'f': fruit(grams=None, scale=0.8),
        },
        steps=[
            'In un barattolo mescola il latte con le proteine in polvere e {x.the} fino a scioglierle.',
            'Aggiungi i semi di chia, mescola bene e dopo 10 minuti mescola di nuovo per evitare grumi.',
            'Lascia riposare in frigo per almeno 4 ore o per tutta la notte.',
            '{f.cut}; aggiungi la frutta sul pudding al momento di mangiare.',
        ],
        protein='latticini', fridge=3, minutes=10, tags=['senza cottura'], max=14,
    ),
    Template(
        key='n_budino', type=SNACK,
        name='Budino proteico {x.label} con {f.label}',
        base={'f_latte': 200, 'f_amido_mais': 15, 'f_miele': 10, 'f_whey': 15},
        slots={
            'x': [
                opt('cacao', 'al cacao', {'f_cacao': 10}, the='il cacao'),
                opt('cocco', 'al cocco', {'f_cocco_rape': 8}, the='il cocco rapé'),
                opt('cannella', 'alla cannella', {'f_cannella': 1}, the='la cannella'),
            ],
            'f': fruit(['banana', 'pera', 'cachi', 'mandarini', 'kiwi', 'fragole', 'ciliegie', 'albicocche',
                        'pesche', 'lamponi', 'mirtilli', 'frutti_bosco', 'fichi'], scale=0.7),
        },
        steps=[
            "In un pentolino stempera l'amido di mais e {x.the} nel latte freddo, poi aggiungi il miele.",
            'Porta sul fuoco basso e mescola continuamente per 5-6 minuti, finché la crema si addensa.',
            'Togli dal fuoco, lascia intiepidire per 5 minuti e incorpora le proteine in polvere con una frusta.',
            'Versa in coppette, copri e lascia rassodare in frigo per almeno 2 ore.',
            '{f.cut}; aggiungi la frutta al momento di mangiare.',
        ],
        protein='latticini', fridge=3, minutes=15, tags=[], max=12,
    ),
    Template(
        key='n_smoothie', type=SNACK,
        name='Smoothie proteico {f.al} con {l.label}',
        base={'f_whey': 20},
        slots={
            'f': fruit_al(['banana', 'mela', 'pera', 'kiwi', 'cachi', 'fragole', 'ciliegie', 'albicocche',
                           'pesche', 'melone', 'mirtilli', 'lamponi', 'fichi', 'prugne'], grams=150),
            'l': [
                opt('latte', 'latte', {'f_latte': 200}, the='il latte'),
                opt('soia', 'bevanda di soia', {'f_bevanda_soia': 200}, the='la bevanda di soia'),
                opt('kefir', 'kefir', {'f_kefir': 200}, the='il kefir'),
            ],
        },
        steps=[
            '{f.cut}.',
            'Per prepararlo in anticipo, porziona la frutta in sacchetti gelo e congelala.',
            'Al momento frulla la frutta con {l.the} e le proteine in polvere fino a ottenere un composto liscio e cremoso.',
        ],
        protein='latticini', fridge=1, freeze=True, minutes=5, tags=['senza cottura', 'post-allenamento'], max=16,
    ),
    Template(
        key='n_shake', type=SNACK,
        name='Shake post-allenamento con banana, avena e {x.label}',
        base={'f_latte': 200, 'f_banana': 100, 'f_avena': 20, 'f_whey': 20},
        slots={
            'x': [
                opt('arachidi', "burro d'arachidi", {'f_burro_arachidi': 10}, the="il burro d'arachidi"),
                opt('cacao', 'cacao', {'f_cacao': 8}, the='il cacao'),
                opt('mandorle', 'crema di mandorle', {'f_crema_mandorle': 10}, the='la crema di mandorle'),
                opt('datteri', 'datteri', {'f_datteri': 15}, the='i datteri snocciolati'),
                opt('cannella', 'cannella', {'f_cannella': 1}, the='la cannella'),
            ],
        },
        steps=[
            "Per prepararlo in anticipo, metti in un sacchetto gelo la banana a rondelle, l'avena e {x.the} e congela.",
            'Al momento versa il contenuto del sacchetto nel frullatore con il latte e le proteine in polvere.',
            'Frulla per 1 minuto fino a ottenere un composto liscio.',
        ],
        protein='latticini', fridge=1, freeze=True, minutes=5, tags=['post-allenamento'], max=5,
    ),
]
