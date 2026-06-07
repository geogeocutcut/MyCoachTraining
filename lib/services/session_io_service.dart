// lib/services/session_io_service.dart
//
// Export: Session + its exercises → .mct JSON file → share via share_plus
// Import: .mct file → parse → create missing exercises → create session
//
// pubspec.yaml additions needed:
//   share_plus: ^10.0.0
//   receive_sharing_intent: ^1.8.0   (handles files opened from outside)
//   path_provider: ^2.1.0            (temp directory for export file)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../services/data_store.dart';

class SessionIOService {
  static const _version = 1;

  // ── Export ─────────────────────────────────────────────────────────────────

  /// Serialises [session] + all its exercises into a .mct file and opens
  /// the system share sheet (WhatsApp, email, Drive, …).
  static Future<void> exportSession(
      BuildContext context, Session session, DataStore store) async {
    // Collect exercises referenced by this session
    final exercises = session.exercises
        .map((se) => store.getExercise(se.exerciseId))
        .whereType<Exercise>()
        .toList();

    final payload = {
      'version': _version,
      'session': _sessionToExportJson(session),
      'exercises': exercises.map(_exerciseToExportJson).toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);

    // Write to a temp file
    final dir = await getTemporaryDirectory();
    // Sanitise filename
    final safeName = session.name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final file = File('${dir.path}/$safeName.mct');
    await file.writeAsString(json, encoding: utf8);

    // Share
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Séance MyCoachTraining : ${session.name}',
      text: 'Voici ma séance "${session.name}" depuis MyCoachTraining 💪',
    );
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  /// Reads a .mct file at [filePath], creates missing exercises, creates
  /// the session, and shows a result dialog.
  /// Returns true if import succeeded.
  static Future<bool> importSession(
      BuildContext context, String filePath, DataStore store) async {
    try {
      final content = await File(filePath).readAsString(encoding: utf8);
      final payload = jsonDecode(content) as Map<String, dynamic>;

      // Version check
      final version = payload['version'] as int? ?? 1;
      if (version > _version) {
        _showError(context,
            'Ce fichier a été créé avec une version plus récente de MyCoachTraining.');
        return false;
      }

      final exercisesJson =
          (payload['exercises'] as List<dynamic>?) ?? [];
      final sessionJson =
          payload['session'] as Map<String, dynamic>;

      // ── Step 1: create missing exercises ──────────────────────────────────
      // Map from export-id → store-id (may differ if exercise already exists)
      final idMap = <String, String>{};
      int createdCount = 0;
      int reusedCount = 0;

      for (final exJson in exercisesJson) {
        final exportId = exJson['id'] as String;
        final name = exJson['name'] as String;

        // Try to find by name (case-insensitive) to avoid duplicates
        final existing = store.exercises.where(
          (e) => e.name.toLowerCase() == name.toLowerCase(),
        );

        if (existing.isNotEmpty) {
          idMap[exportId] = existing.first.id;
          reusedCount++;
        } else {
          // Create new exercise
          final newId = store.newId();
          final exercise = Exercise(
            id: newId,
            name: name,
            instructions: exJson['instructions'] as String?,
            imagePath: null, // images stay local, can't transfer via file
            category: ExerciseCategoryExtension.fromName(
                exJson['category'] as String? ?? 'autre'),
            type: (exJson['type'] as String?) == 'repetitions'
                ? ExerciseType.repetitions
                : ExerciseType.duration,
            value: exJson['value'] as int? ?? 30,
          );
          await store.addExercise(exercise);
          idMap[exportId] = newId;
          createdCount++;
        }
      }

      // ── Step 2: remap exercise IDs and create session ─────────────────────
      final newSessionId = store.newId();
      final importedExercises =
          (sessionJson['exercises'] as List<dynamic>? ?? [])
              .map((e) {
                final exportExId = e['exerciseId'] as String;
                final mappedId = idMap[exportExId];
                if (mappedId == null) return null;
                return SessionExercise(
                  exerciseId: mappedId,
                  customValue: e['customValue'] as int? ?? 30,
                  restAfter: e['restAfter'] as int? ?? 15,
                );
              })
              .whereType<SessionExercise>()
              .toList();

      // Avoid duplicate session name
      final baseName = sessionJson['name'] as String? ?? 'Séance importée';
      final existingNames =
          store.sessions.map((s) => s.name.toLowerCase()).toSet();
      String finalName = baseName;
      int suffix = 2;
      while (existingNames.contains(finalName.toLowerCase())) {
        finalName = '$baseName ($suffix)';
        suffix++;
      }

      final session = Session(
        id: newSessionId,
        name: finalName,
        description: sessionJson['description'] as String?,
        rounds: sessionJson['rounds'] as int? ?? 1,
        restBetweenRounds: sessionJson['restBetweenRounds'] as int? ?? 60,
        exercises: importedExercises,
      );
      await store.addSession(session);

      // ── Step 3: show success dialog ───────────────────────────────────────
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Séance importée ✓'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Séance : $finalName'),
                const SizedBox(height: 8),
                Text(
                  '• $createdCount exercice${createdCount != 1 ? 's' : ''} créé${createdCount != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '• $reusedCount exercice${reusedCount != 1 ? 's' : ''} réutilisé${reusedCount != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return true;
    } catch (e) {
      _showError(context, 'Fichier invalide ou corrompu.\n($e)');
      return false;
    }
  }

  /// Import from raw JSON string (used when receiving via app_links/WhatsApp).
  static Future<bool> importFromString(
      BuildContext context, String content, DataStore store) async {
    debugPrint('MCT >>> importFromString called, length: ${content.length}');
    try {
      final payload = jsonDecode(content) as Map<String, dynamic>;
      debugPrint('MCT >>> JSON decoded OK');

      final exercisesJson = (payload['exercises'] as List<dynamic>?) ?? [];
      final sessionJson = payload['session'] as Map<String, dynamic>;

      final idMap = <String, String>{};
      int createdCount = 0;
      int reusedCount = 0;

      for (final exJson in exercisesJson) {
        final exportId = exJson['id'] as String;
        final name = exJson['name'] as String;
        final existing = store.exercises
            .where((e) => e.name.toLowerCase() == name.toLowerCase());
        if (existing.isNotEmpty) {
          idMap[exportId] = existing.first.id;
          reusedCount++;
        } else {
          final newId = store.newId();
          await store.addExercise(Exercise(
            id: newId,
            name: name,
            instructions: exJson['instructions'] as String?,
            category: ExerciseCategoryExtension.fromName(
                exJson['category'] as String? ?? 'autre'),
            type: (exJson['type'] as String?) == 'repetitions'
                ? ExerciseType.repetitions
                : ExerciseType.duration,
            value: exJson['value'] as int? ?? 30,
          ));
          idMap[exportId] = newId;
          createdCount++;
        }
      }

      final importedExercises =
          (sessionJson['exercises'] as List<dynamic>? ?? [])
              .map((e) {
                final mapped = idMap[e['exerciseId'] as String];
                if (mapped == null) return null;
                return SessionExercise(
                  exerciseId: mapped,
                  customValue: e['customValue'] as int? ?? 30,
                  restAfter: e['restAfter'] as int? ?? 15,
                );
              })
              .whereType<SessionExercise>()
              .toList();

      final baseName = sessionJson['name'] as String? ?? 'Séance importée';
      final existingNames =
          store.sessions.map((s) => s.name.toLowerCase()).toSet();
      String finalName = baseName;
      int suffix = 2;
      while (existingNames.contains(finalName.toLowerCase())) {
        finalName = '$baseName ($suffix)';
        suffix++;
      }

      debugPrint('MCT >>> adding session: $finalName');
      await store.addSession(Session(
        id: store.newId(),
        name: finalName,
        description: sessionJson['description'] as String?,
        rounds: sessionJson['rounds'] as int? ?? 1,
        restBetweenRounds: sessionJson['restBetweenRounds'] as int? ?? 60,
        exercises: importedExercises,
      ));

      debugPrint('MCT >>> context.mounted: ${context.mounted}');
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Séance importée ✓'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(finalName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '• $createdCount exercice${createdCount != 1 ? 's' : ''} '
                  'créé${createdCount != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '• $reusedCount exercice${reusedCount != 1 ? 's' : ''} '
                  'réutilisé${reusedCount != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return true;
    } catch (e, stack) {
      debugPrint('MCT >>> importFromString ERROR: $e\n$stack');
      _showError(context, 'Fichier invalide ou corrompu.\n($e)');
      return false;
    }
  }

  static Session decodeSession(String jsonString) {
    return Session.fromJson(json.decode(jsonString));
  }
  // ── JSON helpers ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _sessionToExportJson(Session s) => {
        'name': s.name,
        'description': s.description,
        'rounds': s.rounds,
        'restBetweenRounds': s.restBetweenRounds,
        'exercises': s.exercises
            .map((e) => {
                  'exerciseId': e.exerciseId,
                  'customValue': e.customValue,
                  'restAfter': e.restAfter,
                })
            .toList(),
      };

  static Map<String, dynamic> _exerciseToExportJson(Exercise e) => {
        'id': e.id,
        'name': e.name,
        'instructions': e.instructions,
        'category': e.category.name,
        'type': e.type.name,
        'value': e.value,
      };

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erreur d\'import'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> shareSession(Session session) async {
    try {
      // 1. On sérialise la séance en chaîne de caractères (JSON)
      // (Utilise ici ta méthode existante de conversion, ex: session.toJsonString())
      final String sessionData = jsonEncode(session.toJson());

      // 2. On crée un fichier temporaire sur l'appareil avec l'extension .mct
      final tempDir = await getTemporaryDirectory();
      // On nettoie le nom pour éviter les caractères spéciaux dans le nom de fichier
      final safeName = session.name.replaceAll(RegExp(r'[^\w\s]+'), '');
      final file = File('${tempDir.path}/$safeName.mct');

      // 3. On écrit les données dans le fichier
      await file.writeAsString(sessionData);

      // 4. On lance l'outil de partage système
      final xFile = XFile(file.path, mimeType: 'application/octet-stream');
      await Share.shareXFiles(
        [xFile],
        text: 'Voici ma séance "${session.name}" créée sur MyCoachTraining ! 🏸',
        subject: 'Partage de séance MyCoachTraining',
      );
    } catch (e) {
      print("Erreur lors du partage de la séance: $e");
    }
  }
}