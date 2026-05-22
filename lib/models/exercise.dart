// lib/models/exercise.dart

enum ExerciseType { duration, repetitions }

enum ExerciseCategory {
  equilibre,
  renforcement,
  mobilite,
  etirement,
  autre,
}

extension ExerciseCategoryExtension on ExerciseCategory {
  String get label {
    switch (this) {
      case ExerciseCategory.equilibre:
        return 'Équilibre';
      case ExerciseCategory.renforcement:
        return 'Renforcement';
      case ExerciseCategory.mobilite:
        return 'Mobilité';
      case ExerciseCategory.etirement:
        return 'Étirement';
      case ExerciseCategory.autre:
        return 'Autre';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseCategory.equilibre:
        return '⚖️';
      case ExerciseCategory.renforcement:
        return '💪';
      case ExerciseCategory.mobilite:
        return '🔄';
      case ExerciseCategory.etirement:
        return '🧘';
      case ExerciseCategory.autre:
        return '⭐';
    }
  }

  String get name => toString().split('.').last;

  static ExerciseCategory fromName(String name) {
    return ExerciseCategory.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ExerciseCategory.autre,
    );
  }
}

class Exercise {
  final String id;
  String name;
  String? instructions;
  String? imagePath;
  ExerciseCategory category;
  ExerciseType type;
  int value; // seconds if duration, count if repetitions

  Exercise({
    required this.id,
    required this.name,
    this.instructions,
    this.imagePath,
    this.category = ExerciseCategory.autre,
    this.type = ExerciseType.duration,
    this.value = 30,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'instructions': instructions,
        'imagePath': imagePath,
        'category': category.name,
        'type': type.name,
        'value': value,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'],
        name: json['name'],
        instructions: json['instructions'],
        imagePath: json['imagePath'],
        category: ExerciseCategoryExtension.fromName(json['category'] ?? 'autre'),
        type: json['type'] == 'repetitions'
            ? ExerciseType.repetitions
            : ExerciseType.duration,
        value: json['value'] ?? 30,
      );

  Exercise copyWith({
    String? name,
    String? instructions,
    String? imagePath,
    ExerciseCategory? category,
    ExerciseType? type,
    int? value,
  }) =>
      Exercise(
        id: id,
        name: name ?? this.name,
        instructions: instructions ?? this.instructions,
        imagePath: imagePath ?? this.imagePath,
        category: category ?? this.category,
        type: type ?? this.type,
        value: value ?? this.value,
      );
}
