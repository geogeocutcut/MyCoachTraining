// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_store.dart';
import 'services/workout_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart'; // Import du nouveau splash screen

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

class MyCoachTrainingApp extends StatelessWidget {
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
}
