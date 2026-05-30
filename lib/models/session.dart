// lib/models/session.dart

class SessionExercise {
  final String exerciseId;
  int customValue;   // duration (s) or reps
  int restAfter;     // rest after THIS exercise (s), overrides session default

  SessionExercise({
    required this.exerciseId,
    required this.customValue,
    this.restAfter = 15,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'customValue': customValue,
        'restAfter': restAfter,
      };

  factory SessionExercise.fromJson(Map<String, dynamic> json) =>
      SessionExercise(
        exerciseId: json['exerciseId'],
        customValue: json['customValue'] ?? 30,
        restAfter: json['restAfter'] ?? 15,
      );
}

class Session {
  final String id;
  String name;
  String? description;
  int rounds;
  int restBetweenRounds;
  List<SessionExercise> exercises;

  Session({
    required this.id,
    required this.name,
    this.description,
    this.rounds = 1,
    this.restBetweenRounds = 60,
    List<SessionExercise>? exercises,
  }) : exercises = exercises ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rounds': rounds,
        'restBetweenRounds': restBetweenRounds,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        rounds: json['rounds'] ?? 1,
        restBetweenRounds: json['restBetweenRounds'] ?? 60,
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => SessionExercise.fromJson(e))
                .toList() ??
            [],
      );
}

/// Represents one completed run of a session.
class SessionCompletion {
  final String id;
  final String sessionId;
  final String sessionName;
  final DateTime completedAt;
  final int durationSeconds;
  final int roundsDone;
  final int exerciseCount;

  SessionCompletion({
    required this.id,
    required this.sessionId,
    required this.sessionName,
    required this.completedAt,
    required this.durationSeconds,
    required this.roundsDone,
    required this.exerciseCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'sessionName': sessionName,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'roundsDone': roundsDone,
        'exerciseCount': exerciseCount,
      };

  factory SessionCompletion.fromJson(Map<String, dynamic> json) =>
      SessionCompletion(
        id: json['id'],
        sessionId: json['sessionId'],
        sessionName: json['sessionName'],
        completedAt: DateTime.parse(json['completedAt']),
        durationSeconds: json['durationSeconds'] ?? 0,
        roundsDone: json['roundsDone'] ?? 1,
        exerciseCount: json['exerciseCount'] ?? 0,
      );

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}min${s > 0 ? ' ${s}s' : ''}';
  }
}