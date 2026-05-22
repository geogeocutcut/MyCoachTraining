// lib/screens/new_session_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../services/data_store.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_card.dart';

class NewSessionScreen extends StatefulWidget {
  const NewSessionScreen({super.key});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _rounds = 1;
  int _restExercise = 15;
  int _restRound = 60;
  final List<_SessionExRow> _rows = [];
  bool _saving = false;

  Future<void> _addExercise() async {
    final store = context.read<DataStore>();
    final ex = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExercisePicker(store: store),
    );
    if (ex != null) {
      setState(() => _rows.add(_SessionExRow(
            exerciseId: ex.id,
            name: ex.name,
            imagePath: ex.imagePath,
            type: ex.type,
            value: ex.value,
          )));
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le nom est obligatoire')));
      return;
    }
    setState(() => _saving = true);
    final store = context.read<DataStore>();
    final session = Session(
      id: store.newId(),
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      rounds: _rounds,
      restBetweenExercises: _restExercise,
      restBetweenRounds: _restRound,
      exercises: _rows
          .map((r) =>
              SessionExercise(exerciseId: r.exerciseId, customValue: r.value))
          .toList(),
    );
    await store.addSession(session);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nouvelle séance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Nom de la séance'),
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(hintText: 'Ex: Rééducation genou'),
            ),
            const SizedBox(height: 16),
            _label('Description (optionnel)'),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Notes pour cette séance...'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _SmallNumberField(
                  label: 'Tours',
                  value: _rounds,
                  onChanged: (v) => setState(() => _rounds = v),
                  min: 1,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _SmallNumberField(
                  label: 'Repos exercices (s)',
                  value: _restExercise,
                  onChanged: (v) => setState(() => _restExercise = v),
                  step: 5,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _SmallNumberField(
                  label: 'Repos tours (s)',
                  value: _restRound,
                  onChanged: (v) => setState(() => _restRound = v),
                  step: 10,
                )),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Exercices (${_rows.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _rows.removeAt(oldIndex);
                  _rows.insert(newIndex, item);
                });
              },
              children: [
                for (int i = 0; i < _rows.length; i++)
                  _SessionExerciseTile(
                    key: ValueKey(_rows[i].exerciseId + i.toString()),
                    row: _rows[i],
                    onRemove: () => setState(() => _rows.removeAt(i)),
                    onValueChanged: (v) =>
                        setState(() => _rows[i].value = v),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add, color: AppColors.teal),
              label: const Text('Ajouter un exercice',
                  style: TextStyle(color: AppColors.teal)),
            ),
            const SizedBox(height: 24),
            TealButton(
              label: 'Créer la séance',
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontSize: 14)),
      );
}

class _SessionExRow {
  final String exerciseId;
  final String name;
  final String? imagePath;
  final ExerciseType type;
  int value;

  _SessionExRow({
    required this.exerciseId,
    required this.name,
    this.imagePath,
    required this.type,
    required this.value,
  });
}

class _SessionExerciseTile extends StatelessWidget {
  final _SessionExRow row;
  final VoidCallback onRemove;
  final ValueChanged<int> onValueChanged;

  const _SessionExerciseTile({
    super.key,
    required this.row,
    required this.onRemove,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.drag_handle, color: AppColors.textGrey),
            const SizedBox(width: 8),
            if (row.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(row.imagePath!,
                    width: 40, height: 40, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder()),
              )
            else
              _placeholder(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(row.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Icon(
              row.type == ExerciseType.duration
                  ? Icons.timer_outlined
                  : Icons.repeat,
              size: 15,
              color: AppColors.textGrey,
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 52,
              child: TextFormField(
                initialValue: '${row.value}',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  isDense: true,
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed > 0) onValueChanged(parsed);
                },
              ),
            ),
            const SizedBox(width: 4),
            Text(
              row.type == ExerciseType.duration ? 'sec' : 'reps',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: AppColors.textGrey, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.fitness_center,
            color: AppColors.textGrey, size: 20),
      );
}

class _SmallNumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int step;

  const _SmallNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (value - step >= min) onChanged(value - step);
                },
                icon: const Icon(Icons.remove, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
              ),
              Text('$value',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              IconButton(
                onPressed: () => onChanged(value + step),
                icon: const Icon(Icons.add, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExercisePicker extends StatefulWidget {
  final DataStore store;
  const _ExercisePicker({required this.store});

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final exercises = widget.store.exercises
        .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choisir un exercice',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
                hintText: 'Rechercher...',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (_, i) {
                final ex = exercises[i];
                return ExerciseListTile(
                  exercise: ex,
                  onTap: () => Navigator.pop(context, ex),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
