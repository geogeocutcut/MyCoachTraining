// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/data_store.dart';
import '../theme/app_theme.dart';
import 'sessions_screen.dart';
import 'exercises_screen.dart';
import 'session_player_screen.dart';
import 'new_session_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    _HomePage(),
    ExercisesScreen(),
    SessionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Exercices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_bulleted_outlined),
              activeIcon: Icon(Icons.format_list_bulleted),
              label: 'Séances',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DataStore>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.monitor_heart,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'KinéTracker',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Vos exercices de rééducation',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weekly calendar fed by real completedDates
            _WeeklyCalendar(
              completedDates: store.completedDates,
              completions: store.completions,
            ),
            const SizedBox(height: 28),

            // Sessions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes séances',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final home =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    home?.setState(() => home._currentIndex = 2);
                  },
                  child: const Text(
                    'Tout voir >',
                    style: TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (store.sessions.isEmpty)
              const _EmptyState(
                  message: 'Aucune séance. Créez-en une ci-dessous.')
            else
              ...store.sessions.take(3).map((s) {
                final exerciseCount = s.exercises.length;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$exerciseCount exercice${exerciseCount > 1 ? 's' : ''} · ${s.rounds} tour${s.rounds > 1 ? 's' : ''}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionPlayerScreen(
                                  session: s, store: store),
                            ),
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Action button – full width
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                label: 'Nouvelle séance',
                color: AppColors.orange,
                bgColor: AppColors.orangeLight,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NewSessionScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly calendar ───────────────────────────────────────────────────────────

class _WeeklyCalendar extends StatelessWidget {
  final List<DateTime> completedDates;
  final List<SessionCompletion> completions;

  const _WeeklyCalendar({
    required this.completedDates,
    required this.completions,
  });

  DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monday = _mondayOf(today);
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    final Set<String> completedKeys = completedDates
        .map((d) => '${d.year}-${d.month}-${d.day}')
        .toSet();

    const dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cette semaine',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HistoryScreen()),
                ),
                child: const Text(
                  'Historique >',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = days[i];
              final key =
                  '${day.year}-${day.month}-${day.day}';
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final isCompleted = completedKeys.contains(key);

              return _DayCell(
                label: dayLabels[i],
                dayNumber: day.day,
                isToday: isToday,
                isCompleted: isCompleted,
              );
            }),
          ),
          // Weekly stats
          Builder(builder: (_) {
            final weekStart = monday;
            final weekEnd = monday.add(const Duration(days: 7));
            final weekCompletions = completions.where((c) =>
                !c.completedAt.isBefore(weekStart) &&
                c.completedAt.isBefore(weekEnd)).toList();
            final count = weekCompletions.length;
            final totalSec = weekCompletions.fold<int>(
                0, (sum, c) => sum + c.durationSeconds);
            final minutes = totalSec ~/ 60;
            final seconds = totalSec % 60;
            final durationLabel = totalSec == 0
                ? '0min'
                : minutes > 0
                    ? '${minutes}min${seconds > 0 ? ' ${seconds}s' : ''}'
                    : '${seconds}s';

            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  _WeekStat(
                    icon: Icons.check_circle_outline,
                    value: '$count',
                    label: 'séance${count > 1 ? 's' : ''}',
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 16),
                  _WeekStat(
                    icon: Icons.timer_outlined,
                    value: durationLabel,
                    label: 'au total',
                    color: AppColors.orange,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _WeekStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final int dayNumber;
  final bool isToday;
  final bool isCompleted;

  const _DayCell({
    required this.label,
    required this.dayNumber,
    required this.isToday,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = AppColors.textGrey;

    if (isToday) {
      bgColor = AppColors.textDark;
      textColor = Colors.white;
    } else if (isCompleted) {
      bgColor = AppColors.teal;
    }

    Widget child;
    if (isCompleted && !isToday) {
      child = const Icon(Icons.check, color: Colors.white, size: 16);
    } else {
      child = Text(
        '$dayNumber',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      );
    }

    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: child,
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.add, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(message,
          style:
              const TextStyle(color: AppColors.textGrey, fontSize: 14)),
    );
  }
}