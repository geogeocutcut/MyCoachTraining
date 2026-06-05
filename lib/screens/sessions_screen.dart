// lib/screens/sessions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../services/data_store.dart';
import '../services/session_io_service.dart';
import '../theme/app_theme.dart';
import 'new_session_screen.dart';
import 'edit_session_screen.dart';
import 'session_player_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DataStore>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Séances',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['mct'],
                        );
                        if (result != null && result.files.single.path != null) {
                          final store = context.read<DataStore>();
                          await SessionIOService.importSession(
                              context, result.files.single.path!, store);
                        }
                      },
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Importer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.teal,
                        side: const BorderSide(color: AppColors.teal),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NewSessionScreen()),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Créer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: store.sessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.format_list_bulleted,
                            size: 64, color: AppColors.border),
                        SizedBox(height: 16),
                        Text('Aucune séance',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Créez votre première séance',
                            style: TextStyle(color: AppColors.textGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: store.sessions.length,
                    itemBuilder: (_, i) {
                      final s = store.sessions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textDark),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              EditSessionScreen(session: s)),
                                    ),
                                    icon: const Icon(Icons.edit_outlined,
                                        color: AppColors.textGrey, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              if (s.description != null &&
                                  s.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    s.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textGrey),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      size: 15, color: AppColors.textGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${s.exercises.length} exercice${s.exercises.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textGrey),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.repeat,
                                      size: 15, color: AppColors.textGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${s.rounds} tour${s.rounds > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textGrey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SessionPlayerScreen(
                                          session: s, store: store),
                                    ),
                                  ),
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('Commencer'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
