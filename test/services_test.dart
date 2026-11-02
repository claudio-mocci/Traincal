import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:traincal/data/local_store.dart';
import 'package:traincal/data/seed_foods.dart';
import 'package:traincal/models/food.dart';
import 'package:traincal/models/recipe.dart';
import 'package:traincal/models/workout.dart';
import 'package:traincal/services/claude_client.dart';
import 'package:traincal/services/intervals_client.dart';

void main() {
  group('IntervalsClient', () {
    test('legge eventi e attività con autenticazione Basic', () async {
      late http.Request captured;
      final mock = MockClient((req) async {
        captured = req;
        if (req.url.path.endsWith('/events')) {
          return http.Response(
            jsonEncode([
              {
                'id': 101,
                'category': 'WORKOUT',
                'start_date_local': '2026-11-03T00:00:00',
                'type': 'Ride',
                'name': 'Sweet spot',
                'moving_time': 5400,
                'icu_training_load': 95,
                'joules': 1500000,
                'icu_ftp': 260,
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            {
              'id': 'i555',
              'start_date_local': '2026-11-02T07:30:00',
              'type': 'Run',
              'name': 'Corsa facile',
              'moving_time': 3000,
              'distance': 9000.0,
              'calories': 620,
              'paired_event_id': 99,
            },
            {'id': '123', 'source': 'STRAVA'},
          ]),
          200,
        );
      });
      final c = IntervalsClient(apiKey: 'secret', httpClient: mock);

      final events = await c.plannedWorkouts(
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 8),
      );
      expect(
        captured.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('API_KEY:secret'))}',
      );
      expect(captured.url.queryParameters['category'], 'WORKOUT');
      expect(captured.url.path, '/api/v1/athlete/0/events');
      final e = events.single;
      expect(e.id, 'e101');
      expect(e.sport, Sport.ride);
      expect(e.trainingLoad, 95);
      expect(e.day, DateTime(2026, 11, 3));

      final acts = await c.activities(
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 8),
      );
      expect(acts, hasLength(1), reason: 'le attività Strava vanno scartate');
      expect(acts.single.completed, isTrue);
      expect(acts.single.calories, 620);
      expect(acts.single.pairedEventId, 99);
    });

    test('crea un allenamento con il payload atteso', () async {
      Map<String, dynamic>? body;
      final mock = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({...body!, 'id': 7}), 200);
      });
      final c = IntervalsClient(
        apiKey: 'k',
        athleteId: 'i42',
        httpClient: mock,
      );
      final w = await c.createWorkout(
        WorkoutDraft(
          date: DateTime(2026, 11, 5),
          sport: Sport.strength,
          name: 'Gambe',
          durationMin: 50,
        ),
      );
      expect(body!['category'], 'WORKOUT');
      expect(body!['type'], 'WeightTraining');
      expect(body!['start_date_local'], '2026-11-05T00:00:00');
      expect(body!['moving_time'], 3000);
      expect(w.eventId, 7);
    });

    test('errore 401 leggibile', () async {
      final c = IntervalsClient(
        apiKey: 'bad',
        httpClient: MockClient((_) async => http.Response('', 401)),
      );
      expect(() => c.athlete(), throwsA(isA<IntervalsException>()));
    });
  });

  group('LocalStore', () {
    test('put/get/delete e record dirty per la sync', () {
      final s = LocalStore.inMemory();
      s.put(Collections.recipes, 'r1', {'id': 'r1', 'name': 'A'});
      s.put(Collections.workoutCache, 'w1', {'id': 'w1'});
      expect(s.get(Collections.recipes, 'r1')!['name'], 'A');
      final dirty = s.dirtyRecords();
      expect(dirty.map((r) => r.id), [
        'r1',
      ], reason: 'la cache allenamenti non si sincronizza');

      s.markClean('recipes', 'r1', dirty.single.updatedAt);
      expect(s.dirtyRecords(), isEmpty);

      s.delete(Collections.recipes, 'r1');
      expect(s.get(Collections.recipes, 'r1'), isNull);
      expect(s.dirtyRecords().single.deleted, isTrue);
    });

    test('applyRemote: vince il timestamp più recente', () {
      final s = LocalStore.inMemory();
      s.put(Collections.plans, 'p', {'v': 'locale'});
      final localTs = s.dirtyRecords().single.updatedAt;

      final older = StoredRecord(
        'plans',
        'p',
        {'v': 'vecchio'},
        localTs - 1,
        false,
      );
      expect(s.applyRemote(older), isFalse);
      expect(s.get('plans', 'p')!['v'], 'locale');

      final newer = StoredRecord(
        'plans',
        'p',
        {'v': 'remoto'},
        localTs + 1,
        false,
      );
      expect(s.applyRemote(newer), isTrue);
      expect(s.get('plans', 'p')!['v'], 'remoto');
      expect(s.dirtyRecords(), isEmpty);

      final deleted = StoredRecord(
        'plans',
        'p',
        {'v': 'remoto'},
        localTs + 2,
        true,
      );
      s.applyRemote(deleted);
      expect(s.get('plans', 'p'), isNull);
    });
  });

  test('ClaudeClient.parseRecipes riconcilia gli alimenti', () {
    final foods = {for (final f in seedFoods) f.id: f};
    final g = ClaudeClient.parseRecipes(
      {
        'recipes': [
          {
            'name': 'Bowl di pollo e ceci',
            'mainProtein': 'Pollo',
            'fridgeDays': 4,
            'freezable': false,
            'prepMinutes': 30,
            'instructions': '...',
            'ingredients': [
              // per id
              {
                'foodId': 'f_pollo',
                'name': 'Pollo',
                'grams': 130,
                'category': 'meatFish',
                'kcal': 110,
                'protein': 23,
                'carbs': 0,
                'fat': 1.5,
              },
              // per nome (id vuoto)
              {
                'foodId': '',
                'name': 'riso basmati',
                'grams': 70,
                'category': 'grains',
                'kcal': 355,
                'protein': 7.5,
                'carbs': 79,
                'fat': 0.6,
              },
              // nuovo alimento
              {
                'foodId': '',
                'name': 'Tahina',
                'grams': 15,
                'category': 'pantry',
                'kcal': 595,
                'protein': 17,
                'carbs': 10,
                'fat': 54,
              },
            ],
          },
        ],
      },
      MealType.main,
      foods,
    );

    final r = g.recipes.single;
    expect(r.source, RecipeSource.ai);
    expect(r.mainProtein, 'pollo');
    expect(r.ingredients[0].foodId, 'f_pollo');
    expect(r.ingredients[1].foodId, 'f_riso');
    expect(g.newFoods.single.name, 'Tahina');
    expect(r.ingredients[2].foodId, g.newFoods.single.id);
    final all = {...foods, for (final f in g.newFoods) f.id: f};
    expect(
      r.macrosPerServing(all).kcal,
      closeTo(1.3 * 110 + 0.7 * 355 + 0.15 * 595, 0.01),
    );
    expect(g.newFoods.single.category, FoodCategory.pantry);
  });
}
