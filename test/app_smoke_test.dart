import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:traincal/data/local_store.dart';
import 'package:traincal/main.dart';
import 'package:traincal/models/nutrition_plan.dart';
import 'package:traincal/models/recipe.dart';
import 'package:traincal/models/workout.dart';
import 'package:traincal/state/app_state.dart';
import 'package:traincal/ui/screens/settings_screen.dart';

import 'test_db.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
    Intl.defaultLocale = 'it_IT';
  });

  Future<AppState> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = LocalStore.inMemory();
    // Un allenamento in cache, per popolare la settimana.
    final monday = mondayOf(DateTime.now());
    store.put(
      Collections.workoutCache,
      'e1',
      Workout(
        id: 'e1',
        completed: false,
        eventId: 1,
        date: monday.add(const Duration(days: 2)),
        icuType: 'Ride',
        name: 'Lungo Z2',
        movingTimeSec: 3 * 3600,
        trainingLoad: 150,
      ).toJson(),
    );
    final state = AppState();
    await state.init(testStore: store, db: testDb, testUserId: 'utente-test');
    state.savePlan(state.newPlan(Goal.cut).copyWith(active: true));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const TraincalApp()),
    );
    await tester.pumpAndSettle();
    return state;
  }

  for (final size in [const Size(1280, 900), const Size(400, 850)]) {
    testWidgets('tutte le schermate si aprono (${size.width.toInt()}px)', (
      tester,
    ) async {
      final state = await pumpApp(tester, size);
      await tester.scrollUntilVisible(
        find.textContaining('Lungo Z2'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Lungo Z2'), findsWidgets);

      await tester.tap(find.text('Allenamenti').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meal prep').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Genera menu'));
      await tester.pumpAndSettle();
      expect(state.weekMealPlan, isNotNull);
      // Porzioni impostate a mano sul primo pasto del menu.
      // Su schermi stretti la prima card può finire sotto la navigazione.
      await tester.ensureVisible(find.byTooltip('Porzioni').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Porzioni').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.tap(find.text('Imposta'));
      await tester.pumpAndSettle();
      expect(
        state.weekMealPlan!.days.expand((d) => d.meals).where((m) => m.locked),
        hasLength(1),
      );
      await tester.tap(find.text('Preparazione'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spesa'));
      await tester.pumpAndSettle();
      expect(find.text('Copia'), findsOneWidget);

      await tester.tap(find.text('Ricette').last);
      await tester.pumpAndSettle();
      // Filtro "Mie ricette": solo quelle create dall'utente.
      state.saveRecipe(
        const Recipe(
          id: 'r_mia',
          name: 'Insalata della casa',
          type: MealType.main,
          ingredients: [Ingredient('f_pollo', 150), Ingredient('f_riso', 80)],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mie ricette'));
      await tester.pumpAndSettle();
      expect(find.text('1 ricette'), findsOneWidget);
      expect(find.text('Insalata della casa'), findsOneWidget);
      await tester.tap(find.text('Mie ricette'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Cerca ricetta'),
        'banana e burro',
      );
      await tester.pumpAndSettle();
      // Su schermi stretti i filtri occupano spazio: si scorre la lista.
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Banana e burro d'arachidi"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profilo').last);
      await tester.pumpAndSettle();
      expect(find.text('Piani nutrizionali'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('senza login: niente allenamenti, menu e API key', (
    tester,
  ) async {
    final state = AppState();
    // init da scollegati cancella la chiave dal portachiavi: in tempo reale,
    // perché il plugin non risponde nel tempo simulato dei widget test.
    await tester.runAsync(
      () => state.init(testStore: LocalStore.inMemory(), db: testDb),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const TraincalApp()),
    );
    await tester.pumpAndSettle();
    expect(state.loggedIn, isFalse);

    await tester.tap(find.text('Allenamenti').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('accedi per vederli'), findsOneWidget);

    await tester.tap(find.text('Meal prep').last);
    await tester.pumpAndSettle();
    expect(find.text('Genera menu'), findsNothing);
    expect(find.textContaining('accedi per'), findsOneWidget);

    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.textContaining('accedi per collegare'), findsOneWidget);
    expect(find.text('API key'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
