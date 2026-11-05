# Traincal

App Flutter (Linux, Windows, Android) che:

- sincronizza gli allenamenti di corsa, bici e palestra con **intervals.icu** (lettura e scrittura);
- stima il **fabbisogno calorico e i macronutrienti** di ogni giorno in base alle sedute pianificate o svolte e al piano scelto (mantenimento, dimagrimento, massa);
- genera un **menu settimanale orientato al meal prep**, con le porzioni scalate sul fabbisogno di ogni giorno, le sessioni di cucina e la **lista della spesa**;
- crea nuove ricette con **Claude** (opzionale);
- sincronizza profilo, piani, ricette e menu tra i dispositivi tramite **Supabase**, con un account personale.

## Avvio su Linux

```bash
# dipendenze di sistema (una volta)
sudo apt install clang ninja-build libgtk-3-dev libsecret-1-dev pkg-config mesa-utils

# SDK Flutter (già installato in ~/development/flutter)
export PATH="$HOME/development/flutter/bin:$PATH"

flutter pub get
flutter run -d linux          # sviluppo
flutter build linux           # build release in build/linux/x64/release/bundle/
flutter test                  # test
```

**Installazione sul PC.** Su desktop `flutter install` non fa nulla: per Flutter l'app si avvia dalla cartella di build. Per installarla nel menu delle applicazioni, con l'icona e il comando `traincal`, senza sudo:

```bash
tool/install_linux.sh            # installa o aggiorna (ricompila la release)
tool/install_linux.sh --remove   # disinstalla (i dati restano)
```

L'app finisce in `~/.local/opt/traincal`. Dopo ogni modifica al codice, rilancia lo script per aggiornare la versione installata.

**Aggiornamento su Android.** Per aggiornare l'app sul telefono senza disinstallarla (i dati restano), con il telefono collegato in debug USB:

```bash
tool/install_android.sh               # aumenta la build, compila e installa con adb install -r
tool/install_android.sh --no-install  # solo APK, da copiare sul telefono e aprire ("Aggiorna")
```

Non usare `flutter install`, che disinstalla prima la versione esistente. L'APK è firmato con `~/.android/debug.keystore`: conservane una copia, perché senza la stessa chiave Android non accetta l'aggiornamento.

Le chiavi API sono salvate nel portachiavi di sistema (libsecret: serve gnome-keyring o KWallet attivo). Se non è disponibile, l'app ripiega sul database locale e lo segnala.

Il database locale è in `~/.local/share/it.traincal.traincal/traincal.db`.

## Configurazione (icona ⚙ in alto)

| Servizio | Cosa serve |
|---|---|
| intervals.icu | Richiede il login. API key da *Settings › Developer Settings*; ID atleta `0` = il proprietario della chiave. Di default resta solo sul dispositivo: con *Salva la chiave nel mio account* la ricevono anche gli altri dispositivi quando accedi. |
| Claude | API key Anthropic (uso a consumo). Modello di default `claude-opus-5-5`, modificabile. |
| Account (Supabase) | Il progetto è configurato in [lib/config/supabase_config.dart](lib/config/supabase_config.dart) (schema in [supabase/schema.sql](supabase/schema.sql)): basta registrarsi o accedere dall'app. |

C!4udioM0cc1 password db subabase

### Account e dati

API key di intervals.icu, allenamenti e menu sono legati al login. Senza accesso l'app non ha la chiave, quindi niente allenamenti né menu; ricette e profilo restano disponibili. All'uscita dall'account le modifiche in sospeso vengono inviate a Supabase, poi chiave, allenamenti in cache e menu vengono rimossi dal dispositivo (i menu tornano al prossimo accesso). Se accede un altro utente, la chiave del precedente viene scartata.

## Come funziona la stima

1. **Metabolismo basale** con la formula di Mifflin-St Jeor, moltiplicato per il fattore di attività fuori dallo sport (1.2-1.55).
2. **Allenamenti**: calorie nette (al netto di quelle che si spenderebbero comunque nello stesso tempo), dalla fonte migliore disponibile:
   misurate dal dispositivo → lavoro meccanico in kJ (bici con potenza) → distanza (corsa ≈ 1 kcal/kg/km) → MET in base allo sport e all'intensità (da IF o TSS).
   Un evento pianificato già svolto viene sostituito dall'attività abbinata.
3. **Obiettivo del piano**: il deficit o surplus settimanale (7700 kcal/kg) è distribuito sui giorni in base al carico. In dimagrimento si taglia di più nei giorni di riposo e di meno in quelli intensi (max 10% del dispendio nei giorni duri, 20% nei moderati, 25% negli altri, mai sotto il basale). Se i limiti non permettono il ritmo richiesto, la schermata Settimana lo segnala.
4. **Macro**: proteine fisse in g/kg secondo il piano, grassi al 25% (0.8-1.2 g/kg), il resto carboidrati. Il confronto con le linee guida (3-8 g/kg secondo il carico) evidenzia i giorni in cui i carboidrati sono troppo bassi. Per le sedute oltre 75' viene suggerita l'integrazione in g/h.

Con *Pubblica su intervals.icu* i target giornalieri vengono scritti come **note** sul calendario (idempotente, una nota per giorno).

## Meal prep

- La settimana è divisa in 1-3 blocchi, ognuno con una sessione di cucina il giorno prima. Pranzi e cene si organizzano in due modi:
  - **Piatti** (ricette alternate): ogni sessione prepara 2-4 ricette con fonti proteiche diverse, distribuite sui pasti del blocco. La stessa ricetta non compare mai in due pasti di fila e le ripetizioni sono bilanciate.
  - **Componenti** da combinare: ogni sessione prepara a parte 1-2 basi (riso, farro, quinoa, patate...), 2-3 proteine e 2-3 verdure di stagione (catalogo in [lib/data/components.dart](lib/data/components.dart)). Ogni pasto è una combinazione diversa: la proteina cambia a ogni pasto, la base si alterna tra i giorni e gli abbinamenti già usati vengono evitati.

  In entrambi i casi le preparazioni che si conservano meno (es. pesce, 2 giorni) finiscono nei primi giorni del blocco, e si evitano le proteine del blocco precedente.
- **Stagionalità**: ogni alimento fresco ha i suoi mesi di stagione (Italia). Le ricette con frutta e verdura fuori stagione nei giorni del blocco sono fortemente penalizzate, quelle con prodotti di stagione leggermente favorite. A cavallo di due mesi conta la maggioranza dei giorni.
- **Pasti liberi ed eliminati**: nelle Opzioni del menu una griglia giorni × pasti permette di cambiare lo stato di ogni pasto (tocco: preparato → libero → eliminato). Un pasto **libero** (es. cena fuori) non ha ricetta, preparazione né spesa, ma mantiene la sua quota di calorie: il menu indica le kcal a disposizione. Un pasto **eliminato** (es. lo spuntino nei giorni di riposo) sparisce e le sue calorie e i suoi macro passano agli altri pasti del giorno. Le stesse azioni sono nel menu ⋮ di ogni pasto; liberi ed eliminati si ripristinano con una ricetta coerente (quella dello stesso pasto in un giorno vicino). Le modifiche valgono subito anche per il menu esistente, per la settimana selezionata, e si sincronizzano con l'account.
- **Giorni e pasti bloccati**: con il lucchetto un giorno del menu resta identico quando si rigenera; dal menu ⋮ si può bloccare anche un singolo pasto, che mantiene la sua ricetta (e le porzioni, se impostate a mano) mentre gli altri si rigenerano. Così si fissano alcuni giorni o pasti e si rigenera il resto. Preparazione e spesa tengono conto di tutto.
- Colazioni e spuntini ruotano tra poche ricette. Con la puntina (schermata Ricette) una colazione o uno spuntino diventa **fisso**: entra sempre nella rotazione, e se le fisse sono più della varietà richiesta si usano solo quelle.
- **Porzioni**: dal menu (icona "Porzioni" accanto a ogni pasto) puoi impostare a mano le porzioni di un pasto. Il pasto resta bloccato e gli altri della giornata si ricalcolano per rispettare il target; "Automatico" lo sblocca. Nell'editor una ricetta può avere una **porzione fissa**, che non viene mai adattata alle kcal del giorno (utile per le colazioni abituali). Le quantità della preparazione e la spesa si aggiornano di conseguenza.
- Le porzioni (a passi di ¼) sono scalate sulle kcal del giorno; un piccolo set di integrazioni (yogurt greco, banana, pane, noci) chiude i gap di proteine e kcal.
- La lista della spesa somma gli ingredienti per reparto, in pezzi o confezioni.

Nella schermata Ricette si filtra per tipo, *di stagione* (rispetto alla settimana selezionata) e per dieta (vegetariano, vegano, senza glutine). Le ricette si possono escludere dal meal prep, duplicare, modificare o generare con Claude, che usa il database degli alimenti e aggiunge quelli nuovi con i relativi valori.

## Database di ricette e alimenti

L'app include **1001 ricette** pensate per il meal prep (620 pranzi/cene, 190 colazioni, 191 spuntini) e circa 210 alimenti, in [assets/db/](assets/db/) come JSON riusabile anche fuori dall'app:

- `foods.json`: valori per 100 g, reparto, pezzo e confezione tipici, `seasonMonths` (vuoto = tutto l'anno);
- `recipes.json`: ingredienti in grammi per porzione, procedimento a passi, proteina principale, giorni in frigo, congelabilità, tempo, tag (`vegetariano`, `vegano`, `senza glutine`, `senza lattosio`, `forno`, `zuppa`...).

Il database è generato da [tool/recipe_db/](tool/recipe_db/): i template di piatti (`templates_*.py`) combinano proteine, cereali, verdure e frutta, scartano gli abbinamenti di stagioni incompatibili, bilanciano varietà e copertura delle quattro stagioni e validano i macro di ogni porzione. Gli ID sono stabili tra una generazione e l'altra.

```bash
python tool/recipe_db/build.py                          # rigenera assets/db/
python tool/recipe_db/build.py --check                  # solo validazione e statistiche
python tool/recipe_db/build.py --pack templates_primi --all   # prova un pacchetto di template
```

## Struttura

```
lib/
  models/       profilo, piani, alimenti, ricette, allenamenti, piano pasti
  services/     energy_calculator, meal_planner, shopping_list (logica pura, testata)
                intervals_client, claude_client, supabase_sync
  data/         store SQLite a documenti, caricamento del database, segreti
  state/        AppState (ChangeNotifier)
  ui/           schermate e widget (layout adattivo desktop/mobile)
assets/db/      database di alimenti e ricette (generato)
tool/recipe_db/ generatore Python del database
supabase/       schema SQL con RLS e last-write-wins
test/           test unitari e smoke test dei widget
```

## Note e limiti

- I valori nutrizionali del database sono indicativi (tabelle CREA e USDA, per 100 g a crudo).
- La sync con Supabase è *last-write-wins* per record, su timestamp del dispositivo.
- Le attività importate da Strava non sono leggibili dalle API di intervals.icu e vengono ignorate.
- Windows: `flutter build windows` da una macchina Windows con Visual Studio. Android: `flutter build apk` con Android SDK.

