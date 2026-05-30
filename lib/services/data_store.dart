// lib/services/data_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/session.dart';

class DataStore extends ChangeNotifier {
  static const _exercisesKey = 'exercises';
  static const _sessionsKey = 'sessions';
  static const _completionsKey = 'completions';

  final _uuid = const Uuid();
  List<Exercise> _exercises = [];
  List<Session> _sessions = [];
  List<SessionCompletion> _completions = [];

  List<Exercise> get exercises => List.unmodifiable(_exercises);
  List<Session> get sessions => List.unmodifiable(_sessions);
  List<SessionCompletion> get completions => List.unmodifiable(_completions);

  /// Distinct dates (UTC day) on which at least one session was completed.
  List<DateTime> get completedDates {
    final seen = <String>{};
    final result = <DateTime>[];
    for (final c in _completions) {
      final key =
          '${c.completedAt.year}-${c.completedAt.month}-${c.completedAt.day}';
      if (seen.add(key)) {
        result.add(DateTime(
            c.completedAt.year, c.completedAt.month, c.completedAt.day));
      }
    }
    return result;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final exJson = prefs.getString(_exercisesKey);
    if (exJson != null) {
      final list = jsonDecode(exJson) as List;
      _exercises = list.map((e) => Exercise.fromJson(e)).toList();
    } else {
      _exercises = _defaultExercises();
    }

    final seJson = prefs.getString(_sessionsKey);
    if (seJson != null) {
      final list = jsonDecode(seJson) as List;
      _sessions = list.map((s) => Session.fromJson(s)).toList();
    } else {
      _sessions = _defaultSessions();
    }

    final coJson = prefs.getString(_completionsKey);
    if (coJson != null) {
      final list = jsonDecode(coJson) as List;
      _completions =
          list.map((c) => SessionCompletion.fromJson(c)).toList();
      // Most-recent first
      _completions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    }

    notifyListeners();
  }

  Future<void> _saveExercises() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _exercisesKey, jsonEncode(_exercises.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _sessionsKey, jsonEncode(_sessions.map((s) => s.toJson()).toList()));
  }

  Future<void> _saveCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completionsKey,
        jsonEncode(_completions.map((c) => c.toJson()).toList()));
  }

  // ── Exercises ──────────────────────────────────────────────────────────────

  String newId() => _uuid.v4();

  Future<void> addExercise(Exercise exercise) async {
    _exercises.add(exercise);
    await _saveExercises();
    notifyListeners();
  }

  Future<void> updateExercise(Exercise updated) async {
    final idx = _exercises.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      _exercises[idx] = updated;
      await _saveExercises();
      notifyListeners();
    }
  }

  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    for (final s in _sessions) {
      s.exercises.removeWhere((e) => e.exerciseId == id);
    }
    await _saveExercises();
    await _saveSessions();
    notifyListeners();
  }

  Exercise? getExercise(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Sessions ───────────────────────────────────────────────────────────────

  Future<void> addSession(Session session) async {
    _sessions.add(session);
    await _saveSessions();
    notifyListeners();
  }

  Future<void> updateSession(Session updated) async {
    final idx = _sessions.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) {
      _sessions[idx] = updated;
      await _saveSessions();
      notifyListeners();
    }
  }

  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _saveSessions();
    notifyListeners();
  }

  // ── Completions ────────────────────────────────────────────────────────────

  Future<void> recordCompletion(SessionCompletion completion) async {
    _completions.insert(0, completion); // most-recent first
    await _saveCompletions();
    notifyListeners();
  }

  Future<void> deleteCompletion(String id) async {
    _completions.removeWhere((c) => c.id == id);
    await _saveCompletions();
    notifyListeners();
  }

  // ── Defaults ───────────────────────────────────────────────────────────────

  List<Exercise> _defaultExercises() {
    final ids = List.generate(6, (_) => _uuid.v4());
    return [
      Exercise(
        id: ids[0],
        name: 'Équilibre unipodal',
        instructions:
            'Tenez-vous sur un pied, l\'autre genou levé à 90°. Gardez le regard fixe devant vous. Changez de côté après la durée indiquée.',
        category: ExerciseCategory.equilibre,
        type: ExerciseType.duration,
        value: 30,
      ),
      Exercise(
        id: ids[1],
        name: 'Pompes',
        instructions:
            'Placez les mains à largeur d\'épaules. Descendez la poitrine vers le sol en gardant le corps droit. Poussez pour revenir.',
        category: ExerciseCategory.renforcement,
        type: ExerciseType.repetitions,
        value: 10,
      ),
      Exercise(
        id: ids[2],
        name: 'Rotation des épaules',
        instructions:
            'Assis ou debout, effectuez de grandes rotations avec les épaules, vers l\'avant puis vers l\'arrière.',
        category: ExerciseCategory.mobilite,
        type: ExerciseType.duration,
        value: 20,
      ),
      Exercise(
        id: ids[3],
        name: 'Étirement quadriceps',
        instructions:
            'Debout, pliez un genou et attrapez votre cheville. Tirez doucement le talon vers la fesse en gardant le dos droit. Maintenez la position.',
        category: ExerciseCategory.etirement,
        type: ExerciseType.duration,
        value: 30,
      ),
      Exercise(
        id: ids[4],
        name: 'Squats',
        instructions:
            'Pieds écartés à largeur d\'épaules. Descendez comme pour vous asseoir, dos droit, genoux alignés avec les pieds.',
        category: ExerciseCategory.renforcement,
        type: ExerciseType.repetitions,
        value: 15,
      ),
      Exercise(
        id: ids[5],
        name: 'Planche abdominale',
        instructions:
            'Appuyez-vous sur les avant-bras et les pointes de pieds. Gardez le corps bien aligné, contractez les abdominaux.',
        category: ExerciseCategory.renforcement,
        type: ExerciseType.duration,
        value: 45,
      ),
    ];
  }

  List<Session> _defaultSessions() {
    final exIds = _exercises.map((e) => e.id).toList();
    if (exIds.length < 4) return [];
    return [
      Session(
        id: _uuid.v4(),
        name: 'Rééducation genou - Semaine 1',
        description:
            'Programme de rééducation prescrit par votre kinésithérapeute. À faire 3 fois par semaine.',
        rounds: 2,
        restBetweenRounds: 60,
        exercises: [
          SessionExercise(exerciseId: exIds[3], customValue: 30, restAfter: 15),
          SessionExercise(exerciseId: exIds[4], customValue: 15, restAfter: 15),
          SessionExercise(exerciseId: exIds[5], customValue: 45, restAfter: 15),
          SessionExercise(exerciseId: exIds[0], customValue: 30, restAfter: 15),
        ],
      ),
    ];
  }
}
