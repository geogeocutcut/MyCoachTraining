// lib/screens/edit_session_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../services/data_store.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_card.dart';
import 'new_session_screen.dart';

class EditSessionScreen extends StatefulWidget {
  final Session session;
  const EditSessionScreen({super.key, required this.session});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late int _rounds;
  late int _restRound;
  late List<_SessionExRow> _rows;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _nameController = TextEditingController(text: s.name);
    _descController = TextEditingController(text: s.description ?? '');
    _rounds = s.rounds;
    _restRound = s.restBetweenRounds;
    final store = context.read<DataStore>();
    _rows = s.exercises.map((se) {
      final ex = store.getExercise(se.exerciseId);
      return _SessionExRow(
        exerciseId: se.exerciseId,
        name: ex?.name ?? 'Exercice supprimé',
        imagePath: ex?.imagePath,
        type: ex?.type ?? ExerciseType.duration,
        value: se.customValue,
        restAfter: se.restAfter,
      );
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

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
            restAfter: 15,
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
    final updated = Session(
      id: widget.session.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      rounds: _rounds,
      restBetweenRounds: _restRound,
      exercises: _rows
          .map((r) => SessionExercise(
                exerciseId: r.exerciseId,
                customValue: r.value,
                restAfter: r.restAfter,
              ))
          .toList(),
    );
    await context.read<DataStore>().updateSession(updated);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la séance'),
        content: Text('Supprimer "${widget.session.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<DataStore>().deleteSession(widget.session.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Modifier la séance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Nom de la séance'),
            TextField(controller: _nameController),
            const SizedBox(height: 16),
            _label('Description (optionnel)'),
            TextField(controller: _descController, maxLines: 3),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Repos tours',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '$_restRound',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.border),
                                ),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                final parsed = int.tryParse(v);
                                if (parsed != null && parsed >= 0) {
                                  _restRound = parsed;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('sec',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
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
                    onRestChanged: (v) =>
                        setState(() => _rows[i].restAfter = v),
                  ),
              ],
            ),
            TextButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add, color: AppColors.teal),
              label: const Text('Ajouter un exercice',
                  style: TextStyle(color: AppColors.teal)),
            ),
            const SizedBox(height: 24),
            TealButton(
              label: 'Modifier',
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Supprimer la séance',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
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

// ── Local re-exports of shared classes from new_session_screen ────────────────

class _SessionExRow {
  final String exerciseId;
  final String name;
  final String? imagePath;
  final ExerciseType type;
  int value;
  int restAfter;

  _SessionExRow({
    required this.exerciseId,
    required this.name,
    this.imagePath,
    required this.type,
    required this.value,
    this.restAfter = 15,
  });
}

class _SessionExerciseTile extends StatelessWidget {
  final _SessionExRow row;
  final VoidCallback onRemove;
  final ValueChanged<int> onValueChanged;
  final ValueChanged<int> onRestChanged;

  const _SessionExerciseTile({
    super.key,
    required this.row,
    required this.onRemove,
    required this.onValueChanged,
    required this.onRestChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.drag_handle, color: AppColors.textGrey),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: AppColors.textGrey, size: 20),
                ),
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
                        borderSide:
                            const BorderSide(color: AppColors.border),
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
                  icon: const Icon(Icons.close,
                      color: AppColors.textGrey, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 58),
                const Icon(Icons.pause_circle_outline,
                    size: 14, color: AppColors.textGrey),
                const SizedBox(width: 6),
                const Text('Repos après :',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 52,
                  child: TextFormField(
                    initialValue: '${row.restAfter}',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed >= 0)
                        onRestChanged(parsed);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                const Text('sec',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 40),
              ),
              Text('$value',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              IconButton(
                onPressed: () => onChanged(value + step),
                icon: const Icon(Icons.add, size: 16),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 40),
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
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textGrey),
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