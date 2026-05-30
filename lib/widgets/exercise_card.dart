// lib/widgets/exercise_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

class CategoryBadge extends StatelessWidget {
  final ExerciseCategory category;
  const CategoryBadge({super.key, required this.category});

  Color _bgColor() {
    switch (category) {
      case ExerciseCategory.equilibre:
        return AppColors.equilibreBg;
      case ExerciseCategory.renforcement:
        return AppColors.renforcementBg;
      case ExerciseCategory.mobilite:
        return AppColors.mobiliteBg;
      case ExerciseCategory.etirement:
        return AppColors.etirementBg;
      case ExerciseCategory.cardio:
        return AppColors.cardioBg;
      case ExerciseCategory.autre:
        return AppColors.autreBg;
    }
  }

  Color _textColor() {
    switch (category) {
      case ExerciseCategory.equilibre:
        return AppColors.equilibreColor;
      case ExerciseCategory.renforcement:
        return AppColors.renforcementColor;
      case ExerciseCategory.mobilite:
        return AppColors.mobiliteColor;
      case ExerciseCategory.etirement:
        return AppColors.etirementColor;
      case ExerciseCategory.cardio:
        return AppColors.cardioColor;
      case ExerciseCategory.autre:
        return AppColors.autreColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          color: _textColor(),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ExerciseListTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ExerciseListTile({
    super.key,
    required this.exercise,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ExerciseImage(imagePath: exercise.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CategoryBadge(category: exercise.category),
                        const SizedBox(width: 8),
                        Icon(
                          exercise.type == ExerciseType.duration
                              ? Icons.timer_outlined
                              : Icons.repeat,
                          size: 14,
                          color: AppColors.textGrey,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          exercise.type == ExerciseType.duration
                              ? '${exercise.value}s'
                              : '${exercise.value} reps',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseImage extends StatelessWidget {
  final String? imagePath;
  const _ExerciseImage({this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imagePath != null && File(imagePath!).existsSync()
            ? Image.file(File(imagePath!), fit: BoxFit.cover)
            : Container(
                color: AppColors.border,
                child: const Icon(Icons.fitness_center,
                    color: AppColors.textGrey, size: 28),
              ),
      ),
    );
  }
}

class TealButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  const TealButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}
