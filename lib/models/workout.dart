/// Macro-categoria di sport, derivata dal campo `type` di intervals.icu.
enum Sport { run, ride, strength, swim, walk, other }

extension SportInfo on Sport {
  String get label => switch (this) {
    Sport.run => 'Corsa',
    Sport.ride => 'Bici',
    Sport.strength => 'Palestra',
    Sport.swim => 'Nuoto',
    Sport.walk => 'Camminata',
    Sport.other => 'Altro',
  };

  /// Valore `type` da inviare a intervals.icu quando si crea un allenamento.
  String get icuType => switch (this) {
    Sport.run => 'Run',
    Sport.ride => 'Ride',
    Sport.strength => 'WeightTraining',
    Sport.swim => 'Swim',
    Sport.walk => 'Walk',
    Sport.other => 'Workout',
  };

  static Sport fromIcuType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('run')) return Sport.run;
    if (t.contains('ride') || t.contains('cycl') || t.contains('bike')) {
      return Sport.ride;
    }
    if (t.contains('weight') ||
        t.contains('strength') ||
        t.contains('crossfit')) {
      return Sport.strength;
    }
    if (t.contains('swim')) return Sport.swim;
    if (t.contains('walk') || t.contains('hike')) return Sport.walk;
    return Sport.other;
  }
}

/// Un allenamento, pianificato (evento WORKOUT) o svolto (attività).
class Workout {
  /// `e<id>` per eventi pianificati, `a<id>` per attività svolte.
  final String id;
  final bool completed;
  final int? eventId;
  final String? activityId;

  /// Per un'attività: l'evento pianificato a cui è abbinata.
  final int? pairedEventId;
  final DateTime date;
  final String icuType;
  final String name;
  final String description;
  final int movingTimeSec;
  final double? distanceM;
  final int? trainingLoad;
  final int? joules;

  /// Intensità in % (es. 75 = IF 0.75).
  final double? intensity;
  final int? ftp;

  /// Calorie misurate dal dispositivo (solo attività svolte).
  final int? calories;

  const Workout({
    required this.id,
    required this.completed,
    this.eventId,
    this.activityId,
    this.pairedEventId,
    required this.date,
    required this.icuType,
    required this.name,
    this.description = '',
    this.movingTimeSec = 0,
    this.distanceM,
    this.trainingLoad,
    this.joules,
    this.intensity,
    this.ftp,
    this.calories,
  });

  Sport get sport => SportInfo.fromIcuType(icuType);
  double get hours => movingTimeSec / 3600;
  DateTime get day => DateTime(date.year, date.month, date.day);

  static DateTime _parseLocal(String s) =>
      DateTime.parse(s.replaceAll('Z', ''));

  static int? _int(dynamic v) => (v as num?)?.toInt();

  factory Workout.fromEvent(Map<String, dynamic> j) {
    final duration = _int(j['moving_time']) ?? _int(j['time_target']) ?? 0;
    return Workout(
      id: 'e${j['id']}',
      completed: false,
      eventId: _int(j['id']),
      date: _parseLocal(j['start_date_local'] as String),
      icuType: j['type'] as String? ?? 'Workout',
      name: j['name'] as String? ?? 'Allenamento',
      description: j['description'] as String? ?? '',
      movingTimeSec: duration,
      distanceM:
          (j['distance'] as num?)?.toDouble() ??
          (j['distance_target'] as num?)?.toDouble(),
      trainingLoad: _int(j['icu_training_load']) ?? _int(j['load_target']),
      joules: _int(j['joules']),
      intensity: (j['icu_intensity'] as num?)?.toDouble(),
      ftp: _int(j['icu_ftp']),
    );
  }

  factory Workout.fromActivity(Map<String, dynamic> j) => Workout(
    id: 'a${j['id']}',
    completed: true,
    activityId: j['id']?.toString(),
    pairedEventId: _int(j['paired_event_id']),
    date: _parseLocal(j['start_date_local'] as String),
    icuType: j['type'] as String? ?? 'Workout',
    name: j['name'] as String? ?? 'Attività',
    description: j['description'] as String? ?? '',
    movingTimeSec: _int(j['moving_time']) ?? _int(j['elapsed_time']) ?? 0,
    distanceM: (j['distance'] as num?)?.toDouble(),
    trainingLoad: _int(j['icu_training_load']),
    joules: _int(j['icu_joules']),
    intensity: (j['icu_intensity'] as num?)?.toDouble(),
    ftp: _int(j['icu_ftp']),
    calories: _int(j['calories']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'completed': completed,
    'eventId': eventId,
    'activityId': activityId,
    'pairedEventId': pairedEventId,
    'date': date.toIso8601String(),
    'icuType': icuType,
    'name': name,
    'description': description,
    'movingTimeSec': movingTimeSec,
    'distanceM': distanceM,
    'trainingLoad': trainingLoad,
    'joules': joules,
    'intensity': intensity,
    'ftp': ftp,
    'calories': calories,
  };

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
    id: j['id'] as String,
    completed: j['completed'] as bool,
    eventId: _int(j['eventId']),
    activityId: j['activityId'] as String?,
    pairedEventId: _int(j['pairedEventId']),
    date: DateTime.parse(j['date'] as String),
    icuType: j['icuType'] as String,
    name: j['name'] as String,
    description: j['description'] as String? ?? '',
    movingTimeSec: _int(j['movingTimeSec']) ?? 0,
    distanceM: (j['distanceM'] as num?)?.toDouble(),
    trainingLoad: _int(j['trainingLoad']),
    joules: _int(j['joules']),
    intensity: (j['intensity'] as num?)?.toDouble(),
    ftp: _int(j['ftp']),
    calories: _int(j['calories']),
  );
}

/// Bozza per creare/modificare un allenamento pianificato su intervals.icu.
class WorkoutDraft {
  final int? eventId;
  final DateTime date;
  final Sport sport;
  final String name;
  final String description;
  final int durationMin;
  final double? distanceKm;
  final int? targetLoad;

  const WorkoutDraft({
    this.eventId,
    required this.date,
    required this.sport,
    required this.name,
    this.description = '',
    required this.durationMin,
    this.distanceKm,
    this.targetLoad,
  });

  Map<String, dynamic> toEventJson() {
    final d = date;
    String two(int v) => v.toString().padLeft(2, '0');
    return {
      'category': 'WORKOUT',
      'start_date_local': '${d.year}-${two(d.month)}-${two(d.day)}T00:00:00',
      'type': sport.icuType,
      'name': name,
      'description': description,
      'moving_time': durationMin * 60,
      if (distanceKm != null) 'distance': distanceKm! * 1000,
      if (targetLoad != null) 'load_target': targetLoad,
    };
  }
}
