// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';
// Importez votre écran principal ici, par exemple :
// import 'home_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Attend 2 secondes sur le splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // Remplace le splash screen par l'écran principal (évite le retour arrière)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()), 
        // Remplacez le Center ci-dessus par votre vrai widget de départ (ex: HomeScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background, // Fond harmonisé avec votre app
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Utilisation de votre icône container agrandie pour le splash (taille 100)
            AppLogo(size: 100.0),
            SizedBox(height: 24),
            Text(
              'Mon Coatch Personnel',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                color: AppColors.teal,
                backgroundColor: AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}