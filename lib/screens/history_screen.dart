// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/data_store.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // The selected month displayed in the calendar (defaults to current month).
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() =>
      setState(() => _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1);
    // Don't allow navigating past current month
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _displayMonth = next);
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _displayMonth.year == now.year &&
        _displayMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DataStore>();
    final completions = store.completions;

    // Set of "yyyy-M-d" strings for days that have completions in display month
    final completedInMonth = <String>{};
    for (final c in completions) {
      if (c.completedAt.year == _displayMonth.year &&
          c.completedAt.month == _displayMonth.month) {
        completedInMonth
            .add('${c.completedAt.year}-${c.completedAt.month}-${c.completedAt.day}');
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Calendar card ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.chevron_left,
                            color: AppColors.textDark),
                      ),
                      Text(
                        _monthLabel(_displayMonth),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark),
                      ),
                      IconButton(
                        onPressed: _isCurrentMonth() ? null : _nextMonth,
                        icon: Icon(Icons.chevron_right,
                            color: _isCurrentMonth()
                                ? AppColors.border
                                : AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CalendarGrid(
                    month: _displayMonth,
                    completedDays: completedInMonth,
                  ),
                ],
              ),
            ),

            // ── Weekly history ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Historique hebdomadaire',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
            ),

            if (completions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Aucune séance complétée pour le moment.',
                      style: TextStyle(color: AppColors.textGrey)),
                ),
              )
            else
              ..._buildWeeklyGroups(completions),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Groups completions by ISO week and builds section widgets.
  List<Widget> _buildWeeklyGroups(List<SessionCompletion> completions) {
    // Group by Monday of the week
    final Map<String, List<SessionCompletion>> groups = {};
    for (final c in completions) {
      final monday = _mondayOf(c.completedAt);
      final key = monday.toIso8601String();
      groups.putIfAbsent(key, () => []).add(c);
    }

    // Sort keys descending
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];
    for (final key in sortedKeys) {
      final monday = DateTime.parse(key);
      final sunday = monday.add(const Duration(days: 6));
      final items = groups[key]!;

      // Total duration and total sessions
      final totalDuration =
          items.fold<int>(0, (sum, c) => sum + c.durationSeconds);

      widgets.add(
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Week header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_dayLabel(monday)} – ${_dayLabel(sunday)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark),
                        ),
                        Text(
                          '${items.length} activité${items.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 14, color: AppColors.teal),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(totalDuration),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, indent: 16, endIndent: 16),
              // Completion tiles
              ...items.map((c) => _CompletionTile(
                    completion: c,
                    onDelete: () =>
                        context.read<DataStore>().deleteCompletion(c.id),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  String _monthLabel(DateTime d) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _dayLabel(DateTime d) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}min${s > 0 ? ' ${s}s' : ''}';
  }

  DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));
}

// ── Calendar grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Set<String> completedDays;

  const _CalendarGrid({required this.month, required this.completedDays});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const dayLabels = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

    // Number of days in the month
    final daysInMonth =
        DateUtils.getDaysInMonth(month.year, month.month);
    // Weekday of the 1st (1=Monday … 7=Sunday in DateTime, but we show Sun first)
    final firstWeekday =
        DateTime(month.year, month.month, 1).weekday % 7; // 0=Sun

    return Column(
      children: [
        // Day-of-week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dayLabels
              .map((l) => SizedBox(
                    width: 36,
                    child: Text(l,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Weeks
        ...List.generate(6, (weekIdx) {
          final cells = List.generate(7, (dayIdx) {
            final cellNum = weekIdx * 7 + dayIdx;
            final dayNum = cellNum - firstWeekday + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox(width: 36, height: 36);
            }
            final date = DateTime(month.year, month.month, dayNum);
            final key =
                '${date.year}-${date.month}-${date.day}';
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isCompleted = completedDays.contains(key);
            final isFuture = date.isAfter(now);

            return _CalendarCell(
              day: dayNum,
              isToday: isToday,
              isCompleted: isCompleted,
              isFuture: isFuture,
            );
          });

          // Skip empty weeks
          final hasAnyDay = cells.any((c) => c is! SizedBox ||
              (c.width == 36 && c.height == 36));
          if (weekIdx > 0 &&
              cells.every((c) => c is SizedBox)) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: cells,
            ),
          );
        }),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isCompleted;
  final bool isFuture;

  const _CalendarCell({
    required this.day,
    required this.isToday,
    required this.isCompleted,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color textColor =
        isFuture ? AppColors.border : AppColors.textGrey;
    Widget? content;

    if (isToday) {
      bg = AppColors.textDark;
      textColor = Colors.white;
    } else if (isCompleted) {
      bg = AppColors.teal;
    }

    if (isCompleted && !isToday) {
      content = const Icon(Icons.check, color: Colors.white, size: 15);
    } else {
      content = Text(
        '$day',
        style: TextStyle(
            fontSize: 13,
            fontWeight:
                isToday ? FontWeight.bold : FontWeight.normal,
            color: textColor),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}

// ── Completion tile ──────────────────────────────────────────────────────────

class _CompletionTile extends StatelessWidget {
  final SessionCompletion completion;
  final VoidCallback onDelete;

  const _CompletionTile(
      {required this.completion, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final time =
        TimeOfDay.fromDateTime(completion.completedAt).format(context);
    final dateStr = _shortDate(completion.completedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_fire_department,
                color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completion.sessionName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$time · $dateStr',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      completion.formattedDuration,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.more_vert,
                color: AppColors.textGrey, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer cette entrée',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (action == 'delete') onDelete();
  }

  String _shortDate(DateTime d) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
