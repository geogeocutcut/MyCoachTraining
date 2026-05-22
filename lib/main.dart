// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_store.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'KinéTracker',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
