"""Bowl e piatti unici componibili: cereale + proteina + verdura."""

from engine import MAIN, Template, opt
from lib import (CARB_GRAINS, PROT_FISH, PROT_MEAT, PROT_VEG, VEG_OVEN, VEG_PAN, carb, prot,
                 veg)

TEMPLATES = [
    Template(
        key='bowl_forno', type=MAIN,
        name='Bowl di {c.label} con {p.label} e {v.label} al forno',
        base={'f_olio': 12, 'f_limone': 10, 'f_spezie': 1},
        slots={'c': carb(CARB_GRAINS), 'p': prot(PROT_MEAT + PROT_VEG), 'v': veg(VEG_OVEN, scale=1.1)},
        steps=[
            'Scalda il forno a 200 °C.',
            '{c.cook}.',
            '{v.cut}, condisci{v.pron} con metà dell\'olio, sale e spezie e cuoci{v.pron} in teglia per {v.roast} minuti.',
            '{p.cut}, condisci{p.pron} con il resto dell\'olio e aggiungi{p.pron} alla teglia negli ultimi {p.oven} minuti.',
            'Componi le bowl con {c.the}, {p.the} e {v.the}; completa con succo di limone.',
        ],
        fridge=4, minutes=45, tags=['bowl', 'forno'], max=40,
    ),
    Template(
        key='bowl_pesce', type=MAIN,
        name='Bowl di {c.label} con {p.label} e {v.label}',
        base={'f_olio': 12, 'f_limone': 15, 'f_aglio': 3, 'f_prezzemolo': 5},
        slots={'c': carb(CARB_GRAINS), 'p': prot(PROT_FISH), 'v': veg(VEG_PAN)},
        steps=[
            '{c.cook}.',
            '{v.cut}; salta{v.pron} in padella con metà dell\'olio e l\'aglio per {v.saute} minuti.',
            '{p.cut} e cuoci{p.pron} in padella con il resto dell\'olio per {p.pan} minuti.',
            'Componi le bowl e completa con prezzemolo tritato e succo di limone. Il pesce si conserva meglio separato dal cereale.',
        ],
        fridge=2, minutes=35, tags=['bowl'], max=35,
    ),
    Template(
        key='insalata_cereali', type=MAIN,
        name='Insalata di {c.label} con {p.label}, {v.label} e feta',
        base={'f_olio': 10, 'f_feta': 30, 'f_basilico': 3, 'f_cipolla_rossa': 20},
        slots={
            'c': carb(['farro', 'orzo', 'quinoa', 'couscous', 'bulgur', 'riso_venere']),
            'p': prot(['ceci', 'cannellini', 'pollo', 'tacchino', 'gamberi'], scale=0.9),
            'v': veg(['zucchine', 'peperoni', 'pomodorini', 'fagiolini', 'asparagi', 'melanzane',
                      'zucca', 'broccoli', 'finocchi', 'carote', 'barbabietola']),
        },
        steps=[
            '{c.cook}, poi allarga{c.pron} su un vassoio a raffreddare.',
            '{v.cut}; salta{v.pron} in padella con un filo d\'olio per {v.saute} minuti e fai intiepidire.',
            "{p.cut}; cuoci{p.pron} in padella con un filo d'olio per {p.pan} minuti.",
            'Affetta sottilmente la cipolla rossa e sbriciola la feta.',
            'Unisci tutto, condisci con l\'olio rimasto e il basilico spezzettato. Si mangia fredda.',
        ],
        fridge=4, minutes=35, tags=['insalata', 'freddo'], max=30,
    ),
]
