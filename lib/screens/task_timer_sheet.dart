import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/task_model.dart';

// ─── Session model (in-memory only, serialised to JSON for Hive) ─────────────
class WorkSession {
  DateTime start;
  DateTime? end;
  WorkSession({required this.start, this.end});

  bool get isActive => end == null;
  Duration get duration => (end ?? DateTime.now()).difference(start);

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    if (end != null) 'end': end!.toIso8601String(),
  };

  factory WorkSession.fromJson(Map<String, dynamic> j) => WorkSession(
    start: DateTime.parse(j['start'] as String),
    end: j['end'] != null ? DateTime.parse(j['end'] as String) : null,
  );
}

// ─── Helper: parse / serialise sessions ─────────────────────────────────────
List<WorkSession> _parseSessions(String json) {
  try {
    final list = jsonDecode(json) as List;
    return list
        .map((e) => WorkSession.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

String _serialiseSessions(List<WorkSession> sessions) =>
    jsonEncode(sessions.map((s) => s.toJson()).toList());

// ─── Format helpers ──────────────────────────────────────────────────────────
String _fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
}

String _fmtTime(DateTime t) => DateFormat('HH:mm').format(t);

// ═══════════════════════════════════════════════════════════════════════════
/// Show the task timer as a draggable bottom sheet.
void showTaskTimerSheet(BuildContext context, TaskModel task) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: TaskTimerSheet(task: task),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
class TaskTimerSheet extends StatefulWidget {
  final TaskModel task;
  const TaskTimerSheet({super.key, required this.task});

  @override
  State<TaskTimerSheet> createState() => _TaskTimerSheetState();
}

class _TaskTimerSheetState extends State<TaskTimerSheet> {
  late List<WorkSession> _sessions;
  Timer? _ticker;
  bool _done = false;

  bool get _isRunning => _sessions.isNotEmpty && _sessions.last.isActive;

  @override
  void initState() {
    super.initState();
    _sessions = _parseSessions(widget.task.sessionsJson);
    // If there's already an active session (app was killed mid-timer), resume it
    if (_isRunning) _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Timer actions ──────────────────────────────────────────────────────
  void _start() {
    setState(() => _sessions.add(WorkSession(start: DateTime.now())));
    _startTicker();
    _persist();
  }

  void _pause() {
    if (!_isRunning) return;
    setState(() => _sessions.last.end = DateTime.now());
    _ticker?.cancel();
    _ticker = null;
    _persist();
  }

  void _resume() {
    setState(() => _sessions.add(WorkSession(start: DateTime.now())));
    _startTicker();
    _persist();
  }

  void _done_() {
    _pause();
    setState(() => _done = true);
    _persist();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _persist() async {
    widget.task.sessionsJson = _serialiseSessions(_sessions);
    await widget.task.save();
  }

  // ── Computed values ────────────────────────────────────────────────────
  Duration get _totalWorked {
    return _sessions.fold(Duration.zero, (acc, s) => acc + s.duration);
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final catColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Task title
          Text(
            widget.task.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (widget.task.type.isNotEmpty)
            Text(
              widget.task.subType.isNotEmpty
                  ? '${widget.task.type} › ${widget.task.subType}'
                  : widget.task.type,
              style: TextStyle(
                fontSize: 13,
                color: catColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 30),

          // ── Timer display ─────────────────────────────────────────────
          if (!_done) ...[
            // Big clock ring
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _isRunning
                          ? (_totalWorked.inSeconds % 3600) / 3600.0
                          : null,
                      strokeWidth: 6,
                      backgroundColor: catColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmtDuration(_totalWorked),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                        ),
                      ),
                      if (_sessions.isEmpty)
                        Text(
                          'Ready',
                          style: TextStyle(
                            color: catColor.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        )
                      else if (_isRunning)
                        Text(
                          'Running…',
                          style: TextStyle(
                            color: catColor.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        )
                      else
                        Text(
                          'Paused',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Action buttons ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_sessions.isEmpty) ...[
                  // Only START
                  _BigButton(
                    icon: CupertinoIcons.play_fill,
                    label: 'Start',
                    color: catColor,
                    onTap: _start,
                  ),
                ] else if (_isRunning) ...[
                  // PAUSE + DONE
                  _BigButton(
                    icon: CupertinoIcons.pause_fill,
                    label: 'Pause',
                    color: Colors.orange,
                    onTap: _pause,
                  ),
                  const SizedBox(width: 16),
                  _BigButton(
                    icon: CupertinoIcons.checkmark_circle_fill,
                    label: 'Done',
                    color: const Color(0xFF30D158),
                    onTap: _done_,
                  ),
                ] else ...[
                  // RESUME + DONE
                  _BigButton(
                    icon: CupertinoIcons.play_fill,
                    label: 'Resume',
                    color: catColor,
                    onTap: _resume,
                  ),
                  const SizedBox(width: 16),
                  _BigButton(
                    icon: CupertinoIcons.checkmark_circle_fill,
                    label: 'Done',
                    color: const Color(0xFF30D158),
                    onTap: _done_,
                  ),
                ],
              ],
            ),
          ],

          // ── Summary / Timeline (after Done) ──────────────────────────
          if (_done) ...[
            // Total badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF30D158).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF30D158), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.clock_fill,
                    color: Color(0xFF30D158),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Total: ${_fmtDuration(_totalWorked)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF30D158),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Timeline
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),

            ..._sessions.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              final dur = s.duration;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: catColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_fmtTime(s.start)} – ${s.end != null ? _fmtTime(s.end!) : 'Now'}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _fmtDuration(dur),
                      style: TextStyle(
                        fontSize: 13,
                        color: catColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Close / Mark Complete
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: catColor,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: () {
                      context.read<AppState>().updateTaskStatus(
                        widget.task,
                        'completed',
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Mark as Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Reusable action button ──────────────────────────────────────────────────
class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
