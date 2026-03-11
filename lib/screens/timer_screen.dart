import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

enum TimerMode { focus, shortBreak, longBreak }

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  // ── Durations (seconds) ──────────────────────────────────────────────────
  static const Map<TimerMode, int> _durations = {
    TimerMode.focus: 25 * 60,
    TimerMode.shortBreak: 5 * 60,
    TimerMode.longBreak: 15 * 60,
  };

  static const Map<TimerMode, String> _labels = {
    TimerMode.focus: 'Focus',
    TimerMode.shortBreak: 'Short Break',
    TimerMode.longBreak: 'Long Break',
  };

  static const Map<TimerMode, Color> _colors = {
    TimerMode.focus: Color(0xFF3478F6),
    TimerMode.shortBreak: Color(0xFF30D158),
    TimerMode.longBreak: Color(0xFF9B59B6),
  };

  TimerMode _mode = TimerMode.focus;
  late int _remaining;
  bool _isRunning = false;
  Timer? _ticker;
  int _sessionsCompleted = 0;

  // Customisable durations (in minutes) — editable via picker
  int _focusMin = 25;
  int _shortMin = 5;
  int _longMin = 15;

  @override
  void initState() {
    super.initState();
    _remaining = _durations[_mode]!;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Computed ────────────────────────────────────────────────────────────
  int get _total {
    switch (_mode) {
      case TimerMode.focus:
        return _focusMin * 60;
      case TimerMode.shortBreak:
        return _shortMin * 60;
      case TimerMode.longBreak:
        return _longMin * 60;
    }
  }

  double get _progress => _total == 0 ? 0 : (_total - _remaining) / _total;

  Color get _color => _colors[_mode]!;

  String get _timeString {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  void _startStop() {
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining > 0) {
          setState(() => _remaining--);
        } else {
          _ticker?.cancel();
          if (_mode == TimerMode.focus) _sessionsCompleted++;
          setState(() => _isRunning = false);
          _onComplete();
        }
      });
    }
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _remaining = _total;
    });
  }

  void _switchMode(TimerMode m) {
    _ticker?.cancel();
    setState(() {
      _mode = m;
      _isRunning = false;
      _remaining = _total;
    });
  }

  void _onComplete() {
    // Brief bounce animation feedback
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          _mode == TimerMode.focus ? '🎉 Session done!' : '✅ Break over!',
        ),
        content: Text(
          _mode == TimerMode.focus
              ? 'Great focus session!\n$_sessionsCompleted session${_sessionsCompleted > 1 ? 's' : ''} completed today.'
              : 'Ready to focus again?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _switchMode(
                _mode == TimerMode.focus
                    ? TimerMode.shortBreak
                    : TimerMode.focus,
              );
            },
            child: Text(
              _mode == TimerMode.focus ? 'Take a Break' : 'Start Focus',
            ),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _showDurationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DurationPicker(
        focusMin: _focusMin,
        shortMin: _shortMin,
        longMin: _longMin,
        onSaved: (f, s, l) {
          setState(() {
            _focusMin = f;
            _shortMin = s;
            _longMin = l;
            _reset();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E10)
          : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Focus Timer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            onPressed: _showDurationPicker,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Mode tabs ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: TimerMode.values.map((m) {
                    final sel = _mode == m;
                    final c = _colors[m]!;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _switchMode(m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? c : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _labels[m]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: sel
                                  ? Colors.white
                                  : c.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            // ── Sessions pills ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final done = i < _sessionsCompleted;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? _colors[TimerMode.focus]!
                        : _colors[TimerMode.focus]!.withValues(alpha: 0.2),
                  ),
                );
              }),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 8),
            Text(
              '$_sessionsCompleted session${_sessionsCompleted != 1 ? 's' : ''} today',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),

            const Spacer(),

            // ── Big ring timer ───────────────────────────────────────────
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow
                  if (_isRunning)
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _color.withValues(alpha: 0.25),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  // Background ring
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: _ArcPainter(
                      progress: _progress,
                      color: _color,
                      isDark: isDark,
                    ),
                  ),
                  // Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeString,
                        style: TextStyle(
                          fontSize: 62,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2,
                          color: _color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isRunning ? _labels[_mode]! : 'Tap to start',
                          key: ValueKey(_isRunning),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

            const Spacer(),

            // ── Controls ─────────────────────────────────────────────────
            Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset
                      _CtrlBtn(
                        icon: CupertinoIcons.arrow_counterclockwise,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                        size: 56,
                        onTap: _reset,
                      ),
                      const SizedBox(width: 24),

                      // Play / Pause
                      GestureDetector(
                        onTap: _startStop,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _color,
                            boxShadow: [
                              BoxShadow(
                                color: _color.withValues(alpha: 0.4),
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
                            size: 32,
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Skip
                      _CtrlBtn(
                        icon: CupertinoIcons.forward_end_fill,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                        size: 56,
                        onTap: _onComplete,
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

// ─── Ring arc painter ─────────────────────────────────────────────────────────
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

    // BG
    paint.color = isDark
        ? Colors.white10
        : Colors.black.withValues(alpha: 0.06);
    canvas.drawCircle(c, r, paint);

    // Progress
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

// ─── Small control button ─────────────────────────────────────────────────────
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
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}

// ─── Duration picker sheet ────────────────────────────────────────────────────
class _DurationPicker extends StatefulWidget {
  final int focusMin, shortMin, longMin;
  final Function(int, int, int) onSaved;
  const _DurationPicker({
    required this.focusMin,
    required this.shortMin,
    required this.longMin,
    required this.onSaved,
  });
  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  late int _f, _s, _l;

  @override
  void initState() {
    super.initState();
    _f = widget.focusMin;
    _s = widget.shortMin;
    _l = widget.longMin;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const Text(
            'Timer Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _MinRow(
            label: 'Focus',
            color: const Color(0xFF3478F6),
            value: _f,
            onChanged: (v) => setState(() => _f = v),
          ),
          _MinRow(
            label: 'Short Break',
            color: const Color(0xFF30D158),
            value: _s,
            onChanged: (v) => setState(() => _s = v),
          ),
          _MinRow(
            label: 'Long Break',
            color: const Color(0xFF9B59B6),
            value: _l,
            onChanged: (v) => setState(() => _l = v),
          ),
          const SizedBox(height: 20),
          CupertinoButton(
            color: const Color(0xFF3478F6),
            borderRadius: BorderRadius.circular(14),
            onPressed: () {
              widget.onSaved(_f, _s, _l);
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinRow extends StatelessWidget {
  final String label;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;
  const _MinRow({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (value > 1) onChanged(value - 1);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                  ),
                  child: Icon(CupertinoIcons.minus, size: 16, color: color),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$value min',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (value < 99) onChanged(value + 1);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                  ),
                  child: Icon(CupertinoIcons.plus, size: 16, color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
