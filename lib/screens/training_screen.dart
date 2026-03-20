import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class TrainingExercise {
  String name;
  int sets;
  int reps;
  int workSeconds; // seconds per set of work
  int restSeconds; // seconds rest between sets

  TrainingExercise({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.workSeconds = 40,
    this.restSeconds = 20,
  });

  TrainingExercise copyWith({
    String? name,
    int? sets,
    int? reps,
    int? workSeconds,
    int? restSeconds,
  }) => TrainingExercise(
    name: name ?? this.name,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    workSeconds: workSeconds ?? this.workSeconds,
    restSeconds: restSeconds ?? this.restSeconds,
  );
}

// Preset templates
const _kPresets = [
  ('HIIT 20/10', [
    ('Burpees', 3, 10, 20, 10),
    ('Jump Squats', 3, 12, 20, 10),
    ('Mountain Climbers', 3, 15, 20, 10),
    ('High Knees', 3, 20, 20, 10),
  ]),
  ('Strength 45/15', [
    ('Push-ups', 4, 12, 45, 15),
    ('Squats', 4, 15, 45, 15),
    ('Plank Hold', 4, 1, 45, 15),
    ('Dumbbell Rows', 4, 10, 45, 15),
  ]),
  ('Stretching', [
    ('Neck Rolls', 2, 5, 30, 10),
    ('Shoulder Stretch', 2, 1, 30, 10),
    ('Hip Flexor Stretch', 2, 1, 40, 10),
    ('Hamstring Stretch', 2, 1, 40, 10),
  ]),
];

// ─── Main screen ──────────────────────────────────────────────────────────────
class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with TickerProviderStateMixin {
  List<TrainingExercise> _exercises = [];
  bool _inSession = false;

  void _startSession() {
    if (_exercises.isEmpty) return;
    setState(() => _inSession = true);
  }

  void _endSession(int totalSecs) {
    setState(() => _inSession = false);
    _showSummary(totalSecs);
  }

  void _showSummary(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('🎉 Workout Done!'),
        content: Text(
          'Total time: ${m}m ${s}s\n'
          '${_exercises.length} exercise${_exercises.length > 1 ? 's' : ''} completed!',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_inSession) {
      return _SessionView(
        exercises: _exercises,
        isDark: isDark,
        onDone: _endSession,
        onCancel: () => setState(() => _inSession = false),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E0E10) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Training',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_exercises.isNotEmpty)
            TextButton(
              onPressed: _startSession,
              child: Text(
                'Start',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Presets ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _PresetsBar(
              onSelect: (exercises) => setState(() => _exercises = exercises),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Exercise list ───────────────────────────────────────────────
          if (_exercises.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.sportscourt_fill,
                      size: 56,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No exercises yet.\nPick a preset or tap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.builder(
                itemCount: _exercises.length,
                itemBuilder: (context, i) {
                  final ex = _exercises[i];
                  return _ExerciseCard(
                    exercise: ex,
                    index: i,
                    isDark: isDark,
                    onEdit: () => _showAddEditSheet(i),
                    onDelete: () => setState(() => _exercises.removeAt(i)),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 60 * i))
                      .slideY(begin: 0.08);
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(null),
        backgroundColor: const Color(0xFF30D158),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(CupertinoIcons.add),
      ),
    );
  }

  void _showAddEditSheet(int? editIndex) {
    final editing =
        editIndex != null ? _exercises[editIndex] : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ExerciseFormSheet(
        existing: editing,
        onSave: (ex) {
          setState(() {
            if (editIndex != null) {
              _exercises[editIndex] = ex;
            } else {
              _exercises.add(ex);
            }
          });
        },
      ),
    );
  }
}

// ─── Preset picker bar ────────────────────────────────────────────────────────
class _PresetsBar extends StatelessWidget {
  final void Function(List<TrainingExercise>) onSelect;
  const _PresetsBar({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presets',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kPresets.map((preset) {
                final name = preset.$1;
                final exercises = preset.$2.map((e) => TrainingExercise(
                  name: e.$1,
                  sets: e.$2,
                  reps: e.$3,
                  workSeconds: e.$4,
                  restSeconds: e.$5,
                )).toList();
                return GestureDetector(
                  onTap: () => onSelect(exercises),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF30D158),
                          const Color(0xFF30D158).withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF30D158).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.bolt_fill,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Exercise card ────────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final TrainingExercise exercise;
  final int index;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF30D158);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  children: [
                    _Chip('${exercise.sets} sets', CupertinoIcons.repeat, color),
                    _Chip(
                      '${exercise.reps} reps',
                      CupertinoIcons.arrow_2_squarepath,
                      color,
                    ),
                    _Chip(
                      '${exercise.workSeconds}s work',
                      CupertinoIcons.play_fill,
                      color,
                    ),
                    _Chip(
                      '${exercise.restSeconds}s rest',
                      CupertinoIcons.pause_fill,
                      const Color(0xFFFF9F0A),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Icon(
                  CupertinoIcons.pencil_circle_fill,
                  color: color.withValues(alpha: 0.7),
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  CupertinoIcons.trash_circle_fill,
                  color: const Color(0xFFFF453A).withValues(alpha: 0.7),
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Chip(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

// ─── Exercise form sheet ──────────────────────────────────────────────────────
class _ExerciseFormSheet extends StatefulWidget {
  final TrainingExercise? existing;
  final void Function(TrainingExercise) onSave;
  const _ExerciseFormSheet({this.existing, required this.onSave});
  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  late TextEditingController _nameCtrl;
  late int _sets, _reps, _workSecs, _restSecs;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _sets = ex?.sets ?? 3;
    _reps = ex?.reps ?? 10;
    _workSecs = ex?.workSeconds ?? 40;
    _restSecs = ex?.restSeconds ?? 20;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing == null ? 'New Exercise' : 'Edit Exercise',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _nameCtrl,
              autofocus: true,
              placeholder: 'Exercise name (e.g. Push-ups)',
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            _NumRow(
              label: 'Sets',
              value: _sets,
              min: 1,
              max: 20,
              color: const Color(0xFF30D158),
              onChanged: (v) => setState(() => _sets = v),
            ),
            _NumRow(
              label: 'Reps',
              value: _reps,
              min: 1,
              max: 100,
              color: const Color(0xFF3478F6),
              onChanged: (v) => setState(() => _reps = v),
            ),
            _NumRow(
              label: 'Work (secs)',
              value: _workSecs,
              min: 5,
              max: 300,
              step: 5,
              color: const Color(0xFF30D158),
              onChanged: (v) => setState(() => _workSecs = v),
            ),
            _NumRow(
              label: 'Rest (secs)',
              value: _restSecs,
              min: 0,
              max: 120,
              step: 5,
              color: const Color(0xFFFF9F0A),
              onChanged: (v) => setState(() => _restSecs = v),
            ),
            const SizedBox(height: 20),
            CupertinoButton(
              color: const Color(0xFF30D158),
              borderRadius: BorderRadius.circular(14),
              onPressed: () {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) return;
                widget.onSave(TrainingExercise(
                  name: name,
                  sets: _sets,
                  reps: _reps,
                  workSeconds: _workSecs,
                  restSeconds: _restSecs,
                ));
                Navigator.pop(context);
              },
              child: Text(
                widget.existing == null ? 'Add Exercise' : 'Save Changes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumRow extends StatelessWidget {
  final String label;
  final int value, min, max;
  final int step;
  final Color color;
  final ValueChanged<int> onChanged;
  const _NumRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            children: [
              _RoundBtn(
                icon: CupertinoIcons.minus,
                color: color,
                onTap: () {
                  if (value - step >= min) onChanged(value - step);
                },
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
              _RoundBtn(
                icon: CupertinoIcons.plus,
                color: color,
                onTap: () {
                  if (value + step <= max) onChanged(value + step);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: 16, color: color),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SESSION VIEW — the actual workout timer
// ═══════════════════════════════════════════════════════════════════════════
class _SessionView extends StatefulWidget {
  final List<TrainingExercise> exercises;
  final bool isDark;
  final void Function(int totalSecs) onDone;
  final VoidCallback onCancel;
  const _SessionView({
    required this.exercises,
    required this.isDark,
    required this.onDone,
    required this.onCancel,
  });

  @override
  State<_SessionView> createState() => _SessionViewState();
}

enum _Phase { work, rest }

class _SessionViewState extends State<_SessionView> {
  int _exIdx = 0; // current exercise
  int _setIdx = 0; // current set (0-based)
  _Phase _phase = _Phase.work;
  late int _remaining;
  bool _isRunning = false;
  Timer? _ticker;
  int _totalElapsed = 0;

  @override
  void initState() {
    super.initState();
    _resetPhase();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  TrainingExercise get _currentEx => widget.exercises[_exIdx];

  int get _phaseDuration =>
      _phase == _Phase.work
          ? _currentEx.workSeconds
          : _currentEx.restSeconds;

  double get _progress =>
      _phaseDuration == 0 ? 1.0 : (_phaseDuration - _remaining) / _phaseDuration;

  void _resetPhase() {
    _remaining =
        _phase == _Phase.work
            ? _currentEx.workSeconds
            : _currentEx.restSeconds;
  }

  void _startStop() {
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _totalElapsed++;
        if (_remaining > 0) {
          setState(() => _remaining--);
        } else {
          _ticker?.cancel();
          setState(() => _isRunning = false);
          _advance();
        }
      });
    }
  }

  void _advance() {
    if (_phase == _Phase.work) {
      // Move to rest (or skip rest if restSeconds == 0)
      if (_currentEx.restSeconds > 0) {
        setState(() {
          _phase = _Phase.rest;
          _resetPhase();
        });
      } else {
        _nextSet();
      }
    } else {
      // Rest done → next set
      _nextSet();
    }
  }

  void _nextSet() {
    if (_setIdx + 1 < _currentEx.sets) {
      setState(() {
        _setIdx++;
        _phase = _Phase.work;
        _resetPhase();
      });
    } else {
      // Exercise done → next exercise
      if (_exIdx + 1 < widget.exercises.length) {
        setState(() {
          _exIdx++;
          _setIdx = 0;
          _phase = _Phase.work;
          _resetPhase();
        });
        _showExerciseTransition();
      } else {
        // All done!
        widget.onDone(_totalElapsed);
      }
    }
  }

  void _showExerciseTransition() {
    final next = widget.exercises[_exIdx];
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Next Exercise!'),
        content: Text('Get ready for:\n${next.name}'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ready!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWork = _phase == _Phase.work;
    final color = isWork ? const Color(0xFF30D158) : const Color(0xFFFF9F0A);

    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor:
          widget.isDark ? const Color(0xFF0E0E10) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: () {
            _ticker?.cancel();
            widget.onCancel();
          },
        ),
        title: const Text(
          'Training Session',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ── Exercise name & set indicator ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    _currentEx.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Set ${_setIdx + 1} of ${_currentEx.sets}',
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_currentEx.reps} reps',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Set progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_currentEx.sets, (i) {
                      final done = i < _setIdx;
                      final current = i == _setIdx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: current ? 16 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: done
                              ? color
                              : current
                              ? color.withValues(alpha: 0.6)
                              : color.withValues(alpha: 0.15),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Phase tag ─────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isWork ? '💪 WORK' : '😤 REST',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),

            const Spacer(),

            // ── Big ring timer ────────────────────────────────────────
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isRunning)
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  CustomPaint(
                    size: const Size(240, 240),
                    painter: _ArcPainter(
                      progress: _progress,
                      color: color,
                      isDark: widget.isDark,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$m:$s',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2,
                          color: color,
                        ),
                      ),
                      Text(
                        isWork ? 'Go!' : 'Rest',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

            const Spacer(),

            // ── Controls ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip phase
                  _CtrlBtn(
                    icon: CupertinoIcons.forward_end_fill,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 52,
                    onTap: () {
                      _ticker?.cancel();
                      setState(() => _isRunning = false);
                      _advance();
                    },
                  ),
                  const SizedBox(width: 24),

                  // Play/Pause
                  GestureDetector(
                    onTap: _startStop,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRunning
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Exercise progress indicator
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_exIdx + 1}/${widget.exercises.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 52,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_exIdx + 1) / widget.exercises.length,
                            minHeight: 6,
                            backgroundColor:
                                color.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'exercise',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Arc painter (same as timer_screen) ───────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;
  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 - 12;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    paint.color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);
    canvas.drawCircle(c, r, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter o) =>
      o.progress != progress || o.color != color;
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  const _CtrlBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
  );
}
