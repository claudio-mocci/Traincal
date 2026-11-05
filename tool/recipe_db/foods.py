"""Database degli alimenti.

Valori indicativi per 100 g di prodotto crudo/secco (come si acquista),
ricavati dalle tabelle CREA e USDA; carboidrati al netto della fibra.

`season` = mesi di stagione in Italia (1-12); None = sempre disponibile
(conservati, surgelati, prodotti da serra tutto l'anno, importati).
`diet` = origine animale (meat, fish, dairy, egg, honey) o None se vegetale.
`gluten` = contiene glutine.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class Food:
    id: str
    name: str
    cat: str
    kcal: float
    p: float
    c: float
    f: float
    unit: float | None = None
    unit_name: str | None = None
    pack: float | None = None
    season: tuple[int, ...] | None = None
    diet: str | None = None
    gluten: bool = False


M, D, G, L, FR, V, N, P, Z = (
    'meatFish', 'dairyEggs', 'grains', 'legumes', 'fruit', 'vegetables',
    'nutsSeeds', 'pantry', 'frozen',
)

# Stagioni ricorrenti
WINTER_VEG = (10, 11, 12, 1, 2, 3)
COLD = (10, 11, 12, 1, 2, 3, 4)
SUMMER = (6, 7, 8, 9)


def _m(*months):
    return tuple(months)


FOODS: list[Food] = [
    # --- Carne -------------------------------------------------------------
    Food('f_pollo', 'Petto di pollo', M, 110, 23, 0, 1.5, pack=500, diet='meat'),
    Food('f_cosce_pollo', 'Sovracosce di pollo disossate', M, 125, 19.5, 0, 5, pack=500, diet='meat'),
    Food('f_macinato_pollo', 'Macinato di pollo e tacchino', M, 115, 20, 0, 4, pack=400, diet='meat'),
    Food('f_tacchino', 'Fesa di tacchino', M, 107, 24, 0, 1.2, pack=500, diet='meat'),
    Food('f_manzo', 'Manzo magro (girello)', M, 120, 21.5, 0, 3.5, pack=400, diet='meat'),
    Food('f_spezzatino', 'Manzo per spezzatino', M, 135, 20, 0, 6, pack=500, diet='meat'),
    Food('f_macinato', 'Macinato di manzo 5%', M, 137, 21, 0, 5.5, pack=500, diet='meat'),
    Food('f_vitello', 'Fesa di vitello', M, 92, 20.7, 0, 1, pack=400, diet='meat'),
    Food('f_lonza', 'Lonza di maiale', M, 146, 21, 0, 7, pack=500, diet='meat'),
    Food('f_salsiccia', 'Salsiccia di suino', M, 304, 15.4, 0.6, 26.7, pack=400, diet='meat'),
    Food('f_bresaola', 'Bresaola', M, 151, 32, 0.4, 2, pack=80, diet='meat'),
    Food('f_prosciutto_cotto', 'Prosciutto cotto', M, 132, 19.8, 0.9, 5, pack=100, diet='meat'),
    Food('f_prosciutto_crudo', 'Prosciutto crudo sgrassato', M, 160, 28, 0, 5.5, pack=80, diet='meat'),
    Food('f_speck', 'Speck', M, 300, 28, 0.5, 20.9, pack=100, diet='meat'),

    # --- Pesce -------------------------------------------------------------
    Food('f_salmone', 'Salmone fresco', M, 200, 20, 0, 13, pack=300, diet='fish'),
    Food('f_salmone_affumicato', 'Salmone affumicato', M, 147, 25.4, 0, 4.5, pack=100, diet='fish'),
    Food('f_merluzzo', 'Merluzzo / nasello', M, 75, 17, 0, 0.7, pack=400, diet='fish'),
    Food('f_baccala', 'Baccalà ammollato', M, 95, 21.6, 0, 0.8, pack=400, diet='fish'),
    Food('f_orata', 'Orata (filetti)', M, 121, 19.8, 0, 3.8, pack=300, diet='fish'),
    Food('f_branzino', 'Branzino (filetti)', M, 97, 18, 0, 2.5, pack=300, diet='fish'),
    Food('f_trota', 'Trota salmonata (filetti)', M, 119, 19.8, 0, 4.4, pack=300, diet='fish'),
    Food('f_sgombro', 'Sgombro (filetti)', M, 170, 17, 0, 11, pack=300, diet='fish'),
    Food('f_alici', 'Alici fresche', M, 96, 16.8, 1.5, 2.6, pack=300, season=_m(4, 5, 6, 7, 8, 9), diet='fish'),
    Food('f_pesce_spada', 'Pesce spada', M, 109, 16.9, 1, 4.2, pack=300, season=_m(5, 6, 7, 8, 9), diet='fish'),
    Food('f_tonno_fresco', 'Tonno fresco', M, 144, 23, 0, 5, pack=300, season=_m(5, 6, 7, 8, 9), diet='fish'),
    Food('f_gamberi', 'Gamberi sgusciati', M, 85, 18, 0.9, 0.8, pack=300, diet='fish'),
    Food('f_calamari', 'Calamari puliti', M, 68, 12.6, 0.6, 1.7, pack=400, diet='fish'),
    Food('f_polpo', 'Polpo pulito', M, 57, 10.6, 1.4, 1, pack=600, diet='fish'),
    Food('f_cozze', 'Cozze sgusciate', M, 84, 11.7, 3.4, 2.7, pack=200, diet='fish'),
    Food('f_tonno', 'Tonno al naturale (sgocciolato)', M, 108, 25, 0, 1,
         unit=52, unit_name='scatoletta', pack=156, diet='fish'),
    Food('f_sgombro_scatola', 'Sgombro al naturale (sgocciolato)', M, 160, 21, 0, 8.5,
         unit=90, unit_name='scatoletta', pack=90, diet='fish'),

    # --- Latticini e uova --------------------------------------------------
    Food('f_uova', 'Uova', D, 128, 12.4, 0, 8.7, unit=55, unit_name='uovo', diet='egg'),
    Food('f_albume', 'Albume', D, 43, 10.7, 0.7, 0, pack=500, diet='egg'),
    Food('f_yogurt_greco', 'Yogurt greco 0%', D, 57, 10, 4, 0.2, pack=500, diet='dairy'),
    Food('f_yogurt', 'Yogurt bianco magro', D, 43, 4.3, 5.8, 0.2, pack=500, diet='dairy'),
    Food('f_skyr', 'Skyr', D, 63, 11, 4, 0.2, pack=450, diet='dairy'),
    Food('f_kefir', 'Kefir', D, 41, 3.3, 4.5, 1, pack=500, diet='dairy'),
    Food('f_latte', 'Latte parzialmente scremato', D, 46, 3.5, 5, 1.6, pack=1000, diet='dairy'),
    Food('f_fiocchi_latte', 'Fiocchi di latte', D, 98, 11.5, 3, 4.5, pack=200, diet='dairy'),
    Food('f_ricotta', 'Ricotta vaccina', D, 146, 8.8, 3.5, 10.9, pack=250, diet='dairy'),
    Food('f_mozzarella_light', 'Mozzarella light', D, 163, 19, 1.5, 9, pack=125, diet='dairy'),
    Food('f_mozzarella', 'Mozzarella fior di latte', D, 253, 18.7, 0.7, 19.5, pack=125, diet='dairy'),
    Food('f_scamorza', 'Scamorza', D, 334, 25, 1, 25.6, pack=200, diet='dairy'),
    Food('f_parmigiano', 'Parmigiano Reggiano', D, 392, 33.5, 0, 28.1, pack=200, diet='dairy'),
    Food('f_pecorino', 'Pecorino romano', D, 387, 28.5, 0.2, 31, pack=200, diet='dairy'),
    Food('f_feta', 'Feta', D, 264, 14, 4, 21, pack=200, diet='dairy'),
    Food('f_spalmabile', 'Formaggio spalmabile light', D, 140, 8, 4, 10, pack=150, diet='dairy'),
    Food('f_burro', 'Burro', D, 717, 0.8, 0.1, 81, pack=125, diet='dairy'),
    Food('f_whey', 'Proteine whey', D, 380, 78, 7, 5, pack=1000, diet='dairy'),

    # --- Cereali, pane e patate -------------------------------------------
    Food('f_avena', "Fiocchi d'avena", G, 370, 13.5, 60, 7, pack=500, gluten=True),
    Food('f_muesli', 'Muesli senza zuccheri aggiunti', G, 360, 10, 62, 6.5, pack=500, gluten=True),
    Food('f_pasta', 'Pasta di semola', G, 355, 12.5, 71, 1.5, pack=500, gluten=True),
    Food('f_pasta_int', 'Pasta integrale', G, 340, 13.5, 64, 2.5, pack=500, gluten=True),
    Food('f_pasta_legumi', 'Pasta di lenticchie rosse', G, 340, 25, 50, 2.5, pack=250),
    Food('f_lasagne', 'Sfoglie per lasagne (secche)', G, 355, 12.5, 71, 1.5, pack=500, gluten=True),
    Food('f_gnocchi', 'Gnocchi di patate', G, 160, 3.5, 34, 0.4, pack=500, gluten=True),
    Food('f_noodles_riso', 'Noodles di riso', G, 360, 6, 80, 0.6, pack=250),
    Food('f_riso', 'Riso basmati', G, 355, 7.5, 79, 0.6, pack=1000),
    Food('f_riso_carnaroli', 'Riso Carnaroli', G, 350, 7, 79, 0.5, pack=1000),
    Food('f_riso_int', 'Riso integrale', G, 360, 7.5, 74, 2.7, pack=1000),
    Food('f_riso_venere', 'Riso Venere', G, 360, 8, 74, 3, pack=500),
    Food('f_farro', 'Farro perlato', G, 340, 14, 67, 2.5, pack=500, gluten=True),
    Food('f_orzo', 'Orzo perlato', G, 350, 10, 72, 1.5, pack=500, gluten=True),
    Food('f_quinoa', 'Quinoa', G, 368, 14, 64, 6, pack=500),
    Food('f_couscous', 'Cous cous', G, 370, 13, 74, 0.6, pack=500, gluten=True),
    Food('f_bulgur', 'Bulgur', G, 342, 12.3, 63, 1.3, pack=500, gluten=True),
    Food('f_grano_saraceno', 'Grano saraceno', G, 343, 13.3, 62, 3.4, pack=500),
    Food('f_miglio', 'Miglio decorticato', G, 378, 11, 72, 4.2, pack=500),
    Food('f_polenta', 'Farina di mais per polenta', G, 362, 8.7, 77, 2.7, pack=500),
    Food('f_farina', 'Farina tipo 0', G, 340, 11, 73, 1, pack=1000, gluten=True),
    Food('f_farina_int', 'Farina integrale', G, 330, 12, 64, 2, pack=1000, gluten=True),
    Food('f_farina_ceci', 'Farina di ceci', G, 360, 21, 54, 6.5, pack=500),
    Food('f_pangrattato', 'Pangrattato', G, 350, 12, 72, 2, pack=500, gluten=True),
    Food('f_pane', 'Pane comune', G, 270, 8.5, 56, 1, pack=500, gluten=True),
    Food('f_pane_int', 'Pane integrale', G, 245, 9, 44, 3, pack=500, gluten=True),
    Food('f_fette', 'Fette biscottate', G, 405, 11, 76, 6, pack=300, gluten=True),
    Food('f_gallette', 'Gallette di riso', G, 385, 8, 81, 3, unit=8, unit_name='galletta', pack=120),
    Food('f_crackers', 'Cracker integrali', G, 420, 10, 66, 12, unit=25, unit_name='pacchetto', pack=250, gluten=True),
    Food('f_tortilla', 'Tortilla integrale', G, 300, 9, 48, 7, unit=62, unit_name='tortilla', pack=370, gluten=True),
    Food('f_piadina', 'Piadina', G, 320, 8, 50, 9, unit=100, unit_name='piadina', pack=400, gluten=True),
    Food('f_patate', 'Patate', G, 77, 2, 17, 0.1, pack=1500),
    Food('f_patate_dolci', 'Patate dolci', G, 86, 1.6, 20, 0.1, pack=1000,
         season=_m(9, 10, 11, 12, 1, 2, 3)),

    # --- Legumi e proteine vegetali ---------------------------------------
    Food('f_ceci', 'Ceci in scatola (sgocciolati)', L, 119, 7, 16.5, 2.5, pack=240),
    Food('f_fagioli', 'Fagioli borlotti in scatola (sgocciolati)', L, 100, 6.5, 15, 0.5, pack=240),
    Food('f_cannellini', 'Fagioli cannellini in scatola (sgocciolati)', L, 92, 6.5, 13, 0.5, pack=240),
    Food('f_fagioli_neri', 'Fagioli neri in scatola (sgocciolati)', L, 91, 6, 13, 0.4, pack=240),
    Food('f_lenticchie', 'Lenticchie secche', L, 330, 24, 51, 1.5, pack=500),
    Food('f_lenticchie_rosse', 'Lenticchie rosse decorticate', L, 340, 24, 53, 1.5, pack=500),
    Food('f_fave_secche', 'Fave secche decorticate', L, 340, 27, 47, 2, pack=500),
    Food('f_tofu', 'Tofu', L, 130, 13, 2, 7.5, pack=200),
    Food('f_tempeh', 'Tempeh', L, 192, 20, 7.6, 10.8, pack=200),
    Food('f_seitan', 'Seitan', L, 130, 25, 4, 2, pack=200, gluten=True),

    # --- Frutta ------------------------------------------------------------
    Food('f_banana', 'Banana', FR, 89, 1.1, 20, 0.3, unit=120, unit_name='banana'),
    Food('f_mela', 'Mela', FR, 52, 0.3, 12.5, 0.2, unit=150, unit_name='mela',
         season=_m(8, 9, 10, 11, 12, 1, 2, 3, 4)),
    Food('f_pera', 'Pera', FR, 57, 0.4, 13, 0.1, unit=170, unit_name='pera',
         season=_m(8, 9, 10, 11, 12, 1, 2)),
    Food('f_kiwi', 'Kiwi', FR, 61, 1.1, 13, 0.5, unit=75, unit_name='kiwi',
         season=_m(11, 12, 1, 2, 3, 4)),
    Food('f_arancia', 'Arancia', FR, 47, 0.9, 10.5, 0.1, unit=180, unit_name='arancia',
         season=_m(11, 12, 1, 2, 3, 4)),
    Food('f_mandarini', 'Mandarini / clementine', FR, 53, 0.8, 12, 0.3, unit=80, unit_name='mandarino',
         season=_m(11, 12, 1, 2)),
    Food('f_pompelmo', 'Pompelmo', FR, 42, 0.8, 9.5, 0.1, unit=300, unit_name='pompelmo',
         season=_m(11, 12, 1, 2, 3, 4)),
    Food('f_limone', 'Limone', FR, 29, 1.1, 6.5, 0.3, unit=100, unit_name='limone'),
    Food('f_cachi', 'Cachi', FR, 70, 0.6, 16, 0.2, unit=200, unit_name='caco',
         season=_m(10, 11, 12)),
    Food('f_melograno', 'Melograno (arilli)', FR, 83, 1.7, 15, 1.2, unit=200, unit_name='melograno',
         season=_m(9, 10, 11, 12)),
    Food('f_uva', 'Uva', FR, 69, 0.7, 16, 0.2, pack=500, season=_m(8, 9, 10)),
    Food('f_fichi', 'Fichi', FR, 74, 0.8, 16, 0.3, unit=50, unit_name='fico', season=_m(7, 8, 9)),
    Food('f_fragole', 'Fragole', FR, 32, 0.7, 6, 0.3, pack=500, season=_m(4, 5, 6)),
    Food('f_ciliegie', 'Ciliegie', FR, 63, 1, 14, 0.2, pack=500, season=_m(5, 6, 7)),
    Food('f_albicocche', 'Albicocche', FR, 48, 1.4, 9.5, 0.4, unit=40, unit_name='albicocca',
         season=_m(6, 7)),
    Food('f_pesche', 'Pesche', FR, 39, 0.9, 8.5, 0.3, unit=180, unit_name='pesca', season=_m(6, 7, 8, 9)),
    Food('f_prugne', 'Prugne / susine', FR, 46, 0.7, 10, 0.3, unit=50, unit_name='prugna',
         season=_m(7, 8, 9)),
    Food('f_melone', 'Melone', FR, 34, 0.8, 8, 0.2, pack=1500, season=_m(6, 7, 8, 9)),
    Food('f_anguria', 'Anguria', FR, 30, 0.6, 7.5, 0.2, pack=3000, season=_m(6, 7, 8)),
    Food('f_mirtilli', 'Mirtilli freschi', FR, 57, 0.7, 12, 0.3, pack=125, season=_m(6, 7, 8, 9)),
    Food('f_lamponi', 'Lamponi freschi', FR, 52, 1.2, 5.5, 0.7, pack=125, season=_m(6, 7, 8, 9)),
    Food('f_castagne', 'Castagne', FR, 196, 2.9, 42, 1.7, pack=500, season=_m(10, 11, 12)),
    Food('f_ananas', 'Ananas', FR, 50, 0.5, 12, 0.1, unit=1000, unit_name='ananas'),
    Food('f_avocado', 'Avocado', FR, 160, 2, 2, 14.7, unit=150, unit_name='avocado'),
    Food('f_datteri', 'Datteri secchi', FR, 280, 2.5, 66, 0.4, pack=200),
    Food('f_uvetta', 'Uvetta', FR, 299, 3, 75, 0.5, pack=250),
    Food('f_albicocche_secche', 'Albicocche secche', FR, 240, 3.4, 55, 0.5, pack=200),
    Food('f_fichi_secchi', 'Fichi secchi', FR, 250, 3.3, 57, 0.9, pack=250),

    # --- Verdura -----------------------------------------------------------
    Food('f_zucchine', 'Zucchine', V, 17, 1.2, 3.1, 0.3, season=_m(5, 6, 7, 8, 9)),
    Food('f_melanzane', 'Melanzane', V, 18, 1.1, 2.6, 0.1, season=_m(6, 7, 8, 9, 10)),
    Food('f_peperoni', 'Peperoni', V, 27, 1, 5, 0.3, season=_m(6, 7, 8, 9, 10)),
    Food('f_pomodorini', 'Pomodorini', V, 20, 1, 3.9, 0.2, season=SUMMER),
    Food('f_pomodori', 'Pomodori da insalata', V, 18, 0.9, 3.5, 0.2, season=SUMMER),
    Food('f_cetrioli', 'Cetrioli', V, 14, 0.7, 2.5, 0.1, season=_m(5, 6, 7, 8, 9)),
    Food('f_fagiolini', 'Fagiolini', V, 31, 1.8, 5, 0.2, season=_m(6, 7, 8, 9)),
    Food('f_fiori_zucca', 'Fiori di zucca', V, 12, 1, 1, 0.2, pack=150, season=_m(5, 6, 7)),
    Food('f_asparagi', 'Asparagi', V, 24, 3.6, 2, 0.2, pack=500, season=_m(3, 4, 5, 6)),
    Food('f_fave_fresche', 'Fave fresche sgranate', V, 64, 5.2, 8.5, 0.4, season=_m(4, 5, 6)),
    Food('f_piselli_freschi', 'Piselli freschi sgranati', V, 76, 5.5, 11, 0.4, season=_m(4, 5, 6)),
    Food('f_carciofi', 'Carciofi (cuori puliti)', V, 33, 2.7, 2.5, 0.2, unit=60, unit_name='carciofo',
         season=_m(11, 12, 1, 2, 3, 4, 5)),
    Food('f_zucca', 'Zucca (polpa)', V, 26, 1.1, 5.5, 0.1, season=_m(9, 10, 11, 12, 1)),
    Food('f_cavolo_nero', 'Cavolo nero', V, 43, 3.3, 5, 0.9, season=WINTER_VEG),
    Food('f_cavolfiore', 'Cavolfiore', V, 25, 2, 3, 0.3, season=COLD),
    Food('f_broccoli', 'Broccoli', V, 34, 2.8, 4.5, 0.4, season=COLD),
    Food('f_cavolini', 'Cavolini di Bruxelles', V, 43, 3.4, 5, 0.3, season=_m(10, 11, 12, 1, 2)),
    Food('f_verza', 'Verza', V, 27, 2.1, 3.5, 0.1, season=WINTER_VEG),
    Food('f_cavolo_rosso', 'Cavolo cappuccio rosso', V, 31, 1.4, 5.5, 0.2, season=WINTER_VEG),
    Food('f_cime_rapa', 'Cime di rapa', V, 28, 3, 2, 0.3, season=_m(10, 11, 12, 1, 2, 3)),
    Food('f_finocchi', 'Finocchi', V, 31, 1.2, 4, 0.2, season=COLD),
    Food('f_porri', 'Porri', V, 35, 2.1, 5.2, 0.1, season=_m(10, 11, 12, 1, 2, 3, 4)),
    Food('f_radicchio', 'Radicchio rosso', V, 23, 1.4, 3.5, 0.2, season=_m(10, 11, 12, 1, 2, 3)),
    Food('f_spinaci', 'Spinaci', V, 23, 2.9, 1.6, 0.4, season=_m(10, 11, 12, 1, 2, 3, 4, 5)),
    Food('f_bietole', 'Bietole', V, 19, 1.8, 2.8, 0.1, season=_m(9, 10, 11, 12, 1, 2, 3, 4, 5, 6)),
    Food('f_valeriana', 'Valeriana / songino', V, 21, 2, 2.5, 0.4, pack=125,
         season=_m(10, 11, 12, 1, 2, 3, 4)),
    Food('f_barbabietola', 'Barbabietola cotta', V, 43, 1.6, 8, 0.2, pack=500,
         season=_m(6, 7, 8, 9, 10, 11)),
    Food('f_funghi', 'Funghi champignon', V, 22, 3.1, 3.3, 0.3),
    Food('f_funghi_porcini', 'Funghi porcini / misti di bosco', V, 26, 3.9, 1, 0.4,
         season=_m(9, 10, 11)),
    Food('f_carote', 'Carote', V, 41, 0.9, 8, 0.2),
    Food('f_cipolla', 'Cipolla', V, 40, 1.1, 9, 0.1),
    Food('f_cipolla_rossa', 'Cipolla rossa', V, 40, 1.1, 9, 0.1),
    Food('f_sedano', 'Sedano', V, 16, 0.7, 3, 0.2),
    Food('f_aglio', 'Aglio', V, 149, 6.4, 30, 0.5, unit=5, unit_name='spicchio'),
    Food('f_zenzero', 'Zenzero fresco', V, 80, 1.8, 16, 0.8, pack=100),
    Food('f_insalata', 'Insalata mista', V, 17, 1.3, 2.5, 0.2),
    Food('f_rucola', 'Rucola', V, 25, 2.6, 2, 0.7, pack=125, season=_m(3, 4, 5, 6, 7, 8, 9, 10, 11)),
    Food('f_basilico', 'Basilico fresco', V, 23, 3.2, 1, 0.6, pack=30),
    Food('f_prezzemolo', 'Prezzemolo fresco', V, 36, 3, 6, 0.8, pack=30),
    Food('f_erbe', 'Erbe aromatiche fresche (rosmarino, salvia, timo)', V, 40, 2, 5, 1, pack=30),

    # --- Frutta secca e semi ----------------------------------------------
    Food('f_mandorle', 'Mandorle', N, 580, 21, 10, 50, pack=200),
    Food('f_noci', 'Noci sgusciate', N, 654, 15, 7, 65, pack=150),
    Food('f_nocciole', 'Nocciole', N, 628, 15, 7, 61, pack=150),
    Food('f_anacardi', 'Anacardi', N, 553, 18, 30, 44, pack=150),
    Food('f_pistacchi', 'Pistacchi sgusciati', N, 560, 20, 18, 45, pack=150),
    Food('f_pinoli', 'Pinoli', N, 673, 13.7, 13, 68, pack=100),
    Food('f_arachidi', 'Arachidi tostate', N, 590, 26, 13, 50, pack=200),
    Food('f_burro_arachidi', "Burro d'arachidi", N, 590, 25, 16, 50, pack=350),
    Food('f_crema_mandorle', 'Crema di mandorle 100%', N, 610, 21, 9, 54, pack=200),
    Food('f_tahina', 'Tahina (crema di sesamo)', N, 595, 17, 21, 54, pack=200),
    Food('f_chia', 'Semi di chia', N, 486, 17, 8, 31, pack=250),
    Food('f_semi_lino', 'Semi di lino', N, 534, 18, 2, 42, pack=250),
    Food('f_semi_zucca', 'Semi di zucca', N, 560, 30, 10, 49, pack=200),
    Food('f_semi_girasole', 'Semi di girasole', N, 584, 21, 11, 51, pack=200),
    Food('f_sesamo', 'Semi di sesamo', N, 573, 18, 12, 50, pack=150),
    Food('f_cocco_rape', 'Cocco rapé', N, 660, 7, 7, 64, pack=150),

    # --- Dispensa e condimenti ---------------------------------------------
    Food('f_olio', "Olio extravergine d'oliva", P, 899, 0, 0, 99.9, pack=1000),
    Food('f_passata', 'Passata di pomodoro', P, 36, 1.5, 6.5, 0.2, pack=700),
    Food('f_pelati', 'Pomodori pelati', P, 22, 1.2, 3.5, 0.2, pack=400),
    Food('f_concentrato', 'Concentrato di pomodoro', P, 82, 4.3, 16, 0.5, pack=130),
    Food('f_pomodori_secchi', 'Pomodori secchi', P, 260, 14, 43, 3, pack=100),
    Food('f_olive', 'Olive nere / taggiasche denocciolate', P, 140, 1, 1, 15, pack=150),
    Food('f_capperi', 'Capperi dissalati', P, 23, 2.4, 2, 0.9, pack=100),
    Food('f_mais', 'Mais dolce in scatola (sgocciolato)', P, 86, 3, 16, 1.2, pack=150),
    Food('f_brodo', 'Brodo vegetale (pronto o da dado)', P, 6, 0.3, 1, 0.1, pack=1000),
    Food('f_latte_cocco', 'Latte di cocco light', P, 73, 0.7, 2, 7, pack=400),
    Food('f_bevanda_soia', 'Bevanda di soia senza zuccheri', P, 33, 3.3, 0.7, 1.8, pack=1000),
    Food('f_miele', 'Miele', P, 304, 0.3, 82, 0, pack=500, diet='honey'),
    Food('f_sciroppo_acero', "Sciroppo d'acero", P, 260, 0, 67, 0, pack=250),
    Food('f_marmellata', 'Confettura extra di frutta', P, 220, 0.5, 54, 0, pack=340),
    Food('f_zucchero_canna', 'Zucchero di canna', P, 390, 0, 99, 0, pack=1000),
    Food('f_cacao', 'Cacao amaro in polvere', P, 355, 20.4, 11.5, 25.6, pack=75),
    Food('f_cioccolato', 'Cioccolato fondente 85%', P, 600, 10, 19, 52, pack=100),
    Food('f_lievito', 'Lievito per dolci', P, 100, 0, 25, 0, pack=16),
    Food('f_soia', 'Salsa di soia', P, 53, 8, 5, 0.6, pack=150, gluten=True),
    Food('f_aceto', 'Aceto balsamico', P, 88, 0.5, 17, 0, pack=250),
    Food('f_senape', 'Senape', P, 66, 4.4, 5.8, 4, pack=200),
    Food('f_pesto', 'Pesto alla genovese', P, 450, 5, 6, 45, pack=190, diet='dairy'),
    Food('f_curry', 'Curry in polvere', P, 325, 14, 25, 14, pack=50),
    Food('f_paprika', 'Paprika dolce', P, 282, 14, 20, 13, pack=50),
    Food('f_cumino', 'Cumino in polvere', P, 375, 18, 34, 22, pack=50),
    Food('f_curcuma', 'Curcuma in polvere', P, 312, 9.7, 45, 3.3, pack=50),
    Food('f_cannella', 'Cannella in polvere', P, 247, 4, 27, 1.2, pack=50),
    Food('f_spezie', 'Spezie miste (origano, peperoncino, pepe)', P, 270, 9, 26, 4, pack=50),
    Food('f_garam', 'Garam masala', P, 330, 13, 40, 15, pack=50),

    # --- Surgelati ---------------------------------------------------------
    Food('f_frutti_bosco', 'Frutti di bosco surgelati', Z, 45, 0.8, 8, 0.3, pack=300),
    Food('f_piselli', 'Piselli surgelati', Z, 75, 5.4, 10, 0.4, pack=450),
    Food('f_edamame', 'Edamame surgelati', Z, 121, 12, 9, 5, pack=400),
    Food('f_spinaci_surg', 'Spinaci surgelati', Z, 25, 3, 1.5, 0.4, pack=450),
    Food('f_minestrone_surg', 'Verdure per minestrone surgelate', Z, 35, 2, 5.5, 0.3, pack=1000),
    # Gelateria: gusti a base latte (fiordilatte, nocciola, cioccolato...) e
    # alla frutta (sorbetti), cono in cialda.
    Food('f_gelato_crema', 'Gelato artigianale (gusti crema)', Z, 210, 4.5, 26, 10,
         diet='dairy'),
    Food('f_gelato_frutta', 'Gelato artigianale (gusti frutta)', Z, 120, 0.5, 29, 0.3),
    Food('f_cono', 'Cono in cialda', G, 400, 8, 80, 5, unit=12, unit_name='cono',
         gluten=True),
]

FOODS_BY_ID = {f.id: f for f in FOODS}
assert len(FOODS_BY_ID) == len(FOODS), 'id duplicati negli alimenti'


def register(extra: list[Food]):
    """Aggiunge gli alimenti definiti da un pacchetto di template
    (`EXTRA_FOODS`)."""
    for food in extra:
        if food.id in FOODS_BY_ID:
            if FOODS_BY_ID[food.id] != food:
                raise ValueError(f'alimento {food.id} definito due volte in modo diverso')
            continue
        FOODS.append(food)
        FOODS_BY_ID[food.id] = food
