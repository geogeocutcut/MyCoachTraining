// lib/widgets/app_logo.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    // On calcule proportionnellement les arrondis et la taille de l'icône
    final borderRadius = (14.0 / 48.0) * size;
    final iconSize = (26.0 / 48.0) * size;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.monitor_heart,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}