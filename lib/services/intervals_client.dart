import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food.dart';
import '../models/workout.dart';

class IntervalsException implements Exception {
  final int? statusCode;
  final String message;

  IntervalsException(this.message, [this.statusCode]);

  @override
  String toString() => statusCode == null
      ? 'intervals.icu: $message'
      : 'intervals.icu ($statusCode): $message';
}

class WellnessDay {
  final DateTime date;
  final double? weight;
  final int? restingHR;

  const WellnessDay(this.date, this.weight, this.restingHR);
}

/// Client REST per intervals.icu (https://intervals.icu/api-docs.html).
/// Autenticazione Basic con utente "API_KEY" e la chiave personale.
class IntervalsClient {
  static const _base = 'https://intervals.icu/api/v1';

  final String apiKey;

  /// "0" indica l'atleta proprietario della chiave.
  final String athleteId;
  final http.Client _http;

  IntervalsClient({
    required this.apiKey,
    this.athleteId = '0',
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Map<String, String> get _headers => {
    'Authorization': 'Basic ${base64Encode(utf8.encode('API_KEY:$apiKey'))}',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_base/athlete/$athleteId$path')
          .replace(queryParameters: query);

  Future<dynamic> _send(Future<http.Response> req) async {
    final http.Response res;
    try {
      res = await req.timeout(const Duration(seconds: 30));
    } catch (e) {
      throw IntervalsException('connessione non riuscita ($e)');
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw IntervalsException(
        'API key non valida o senza permessi',
        res.statusCode,
      );
    }
    if (res.statusCode >= 400) {
      throw IntervalsException(
        res.body.isEmpty ? 'errore' : res.body,
        res.statusCode,
      );
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<Map<String, dynamic>> athlete() async =>
      await _send(_http.get(_uri(''), headers: _headers))
          as Map<String, dynamic>;

  Future<List<Workout>> plannedWorkouts(
    DateTime oldest,
    DateTime newest,
  ) async {
    final list = await _send(
      _http.get(
        _uri('/events', {
          'oldest': _date(oldest),
          'newest': _date(newest),
          'category': 'WORKOUT',
        }),
        headers: _headers,
      ),
    ) as List;
    return list.cast<Map<String, dynamic>>().map(Workout.fromEvent).toList();
  }

  Future<List<Workout>> activities(DateTime oldest, DateTime newest) async {
    final list = await _send(
      _http.get(
        _uri('/activities', {
          'oldest': _date(oldest),
          'newest': '${_date(newest)}T23:59:59',
        }),
        headers: _headers,
      ),
    ) as List;
    return list
        .cast<Map<String, dynamic>>()
        // Le attività importate da Strava non sono leggibili via API.
        .where((a) => a['start_date_local'] != null)
        .map(Workout.fromActivity)
        .toList();
  }

  Future<List<WellnessDay>> wellness(DateTime oldest, DateTime newest) async {
    final list = await _send(
      _http.get(
        _uri('/wellness', {
          'oldest': _date(oldest),
          'newest': _date(newest),
          'fields': 'id,weight,restingHR',
        }),
        headers: _headers,
      ),
    ) as List;
    return list.cast<Map<String, dynamic>>().map((w) {
      return WellnessDay(
        DateTime.parse(w['id'] as String),
        (w['weight'] as num?)?.toDouble(),
        (w['restingHR'] as num?)?.toInt(),
      );
    }).toList();
  }

  Future<Workout> createWorkout(WorkoutDraft d) async {
    final j = await _send(
      _http.post(
        _uri('/events'),
        headers: _headers,
        body: jsonEncode(d.toEventJson()),
      ),
    );
    return Workout.fromEvent(j as Map<String, dynamic>);
  }

  Future<Workout> updateWorkout(WorkoutDraft d) async {
    final j = await _send(
      _http.put(
        _uri('/events/${d.eventId}'),
        headers: _headers,
        body: jsonEncode(d.toEventJson()),
      ),
    );
    return Workout.fromEvent(j as Map<String, dynamic>);
  }

  Future<void> deleteWorkout(int eventId) async {
    await _send(_http.delete(_uri('/events/$eventId'), headers: _headers));
  }

  /// Pubblica il target nutrizionale del giorno come nota sul calendario.
  /// L'uid fisso per data rende l'operazione idempotente (upsert).
  Future<void> upsertNutritionNote(
    DateTime day,
    Macros target, {
    String extra = '',
  }) async {
    final d = _date(day);
    final body = {
      'category': 'NOTE',
      'uid': 'traincal-nutrition-$d',
      'start_date_local': '${d}T00:00:00',
      'end_date_local': '${d}T00:00:00',
      'name': '🍽 ${target.kcal.round()} kcal · C ${target.carbs.round()} g',
      'description':
          'Target Traincal\nKcal: ${target.kcal.round()}\nProteine: ${target.protein.round()} g\n'
          'Carboidrati: ${target.carbs.round()} g\nGrassi: ${target.fat.round()} g'
          '${extra.isEmpty ? '' : '\n\n$extra'}',
    };
    await _send(
      _http.post(
        _uri('/events', {'upsertOnUid': 'true'}),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  void close() => _http.close();
}
