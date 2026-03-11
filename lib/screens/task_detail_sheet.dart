import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart';
import 'task_timer_sheet.dart';

/// Parse sessions JSON for display in detail sheet.
List<Map<String, dynamic>> _parseSessions(String json) {
  try {
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
}

String _fmtTime(String iso) {
  try {
    return DateFormat('HH:mm').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

String _fmtDur(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

void showTaskDetailSheet(BuildContext context, TaskModel task) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _TaskDetailSheet(task: task),
    ),
  );
}

class _TaskDetailSheet extends StatelessWidget {
  final TaskModel task;
  const _TaskDetailSheet({required this.task});

  Color get _priorityColor {
    switch (task.priority) {
      case 'High':
        return const Color(0xFFFF453A);
      case 'Low':
        return const Color(0xFF30D158);
      default:
        return const Color(0xFFFF9F0A);
    }
  }

  Color get _statusColor {
    switch (task.status) {
      case 'completed':
        return const Color(0xFF30D158);
      case 'cancelled':
        return const Color(0xFFFF453A);
      case 'next':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF3478F6);
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'next':
        return 'Next';
      default:
        return 'In Progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sessions = _parseSessions(task.sessionsJson);
    Duration totalWorked = Duration.zero;
    for (final s in sessions) {
      if (s['start'] != null) {
        final start = DateTime.parse(s['start'] as String);
        final end = s['end'] != null
            ? DateTime.parse(s['end'] as String)
            : DateTime.now();
        totalWorked += end.difference(start);
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Status badge + Title ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      decoration: task.status == 'completed'
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _statusColor, width: 1),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => CreateTaskScreen(existingTask: task),
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.pencil, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            if (task.type.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.subType.isNotEmpty
                    ? '${task.type}  ›  ${task.subType}'
                    : task.type,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── Info grid ────────────────────────────────────────────
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(
                  icon: CupertinoIcons.flag_fill,
                  label: 'Priority',
                  value: task.priority,
                  color: _priorityColor,
                ),
                _InfoChip(
                  icon: CupertinoIcons.calendar,
                  label: 'Date',
                  value: DateFormat('MMM d, yyyy').format(task.date),
                  color: const Color(0xFF3478F6),
                ),
                if (task.time != null)
                  _InfoChip(
                    icon: CupertinoIcons.bell_fill,
                    label: 'Reminder',
                    value: DateFormat('HH:mm').format(task.time!),
                    color: const Color(0xFFFF9F0A),
                  ),
                if (task.repetition != 'None')
                  _InfoChip(
                    icon: CupertinoIcons.repeat,
                    label: 'Repeat',
                    value: task.repetition,
                    color: const Color(0xFF9B59B6),
                  ),
                if (sessions.isNotEmpty)
                  _InfoChip(
                    icon: CupertinoIcons.clock,
                    label: 'Time worked',
                    value: _fmtDur(totalWorked),
                    color: const Color(0xFF30D158),
                  ),
              ],
            ),

            // ── Notes ─────────────────────────────────────────────────
            if (task.note.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  task.note,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],

            // ── Work sessions timeline ────────────────────────────────
            if (sessions.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Work Sessions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              ...sessions.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final start = DateTime.parse(s['start'] as String);
                final hasEnd = s['end'] != null;
                final end = hasEnd
                    ? DateTime.parse(s['end'] as String)
                    : DateTime.now();
                final dur = end.difference(start);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF3478F6,
                          ).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Color(0xFF3478F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_fmtTime(s['start'] as String)} – ${hasEnd ? _fmtTime(s['end'] as String) : 'Active'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _fmtDur(dur),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3478F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                // Timer button
                Expanded(
                  child: _ActionBtn(
                    icon: CupertinoIcons.timer,
                    label: 'Timer',
                    color: const Color(0xFF3478F6),
                    onTap: () {
                      Navigator.pop(context);
                      showTaskTimerSheet(context, task);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Toggle complete
                Expanded(
                  child: _ActionBtn(
                    icon: task.status == 'completed'
                        ? CupertinoIcons.xmark_circle
                        : CupertinoIcons.checkmark_circle_fill,
                    label: task.status == 'completed' ? 'Undo' : 'Complete',
                    color: const Color(0xFF30D158),
                    onTap: () {
                      appState.toggleTaskCompleted(task);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Delete
                Expanded(
                  child: _ActionBtn(
                    icon: CupertinoIcons.trash,
                    label: 'Delete',
                    color: const Color(0xFFFF453A),
                    onTap: () {
                      Navigator.pop(context);
                      appState.deleteTask(task);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info chip ───────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Action button ───────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
