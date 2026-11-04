"""Librerie di opzioni riutilizzabili dai template.

Ogni opzione espone attributi da usare nei passi con la sintassi
`{slot.attr}`:

- verdure: `the` (con articolo), `pron` (lo/la/li/le, da attaccare ai verbi:
  "salta{v.pron}" -> "saltala"), `cut` (pulizia e taglio, frase completa),
  `saute`/`roast`/`boil` (minuti di cottura in padella, forno, acqua).
- proteine: `the`, `pron`, `cut`, `pan` e `oven` (minuti), `protein`.
- cereali: `the`, `cook` (frase completa di cottura).
- frutta e frutta secca: `the`, `cut`.
"""

from engine import opt


def _pick(lib: dict, keys, grams, scale):
    keys = keys or list(lib)
    out = []
    for k in keys:
        o = lib[k]
        g = grams if grams is not None else o['g']
        ing = {o['id']: g * scale}
        ing.update(o.get('plus', {}))
        out.append(opt(k, o['label'], ing, o.get('protein'),
                       **{a: v for a, v in o.items() if a not in ('id', 'g', 'label', 'plus', 'protein')}))
    return out


# --- Verdure ----------------------------------------------------------------

VEG = {
    'zucchine': dict(id='f_zucchine', label='zucchine', the='le zucchine', pron='le',
                     cut='spunta le zucchine e tagliale a rondelle', saute=8, roast=20, boil=5, g=180),
    'melanzane': dict(id='f_melanzane', label='melanzane', the='le melanzane', pron='le',
                      cut='taglia le melanzane a cubetti', saute=12, roast=25, boil=8, g=180),
    'peperoni': dict(id='f_peperoni', label='peperoni', the='i peperoni', pron='li',
                     cut='elimina semi e filamenti dai peperoni e tagliali a falde', saute=12, roast=25, boil=8, g=160),
    'pomodorini': dict(id='f_pomodorini', label='pomodorini', the='i pomodorini', pron='li',
                       cut='lava i pomodorini e tagliali a metà', saute=5, roast=15, boil=3, g=150),
    'fagiolini': dict(id='f_fagiolini', label='fagiolini', the='i fagiolini', pron='li',
                      cut='spunta i fagiolini e tagliali a metà', saute=10, roast=20, boil=8, g=180),
    'asparagi': dict(id='f_asparagi', label='asparagi', the='gli asparagi', pron='li',
                     cut='elimina la parte legnosa degli asparagi e tagliali a tocchetti', saute=8, roast=15, boil=6, g=180),
    'piselli_freschi': dict(id='f_piselli_freschi', label='piselli freschi', the='i piselli', pron='li',
                            cut='sgrana i piselli', saute=10, roast=15, boil=8, g=120),
    'fave': dict(id='f_fave_fresche', label='fave fresche', the='le fave', pron='le',
                 cut='sgrana le fave ed elimina la pellicina', saute=8, roast=15, boil=6, g=120),
    'carciofi': dict(id='f_carciofi', label='carciofi', the='i carciofi', pron='li',
                     cut='pulisci i carciofi, elimina le foglie dure e tagliali a spicchi sottili', saute=15, roast=25, boil=12, g=150),
    'zucca': dict(id='f_zucca', label='zucca', the='la zucca', pron='la',
                  cut='sbuccia la zucca, elimina i semi e tagliala a cubetti', saute=15, roast=25, boil=15, g=200),
    'cavolo_nero': dict(id='f_cavolo_nero', label='cavolo nero', the='il cavolo nero', pron='lo',
                        cut='elimina la costa centrale del cavolo nero e taglialo a strisce', saute=12, roast=15, boil=10, g=150),
    'cavolfiore': dict(id='f_cavolfiore', label='cavolfiore', the='il cavolfiore', pron='lo',
                       cut='dividi il cavolfiore in cimette', saute=12, roast=25, boil=10, g=200),
    'broccoli': dict(id='f_broccoli', label='broccoli', the='i broccoli', pron='li',
                     cut='dividi i broccoli in cimette e taglia a rondelle il gambo pelato', saute=10, roast=20, boil=7, g=200),
    'cavolini': dict(id='f_cavolini', label='cavolini di Bruxelles', the='i cavolini', pron='li',
                     cut='pulisci i cavolini di Bruxelles e tagliali a metà', saute=12, roast=25, boil=10, g=180),
    'verza': dict(id='f_verza', label='verza', the='la verza', pron='la',
                  cut='elimina le foglie esterne della verza e tagliala a striscioline', saute=12, roast=20, boil=10, g=180),
    'cavolo_rosso': dict(id='f_cavolo_rosso', label='cavolo rosso', the='il cavolo rosso', pron='lo',
                         cut='affetta finemente il cavolo rosso', saute=10, roast=20, boil=8, g=150),
    'cime_rapa': dict(id='f_cime_rapa', label='cime di rapa', the='le cime di rapa', pron='le',
                      cut='pulisci le cime di rapa tenendo foglie tenere e infiorescenze', saute=10, roast=15, boil=6, g=200),
    'finocchi': dict(id='f_finocchi', label='finocchi', the='i finocchi', pron='li',
                     cut='elimina le foglie esterne dei finocchi e tagliali a spicchi', saute=12, roast=25, boil=10, g=200),
    'porri': dict(id='f_porri', label='porri', the='i porri', pron='li',
                  cut='elimina la parte verde dura dei porri e tagliali a rondelle', saute=10, roast=20, boil=8, g=150),
    'radicchio': dict(id='f_radicchio', label='radicchio', the='il radicchio', pron='lo',
                      cut='taglia il radicchio a spicchi o a striscioline', saute=6, roast=12, boil=4, g=150),
    'spinaci': dict(id='f_spinaci', label='spinaci', the='gli spinaci', pron='li',
                    cut='lava bene gli spinaci', saute=4, roast=8, boil=3, g=180),
    'bietole': dict(id='f_bietole', label='bietole', the='le bietole', pron='le',
                    cut='lava le bietole e tagliale a strisce', saute=8, roast=12, boil=6, g=180),
    'funghi': dict(id='f_funghi', label='funghi', the='i funghi', pron='li',
                   cut='pulisci i funghi con un panno umido e affettali', saute=8, roast=18, boil=6, g=180),
    'porcini': dict(id='f_funghi_porcini', label='funghi porcini', the='i funghi', pron='li',
                    cut='pulisci i funghi porcini con un panno umido e tagliali a fettine', saute=10, roast=18, boil=6, g=150),
    'carote': dict(id='f_carote', label='carote', the='le carote', pron='le',
                   cut='pela le carote e tagliale a rondelle', saute=10, roast=25, boil=10, g=150),
    'patate_dolci': dict(id='f_patate_dolci', label='patate dolci', the='le patate dolci', pron='le',
                         cut='sbuccia le patate dolci e tagliale a cubetti', saute=15, roast=30, boil=15, g=180),
    'barbabietola': dict(id='f_barbabietola', label='barbabietola', the='la barbabietola', pron='la',
                         cut='taglia la barbabietola cotta a cubetti', saute=3, roast=10, boil=0, g=150),
}

# Gruppi tematici di verdure.
VEG_PAN = ['zucchine', 'melanzane', 'peperoni', 'fagiolini', 'asparagi', 'carciofi', 'zucca',
           'cavolo_nero', 'cavolfiore', 'broccoli', 'verza', 'cime_rapa', 'finocchi', 'porri',
           'radicchio', 'spinaci', 'bietole', 'funghi', 'porcini', 'piselli_freschi', 'fave']
VEG_OVEN = ['zucchine', 'melanzane', 'peperoni', 'pomodorini', 'asparagi', 'carciofi', 'zucca',
            'cavolfiore', 'broccoli', 'cavolini', 'finocchi', 'porri', 'radicchio', 'funghi',
            'carote', 'patate_dolci', 'fagiolini']
VEG_SOUP = ['zucca', 'cavolfiore', 'broccoli', 'porri', 'carote', 'piselli_freschi', 'asparagi',
            'zucchine', 'spinaci', 'funghi', 'porcini', 'patate_dolci', 'finocchi', 'cavolo_nero',
            'bietole', 'fave', 'carciofi', 'peperoni']
VEG_RISOTTO = ['zucca', 'asparagi', 'funghi', 'porcini', 'radicchio', 'zucchine', 'carciofi',
               'piselli_freschi', 'spinaci', 'porri', 'cavolo_nero', 'peperoni', 'melanzane',
               'broccoli', 'fave', 'carote']


def veg(keys=None, grams=None, scale=1.0):
    return _pick(VEG, keys, grams, scale)


# --- Proteine ---------------------------------------------------------------

PROT = {
    'pollo': dict(id='f_pollo', label='pollo', the='il pollo', pron='lo', protein='pollo',
                  cut='taglia il pollo a bocconcini', pan=8, oven=20, g=140),
    'sovracosce': dict(id='f_cosce_pollo', label='sovracosce di pollo', the='le sovracosce', pron='le',
                       protein='pollo', cut='elimina il grasso visibile dalle sovracosce e tagliale a pezzi',
                       pan=14, oven=30, g=150),
    'tacchino': dict(id='f_tacchino', label='tacchino', the='il tacchino', pron='lo', protein='tacchino',
                     cut='taglia il tacchino a straccetti', pan=7, oven=20, g=140),
    'manzo': dict(id='f_manzo', label='manzo', the='il manzo', pron='lo', protein='manzo',
                  cut='taglia il manzo a straccetti sottili', pan=4, oven=15, g=130),
    'vitello': dict(id='f_vitello', label='vitello', the='il vitello', pron='lo', protein='manzo',
                    cut='taglia il vitello a bocconcini', pan=6, oven=18, g=140),
    'maiale': dict(id='f_lonza', label='lonza di maiale', the='la lonza', pron='la', protein='maiale',
                   cut='taglia la lonza a bocconcini', pan=8, oven=22, g=130),
    'salmone': dict(id='f_salmone', label='salmone', the='il salmone', pron='lo', protein='pesce',
                    cut='elimina la pelle dal salmone e taglialo a cubotti', pan=6, oven=15, g=130),
    'merluzzo': dict(id='f_merluzzo', label='merluzzo', the='il merluzzo', pron='lo', protein='pesce',
                     cut='taglia il merluzzo a tranci', pan=6, oven=15, g=180),
    'orata': dict(id='f_orata', label='orata', the="l'orata", pron='la', protein='pesce',
                  cut="taglia l'orata a pezzi", pan=6, oven=15, g=160),
    'branzino': dict(id='f_branzino', label='branzino', the='il branzino', pron='lo', protein='pesce',
                     cut='taglia il branzino a pezzi', pan=6, oven=15, g=170),
    'trota': dict(id='f_trota', label='trota salmonata', the='la trota', pron='la', protein='pesce',
                  cut='taglia la trota a pezzi', pan=6, oven=15, g=160),
    'pesce_spada': dict(id='f_pesce_spada', label='pesce spada', the='il pesce spada', pron='lo',
                        protein='pesce', cut='taglia il pesce spada a cubetti', pan=5, oven=12, g=160),
    'tonno_fresco': dict(id='f_tonno_fresco', label='tonno fresco', the='il tonno', pron='lo',
                         protein='pesce', cut='taglia il tonno a cubetti', pan=3, oven=10, g=140),
    'gamberi': dict(id='f_gamberi', label='gamberi', the='i gamberi', pron='li', protein='pesce',
                    cut='elimina il filo intestinale dai gamberi', pan=4, oven=10, g=170),
    'calamari': dict(id='f_calamari', label='calamari', the='i calamari', pron='li', protein='pesce',
                     cut='taglia i calamari ad anelli', pan=8, oven=15, g=200),
    'tofu': dict(id='f_tofu', label='tofu', the='il tofu', pron='lo', protein='vegetale',
                 cut='tampona il tofu con carta da cucina e taglialo a cubetti', pan=8, oven=20, g=180),
    'tempeh': dict(id='f_tempeh', label='tempeh', the='il tempeh', pron='lo', protein='vegetale',
                   cut='taglia il tempeh a fettine', pan=8, oven=20, g=130),
    'seitan': dict(id='f_seitan', label='seitan', the='il seitan', pron='lo', protein='vegetale',
                   cut='taglia il seitan a straccetti', pan=6, oven=15, g=140),
    'ceci': dict(id='f_ceci', label='ceci', the='i ceci', pron='li', protein='legumi',
                 cut='sciacqua e sgocciola i ceci', pan=6, oven=20, g=220),
    'cannellini': dict(id='f_cannellini', label='cannellini', the='i cannellini', pron='li', protein='legumi',
                       cut='sciacqua e sgocciola i fagioli cannellini', pan=5, oven=15, g=230),
    'borlotti': dict(id='f_fagioli', label='borlotti', the='i borlotti', pron='li', protein='legumi',
                     cut='sciacqua e sgocciola i fagioli borlotti', pan=5, oven=15, g=230),
}

PROT_MEAT = ['pollo', 'sovracosce', 'tacchino', 'manzo', 'vitello', 'maiale']
PROT_FISH = ['salmone', 'merluzzo', 'orata', 'branzino', 'trota', 'pesce_spada', 'tonno_fresco',
             'gamberi', 'calamari']
PROT_VEG = ['tofu', 'tempeh', 'seitan', 'ceci', 'cannellini', 'borlotti']
PROT_LEAN = ['pollo', 'tacchino', 'manzo', 'maiale', 'salmone', 'merluzzo', 'gamberi', 'tofu', 'tempeh']


def prot(keys=None, grams=None, scale=1.0):
    return _pick(PROT, keys, grams, scale)


# --- Cereali e carboidrati --------------------------------------------------

CARB = {
    'riso': dict(id='f_riso', label='riso basmati', pron='lo', the='il riso', g=75,
                 cook='lessa il riso basmati in abbondante acqua salata per 12 minuti e scolalo'),
    'riso_int': dict(id='f_riso_int', label='riso integrale', pron='lo', the='il riso', g=75,
                     cook='lessa il riso integrale in acqua salata per 35-40 minuti e scolalo'),
    'riso_venere': dict(id='f_riso_venere', label='riso Venere', pron='lo', the='il riso', g=75,
                        cook='lessa il riso Venere in acqua salata per 18 minuti e scolalo'),
    'farro': dict(id='f_farro', label='farro', pron='lo', the='il farro', g=75,
                  cook='lessa il farro perlato in acqua salata per 20-25 minuti e scolalo'),
    'orzo': dict(id='f_orzo', label='orzo', pron='lo', the="l'orzo", g=75,
                 cook="lessa l'orzo perlato in acqua salata per 25 minuti e scolalo"),
    'quinoa': dict(id='f_quinoa', label='quinoa', pron='la', the='la quinoa', g=70,
                   cook='sciacqua la quinoa e cuocila nel doppio del suo volume di acqua salata per 15 minuti, finché assorbe tutta l\'acqua'),
    'couscous': dict(id='f_couscous', label='cous cous', pron='lo', the='il cous cous', g=75,
                     cook='versa sul cous cous lo stesso peso di acqua bollente salata, copri per 5 minuti e sgranalo con una forchetta'),
    'bulgur': dict(id='f_bulgur', label='bulgur', pron='lo', the='il bulgur', g=75,
                   cook='cuoci il bulgur nel doppio del suo volume di acqua salata per 12 minuti, poi sgranalo'),
    'grano_saraceno': dict(id='f_grano_saraceno', label='grano saraceno', pron='lo', the='il grano saraceno', g=75,
                           cook='tosta il grano saraceno in pentola per 2 minuti, poi cuocilo in acqua salata per 15 minuti e scolalo'),
    'miglio': dict(id='f_miglio', label='miglio', pron='lo', the='il miglio', g=70,
                   cook='sciacqua il miglio e cuocilo nel doppio del suo volume di acqua salata per 15 minuti'),
    'patate': dict(id='f_patate', label='patate', pron='le', the='le patate', g=300,
                   cook='taglia le patate a spicchi e cuocile in forno a 200 °C con un filo d\'olio per 35 minuti'),
}
CARB_GRAINS = ['riso', 'riso_int', 'riso_venere', 'farro', 'orzo', 'quinoa', 'couscous', 'bulgur',
               'grano_saraceno', 'miglio']


def carb(keys=None, grams=None, scale=1.0):
    return _pick(CARB, keys, grams, scale)


# --- Frutta -----------------------------------------------------------------

FRUIT = {
    'banana': dict(id='f_banana', label='banana', the='la banana', cut='taglia la banana a rondelle', g=100),
    'mela': dict(id='f_mela', label='mela', the='la mela', cut='taglia la mela a cubetti', g=130),
    'pera': dict(id='f_pera', label='pera', the='la pera', cut='taglia la pera a cubetti', g=130),
    'kiwi': dict(id='f_kiwi', label='kiwi', the='il kiwi', cut='sbuccia il kiwi e taglialo a rondelle', g=150),
    'arancia': dict(id='f_arancia', label='arancia', the="l'arancia", cut="pela l'arancia a vivo e tagliala a spicchi", g=150),
    'mandarini': dict(id='f_mandarini', label='mandarini', the='i mandarini', cut='sbuccia i mandarini e dividili a spicchi', g=150),
    'cachi': dict(id='f_cachi', label='cachi', the='il caco', cut='taglia il caco a metà e preleva la polpa', g=150),
    'melograno': dict(id='f_melograno', label='melograno', the='il melograno', cut='sgrana il melograno', g=80),
    'uva': dict(id='f_uva', label='uva', the="l'uva", cut="lava l'uva e taglia gli acini a metà", g=120),
    'fichi': dict(id='f_fichi', label='fichi', the='i fichi', cut='taglia i fichi in quarti', g=120),
    'fragole': dict(id='f_fragole', label='fragole', the='le fragole', cut='lava le fragole e tagliale a pezzi', g=150),
    'ciliegie': dict(id='f_ciliegie', label='ciliegie', the='le ciliegie', cut='snocciola le ciliegie', g=120),
    'albicocche': dict(id='f_albicocche', label='albicocche', the='le albicocche', cut='snocciola le albicocche e tagliale a spicchi', g=150),
    'pesche': dict(id='f_pesche', label='pesche', the='le pesche', cut='taglia le pesche a cubetti', g=150),
    'prugne': dict(id='f_prugne', label='prugne', the='le prugne', cut='snocciola le prugne e tagliale a spicchi', g=130),
    'melone': dict(id='f_melone', label='melone', the='il melone', cut='taglia il melone a cubetti', g=200),
    'mirtilli': dict(id='f_mirtilli', label='mirtilli', the='i mirtilli', cut='lava i mirtilli', g=100),
    'lamponi': dict(id='f_lamponi', label='lamponi', the='i lamponi', cut='sciacqua delicatamente i lamponi', g=100),
    'frutti_bosco': dict(id='f_frutti_bosco', label='frutti di bosco', the='i frutti di bosco',
                         cut='scongela i frutti di bosco', g=100),
}
FRUIT_ALL = list(FRUIT)


def fruit(keys=None, grams=None, scale=1.0):
    return _pick(FRUIT, keys, grams, scale)


# --- Frutta secca e semi ----------------------------------------------------

NUTS = {
    'mandorle': dict(id='f_mandorle', label='mandorle', the='le mandorle', g=15),
    'noci': dict(id='f_noci', label='noci', the='le noci', g=15),
    'nocciole': dict(id='f_nocciole', label='nocciole', the='le nocciole', g=15),
    'anacardi': dict(id='f_anacardi', label='anacardi', the='gli anacardi', g=15),
    'pistacchi': dict(id='f_pistacchi', label='pistacchi', the='i pistacchi', g=15),
    'semi_zucca': dict(id='f_semi_zucca', label='semi di zucca', the='i semi di zucca', g=15),
    'burro_arachidi': dict(id='f_burro_arachidi', label="burro d'arachidi", the="il burro d'arachidi", g=15),
    'crema_mandorle': dict(id='f_crema_mandorle', label='crema di mandorle', the='la crema di mandorle', g=15),
}
NUTS_WHOLE = ['mandorle', 'noci', 'nocciole', 'anacardi', 'pistacchi', 'semi_zucca']


def nuts(keys=None, grams=None, scale=1.0):
    return _pick(NUTS, keys, grams, scale)
