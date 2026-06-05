// lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_store.dart';
import 'services/workout_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart'; // Import du nouveau splash screen
import 'package:uni_links/uni_links.dart'; // ← Import indispensable
import 'services/session_io_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WorkoutNotificationService.init();
  final store = DataStore();
  await store.load();
  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const MyCoachTrainingApp(),
    ),
  );
}

class MyCoachTrainingApp extends StatefulWidget {
  const MyCoachTrainingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCoatchTraining',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
  @override
  State<MyCoachTrainingApp> createState() => _MyCoachTrainingAppState();
}

class _MyCoachTrainingAppState extends State<MyCoachTrainingApp> {
  @override
  void initState() {
    super.initState();
    // Activer l'écoute des fichiers ouverts depuis l'extérieur (WhatsApp, etc.)
    _initIncomingLinks();
  }

  /// Initialise la capture des liens/fichiers externes
  Future<void> _initIncomingLinks() async {
    final store = context.read<DataStore>();

    // CAS 1 : L'application était COMPLÈTEMENT FERMÉE et s'ouvre via le fichier
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleIncomingFile(initialUri, store);
      }
    } catch (e) {
      print("Erreur lors de l'interception initiale : $e");
    }

    // CAS 2 : L'application était en ARRIÈRE-PLAN et le fichier la réveille
    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleIncomingFile(uri, store);
      }
    }, onError: (Object err) {
      print("Erreur du flux de liens : $err");
    });
  }

  /// Lit et importe le fichier de session reçu
  Future<void> _handleIncomingFile(Uri uri, DataStore store) async {
    try {
      // Sur Android, le chemin du fichier peut être encapsulé dans une Uri de type file:// ou content://
      final String filePath = uri.toFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        final String jsonContent = await file.readAsString();
        
        // Utilise ta méthode existante pour décoder la chaîne de caractères brute (JSON) en objet Session
        // Par exemple si tu as une méthode comme SessionIoService.decodeSession ou Session.fromJson
        final session = SessionIOService.decodeSession(jsonContent);

        // Ajoute la séance au DataStore (ce qui mettra à jour l'UI automatiquement via Provider)
        await store.addSession(session);

        // Affiche une confirmation à l'écran
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Séance "${session.name}" importée avec succès !'),
              backgroundColor: Colors.teal,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print("Échec de l'importation de la séance externe : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCoachTraining',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
