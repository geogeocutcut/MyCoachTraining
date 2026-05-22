// lib/screens/new_exercise_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../services/data_store.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_card.dart';

class NewExerciseScreen extends StatefulWidget {
  const NewExerciseScreen({super.key});

  @override
  State<NewExerciseScreen> createState() => _NewExerciseScreenState();
}

class _NewExerciseScreenState extends State<NewExerciseScreen> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.etirement;
  ExerciseType _type = ExerciseType.duration;
  int _value = 30;
  String? _imagePath;
  bool _saving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) setState(() => _imagePath = xFile.path);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est obligatoire')),
      );
      return;
    }
    setState(() => _saving = true);
    final store = context.read<DataStore>();
    final exercise = Exercise(
      id: store.newId(),
      name: _nameController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      imagePath: _imagePath,
      category: _category,
      type: _type,
      value: _value,
    );
    await store.addExercise(exercise);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Sheet header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nouvel exercice',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 20),
                    _label('Nom *'),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          hintText: 'Ex : Étirement quadriceps'),
                    ),
                    const SizedBox(height: 16),
                    _label('Instructions'),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          hintText: 'Décrivez comment réaliser l\'exercice...'),
                    ),
                    const SizedBox(height: 16),
                    _label('Catégorie'),
                    _CategoryDropdown(
                      value: _category,
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 16),
                    _label('Type'),
                    _TypeToggle(
                      value: _type,
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    const SizedBox(height: 16),
                    _label(_type == ExerciseType.duration
                        ? 'Durée (secondes)'
                        : 'Répétitions'),
                    _NumberField(
                      value: _value,
                      onChanged: (v) => setState(() => _value = v),
                    ),
                    const SizedBox(height: 32),
                    TealButton(
                      label: 'Créer l\'exercice',
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.border, style: BorderStyle.solid, width: 1.5),
        ),
        child: _imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    Image.file(File(_imagePath!), fit: BoxFit.cover))
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload, color: AppColors.textGrey, size: 32),
                  SizedBox(height: 8),
                  Text('Ajouter une photo',
                      style: TextStyle(color: AppColors.textGrey)),
                ],
              ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
      );
}

class _CategoryDropdown extends StatelessWidget {
  final ExerciseCategory value;
  final ValueChanged<ExerciseCategory?> onChanged;

  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExerciseCategory>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ExerciseCategory.values
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text('${c.emoji} ${c.label}'),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final ExerciseType value;
  final ValueChanged<ExerciseType> onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleBtn(
            label: 'Durée',
            icon: Icons.timer_outlined,
            selected: value == ExerciseType.duration,
            onTap: () => onChanged(ExerciseType.duration),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleBtn(
            label: 'Répétitions',
            icon: Icons.repeat,
            selected: value == ExerciseType.repetitions,
            onTap: () => onChanged(ExerciseType.repetitions),
          ),
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: selected ? Colors.white : AppColors.textGrey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _NumberField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => onChanged((value - 1).clamp(1, 9999)),
          icon: const Icon(Icons.remove_circle_outline, color: AppColors.teal),
          iconSize: 32,
        ),
        Container(
          width: 100,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ),
        IconButton(
          onPressed: () => onChanged((value + 1).clamp(1, 9999)),
          icon: const Icon(Icons.add_circle_outline, color: AppColors.teal),
          iconSize: 32,
        ),
      ],
    );
  }
}
