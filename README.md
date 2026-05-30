# MyCoatchTraining — Application Flutter

Application mobile de suivi des exercices de kinésithérapie, inspirée du Tabata Timer.

## Fonctionnalités

- **Exercices** : créer, modifier, supprimer des exercices avec photo, instructions, catégorie
- **Deux types d'exercices** : durée (timer visuel) ou répétitions (bouton "Terminé")
- **Séances** : assembler des exercices en séances avec plusieurs tours
- **Lecteur de séance** : enchaînement automatique avec :
  - Écran de préparation (5 secondes avant le début)
  - Timer circulaire animé (teal pour les exercices, orange pour le repos)
  - Repos configurables entre exercices et entre tours
  - Pause / Reprendre
  - Skip
  - Écran de fin de séance
- **Stockage local** : données persistées avec `shared_preferences`, aucun serveur requis
- **Données de démo** : 6 exercices et 1 séance chargés au premier lancement

## Structure des fichiers

```
lib/
├── main.dart                        # Point d'entrée
├── models/
│   ├── exercise.dart                # Modèle Exercise + ExerciseCategory
│   └── session.dart                 # Modèle Session + SessionExercise
├── services/
│   └── data_store.dart              # Persistance locale (ChangeNotifier)
├── theme/
│   └── app_theme.dart               # Couleurs et thème Material 3
├── widgets/
│   └── exercise_card.dart           # Widgets réutilisables
└── screens/
    ├── home_screen.dart             # Accueil + navigation bottom bar
    ├── exercises_screen.dart        # Liste des exercices avec recherche
    ├── new_exercise_screen.dart     # Formulaire création exercice
    ├── edit_exercise_screen.dart    # Formulaire modification exercice
    ├── sessions_screen.dart         # Liste des séances
    ├── new_session_screen.dart      # Formulaire création séance
    ├── edit_session_screen.dart     # Formulaire modification séance
    └── session_player_screen.dart   # Lecteur de séance (timer + reps)
```

## Installation

### Prérequis
- Flutter SDK ≥ 3.0.0 : https://docs.flutter.dev/get-started/install
- Android Studio ou VS Code avec l'extension Flutter

### Étapes

```bash
# 1. Cloner / copier le projet
cd MyCoachTraining

# 2. Créer le dossier assets
mkdir -p assets/images

# 3. Installer les dépendances
flutter pub get

# 4. Lancer sur un émulateur ou appareil connecté
flutter run
```

### iOS (supplémentaire)

Ajouter dans `ios/Runner/Info.plist` :
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Accès à la galerie pour ajouter des photos aux exercices</string>
<key>NSCameraUsageDescription</key>
<string>Accès à la caméra pour photographier les exercices</string>
```

## Dépendances utilisées

| Package | Usage |
|---|---|
| `provider` | Gestion d'état global (DataStore) |
| `shared_preferences` | Persistance locale JSON |
| `uuid` | Génération d'identifiants uniques |
| `image_picker` | Sélection de photos depuis la galerie |
| `path_provider` | Accès aux chemins système |
| `path` | Manipulation des chemins |

## Personnalisation

### Ajouter une catégorie d'exercice
Dans `lib/models/exercise.dart`, ajouter une valeur à `ExerciseCategory` et compléter les extensions `label`, `emoji`, et les couleurs dans `app_theme.dart`.

### Modifier les couleurs
Éditer `lib/theme/app_theme.dart` — la couleur principale est `AppColors.teal` (#3ECFB2).

### Temps de préparation
Dans `session_player_screen.dart`, modifier `_prepareSeconds` (défaut : 5 secondes).
