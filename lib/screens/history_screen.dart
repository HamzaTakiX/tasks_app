import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_state.dart';
import '../models/task_model.dart';
import 'task_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';
  String _statusFilter = 'All';
  DateTime? _filterDate;

  static const _statusOptions = [
    'All',
    'in_progress',
    'completed',
    'cancelled',
    'next',
  ];
  static const _statusLabels = {
    'All': 'All',
    'in_progress': 'In Progress',
    'completed': 'Done',
    'cancelled': 'Cancelled',
    'next': 'Next',
  };

  Future<void> _pickDate() async {
    if (_filterDate != null) {
      setState(() => _filterDate = null);
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _filterDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.onSurface;

    var tasks = appState.taskBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (_statusFilter != 'All') {
      tasks = tasks.where((t) {
        final s = t.status.isEmpty ? 'in_progress' : t.status;
        return s == _statusFilter;
      }).toList();
    }

    if (_filterDate != null) {
      tasks = tasks
          .where(
            (t) =>
                t.date.year == _filterDate!.year &&
                t.date.month == _filterDate!.month &&
                t.date.day == _filterDate!.day,
          )
          .toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      tasks = tasks
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.type.toLowerCase().contains(q) ||
                t.note.toLowerCase().contains(q),
          )
          .toList();
    }

    // Group by date
    final Map<String, List<TaskModel>> grouped = {};
    for (final t in tasks) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final dateKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _filterDate != null
                  ? CupertinoIcons.calendar_badge_minus
                  : CupertinoIcons.calendar,
              size: 22,
              color: _filterDate != null
                  ? surfaceColor
                  : surfaceColor.withValues(alpha: 0.4),
            ),
            tooltip: _filterDate != null ? 'Clear date' : 'Filter by date',
            onPressed: _pickDate,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: CupertinoSearchTextField(
              placeholder: 'Search tasks…',
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(color: surfaceColor),
            ),
          ).animate().fadeIn(duration: 200.ms),

          const SizedBox(height: 10),

          // Filter chips — monochrome style
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_filterDate != null) _buildDateChip(surfaceColor),

                ..._statusOptions.map((opt) {
                  final isActive = _statusFilter == opt;
                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? surfaceColor.withValues(
                                alpha: isDark ? 0.9 : 0.85,
                              )
                            : surfaceColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabels[opt]!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? (isDark ? Colors.black : Colors.white)
                              : surfaceColor.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms, delay: 40.ms),

          const SizedBox(height: 8),

          // Task list grouped by date
          Expanded(
            child: tasks.isEmpty
                ? _buildEmpty(surfaceColor)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: dateKeys.length,
                    itemBuilder: (context, di) {
                      final key = dateKeys[di];
                      final date = DateTime.parse(key);
                      final dayTasks = grouped[key]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateHeader(
                            date,
                            dayTasks.length,
                            surfaceColor,
                            isDark,
                          ),
                          ...dayTasks.asMap().entries.map((e) {
                            return _TaskRow(
                                  task: e.value,
                                  isDark: isDark,
                                  surfaceColor: surfaceColor,
                                )
                                .animate(
                                  delay: Duration(milliseconds: 25 * e.key),
                                )
                                .fadeIn()
                                .slideX(begin: 0.02);
                          }),
                          if (di < dateKeys.length - 1)
                            const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(Color surfaceColor) {
    return GestureDetector(
      onTap: () => setState(() => _filterDate = null),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: surfaceColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('MMM d').format(_filterDate!),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.xmark,
              size: 12,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(
    DateTime date,
    int count,
    Color surfaceColor,
    bool isDark,
  ) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(date, now);
    final isYesterday = DateUtils.isSameDay(
      date,
      now.subtract(const Duration(days: 1)),
    );

    String dayName;
    if (isToday) {
      dayName = 'Today';
    } else if (isYesterday) {
      dayName = 'Yesterday';
    } else {
      dayName = DateFormat('EEEE').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Large day number
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: surfaceColor.withValues(alpha: isToday ? 1.0 : 0.75),
              height: 1,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(width: 10),
          // Day name + month/year
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: surfaceColor.withValues(
                        alpha: isToday ? 0.9 : 0.5,
                      ),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: surfaceColor.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Count
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: surfaceColor.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color surfaceColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.tray,
            size: 48,
            color: surfaceColor.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 12),
          Text(
            'No tasks found',
            style: TextStyle(
              color: surfaceColor.withValues(alpha: 0.3),
              fontSize: 15,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ─── Minimal task row ─────────────────────────────────────────────────────────
class _TaskRow extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  final Color surfaceColor;

  const _TaskRow({
    required this.task,
    required this.isDark,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.status == 'completed';
    final cancelled = task.status == 'cancelled';

    return GestureDetector(
      onTap: () => showTaskDetailSheet(context, task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: surfaceColor.withValues(alpha: isDark ? 0.06 : 0.04),
          ),
        ),
        child: Row(
          children: [
            // Checkbox-style indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: done
                    ? surfaceColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                border: Border.all(
                  color: surfaceColor.withValues(alpha: done ? 0.12 : 0.15),
                  width: 1.5,
                ),
              ),
              child: done
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: surfaceColor.withValues(alpha: 0.5),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: surfaceColor.withValues(
                        alpha: done || cancelled ? 0.35 : 0.85,
                      ),
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: surfaceColor.withValues(alpha: 0.25),
                    ),
                  ),
                  if (task.type.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.subType.isNotEmpty
                          ? '${task.type} · ${task.subType}'
                          : task.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: surfaceColor.withValues(alpha: 0.3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Time or status hint
            if (task.time != null)
              Text(
                '${task.time!.hour.toString().padLeft(2, '0')}:${task.time!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: surfaceColor.withValues(alpha: 0.25),
                  letterSpacing: 0.3,
                ),
              )
            else
              _statusDot(done, cancelled),

            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: surfaceColor.withValues(alpha: 0.12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(bool done, bool cancelled) {
    Color dotColor;
    if (done) {
      dotColor = surfaceColor.withValues(alpha: 0.15);
    } else if (cancelled) {
      dotColor = surfaceColor.withValues(alpha: 0.15);
    } else {
      dotColor = surfaceColor.withValues(alpha: 0.25);
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
    );
  }
}
