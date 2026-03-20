import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models/habit_model.dart';

// ─── Palette options ─────────────────────────────────────────────────────────
const _kColors = [
  Color(0xFF3478F6),
  Color(0xFF30D158),
  Color(0xFFFF453A),
  Color(0xFFFF9F0A),
  Color(0xFF9B59B6),
  Color(0xFF00C7BE),
  Color(0xFFFF375F),
  Color(0xFF64D2FF),
];

const _kIcons = [
  CupertinoIcons.star_fill,
  CupertinoIcons.flame_fill,
  CupertinoIcons.heart_fill,
  CupertinoIcons.bolt_fill,
  CupertinoIcons.book_fill,
  CupertinoIcons.moon_fill,
  CupertinoIcons.drop_fill,
  CupertinoIcons.leaf_arrow_circlepath,
  CupertinoIcons.sportscourt_fill,
  CupertinoIcons.music_note,
  CupertinoIcons.pencil,
  CupertinoIcons.briefcase_fill,
];

const _kIconPoints = [
  0xF4B4,
  0xF3FD,
  0xF37B,
  0xF305,
  0xF32B,
  0xF40C,
  0xF344,
  0xF3AD,
  0xF503,
  0xF408,
  0xF12A,
  0xF295,
];

const _kFrequencies = ['daily', 'weekdays', 'weekends'];
const _kFrequencyLabels = {
  'daily': 'Every Day',
  'weekdays': 'Weekdays',
  'weekends': 'Weekends',
};

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with TickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final habits = appState.habitBox.values.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final todayDone = habits.where((h) => h.isCompletedToday).length;
    final total = habits.length;
    final ratio = total == 0 ? 0.0 : todayDone / total;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E10)
          : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Habits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled_solid),
            onPressed: () => _showAddEditSheet(context, appState),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'All Habits'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── TODAY TAB ────────────────────────────────────────────────
          _TodayTab(
            habits: habits,
            ratio: ratio,
            todayDone: todayDone,
            total: total,
            now: now,
            isDark: isDark,
            onCheckIn: (h) => _checkIn(context, appState, h),
            onEdit: (h) => _showAddEditSheet(context, appState, existing: h),
            onDelete: (h) => _delete(appState, h),
          ),
          // ── ALL HABITS TAB ───────────────────────────────────────────
          _AllHabitsTab(
            habits: habits,
            isDark: isDark,
            onEdit: (h) => _showAddEditSheet(context, appState, existing: h),
            onDelete: (h) => _delete(appState, h),
          ),
        ],
      ),
    );
  }

  void _checkIn(BuildContext context, AppState appState, HabitModel h) {
    if (h.isCompletedToday) {
      // ── UNDO: remove today's check-in ───────────────────────────────────
      final today = DateTime.now();
      h.completedDates.removeWhere(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );
      if (h.streakCount > 0) h.streakCount -= 1;
      // Find the last completed date after removal
      if (h.completedDates.isEmpty) {
        h.lastCompletedDate = null;
      } else {
        h.lastCompletedDate = h.completedDates.reduce(
          (a, b) => a.isAfter(b) ? a : b,
        );
      }
      h.save();
      appState.refresh();
    } else {
      // ── CHECK IN ────────────────────────────────────────────────────────
      final now = DateTime.now();
      h.lastCompletedDate = now;
      h.streakCount += 1;
      h.completedDates.add(now);
      if (h.streakCount > h.bestStreak) h.bestStreak = h.streakCount;
      h.save();
      appState.refresh();
    }
  }

  void _delete(AppState appState, HabitModel h) {
    h.delete();
    appState.refresh();
  }

  void _showAddEditSheet(
    BuildContext context,
    AppState appState, {
    HabitModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: appState,
        child: _HabitFormSheet(existing: existing),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TODAY TAB
// ═══════════════════════════════════════════════════════════════════════════
class _TodayTab extends StatelessWidget {
  final List<HabitModel> habits;
  final double ratio;
  final int todayDone;
  final int total;
  final DateTime now;
  final bool isDark;
  final Function(HabitModel) onCheckIn;
  final Function(HabitModel) onEdit;
  final Function(HabitModel) onDelete;

  const _TodayTab({
    required this.habits,
    required this.ratio,
    required this.todayDone,
    required this.total,
    required this.now,
    required this.isDark,
    required this.onCheckIn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Daily summary ring
        SliverToBoxAdapter(
          child: _DailySummaryCard(
            ratio: ratio,
            done: todayDone,
            total: total,
            now: now,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
        ),

        if (habits.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.flame,
                    size: 56,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No habits yet.\nTap + to add your first!',
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.builder(
              itemCount: habits.length,
              itemBuilder: (context, i) {
                final h = habits[i];
                return _HabitTodayCard(
                      habit: h,
                      isDark: isDark,
                      onCheckIn: () => onCheckIn(h),
                      onEdit: () => onEdit(h),
                      onDelete: () => onDelete(h),
                    )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 60 * i))
                    .slideY(begin: 0.06);
              },
            ),
          ),
      ],
    );
  }
}

// ── Daily summary card ────────────────────────────────────────────────────────
class _DailySummaryCard extends StatelessWidget {
  final double ratio;
  final int done;
  final int total;
  final DateTime now;
  const _DailySummaryCard({
    required this.ratio,
    required this.done,
    required this.total,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _RingPainter(
                    ratio: ratio,
                    color: Colors.white,
                    bg: Colors.white24,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$done/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'done',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(now),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ratio == 1.0
                      ? '🎉 All done!'
                      : '${(ratio * 100).toStringAsFixed(0)}% complete',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Habit card for Today tab ──────────────────────────────────────────────────
class _HabitTodayCard extends StatelessWidget {
  final HabitModel habit;
  final bool isDark;
  final VoidCallback onCheckIn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitTodayCard({
    required this.habit,
    required this.isDark,
    required this.onCheckIn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final done = habit.isCompletedToday;

    // Last 7 days dots
    final last7 = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return habit.wasCompletedOn(d);
    });

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon circle
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: done ? 1.0 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    IconData(
                      habit.iconCodePoint,
                      fontFamily: 'CupertinoIcons',
                      fontPackage: 'cupertino_icons',
                    ),
                    color: done ? Colors.white : color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: done ? 0.5 : 1),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.flame_fill,
                            size: 13,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${habit.streakCount} day streak',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _kFrequencyLabels[habit.frequency] ?? 'Daily',
                            style: TextStyle(
                              fontSize: 11,
                              color: color.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Check-in button
                GestureDetector(
                  onTap: onCheckIn,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? color : color.withValues(alpha: 0.1),
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      done ? CupertinoIcons.checkmark : CupertinoIcons.circle,
                      color: done ? Colors.white : color,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 7-day history dots
            Row(
              children: List.generate(7, (i) {
                final day = DateTime.now().subtract(Duration(days: 6 - i));
                final filled = last7[i];
                return Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? color : color.withValues(alpha: 0.1),
                        ),
                        child: filled
                            ? const Icon(
                                CupertinoIcons.checkmark,
                                size: 13,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('E').format(day)[0],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: filled
                              ? color
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ), // Column
                ); // Expanded
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            child: const Text('Edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ALL HABITS TAB (stats per habit)
// ═══════════════════════════════════════════════════════════════════════════
class _AllHabitsTab extends StatelessWidget {
  final List<HabitModel> habits;
  final bool isDark;
  final Function(HabitModel) onEdit;
  final Function(HabitModel) onDelete;

  const _AllHabitsTab({
    required this.habits,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Center(child: Text('No habits yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: habits.length,
      itemBuilder: (context, i) {
        final h = habits[i];
        final color = Color(h.colorValue);
        final completionRate = h.completedDates.isEmpty
            ? 0.0
            : min(
                1.0,
                h.completedDates.length /
                    max(
                      1,
                      DateTime.now()
                              .difference(
                                h.completedDates.reduce(
                                  (a, b) => a.isBefore(b) ? a : b,
                                ),
                              )
                              .inDays +
                          1,
                    ),
              );

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  IconData(
                    h.iconCodePoint,
                    fontFamily: 'CupertinoIcons',
                    fontPackage: 'cupertino_icons',
                  ),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MiniStat(
                          icon: CupertinoIcons.flame_fill,
                          value: '${h.streakCount}',
                          label: 'streak',
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          icon: CupertinoIcons.star_fill,
                          value: '${h.bestStreak}',
                          label: 'best',
                          color: color,
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          icon: CupertinoIcons.checkmark_circle_fill,
                          value: '${h.completedDates.length}',
                          label: 'total',
                          color: const Color(0xFF30D158),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: completionRate,
                              minHeight: 5,
                              backgroundColor: color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(completionRate * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 18,
                ),
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (_) => CupertinoActionSheet(
                      actions: [
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit(h);
                          },
                          child: const Text('Edit'),
                        ),
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete(h);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 60 * i));
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(
        '$value $label',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD / EDIT HABIT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _HabitFormSheet extends StatefulWidget {
  final HabitModel? existing;
  const _HabitFormSheet({this.existing});
  @override
  State<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<_HabitFormSheet> {
  late TextEditingController _ctrl;
  late Color _selectedColor;
  late int _selectedIconIdx;
  late String _frequency;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existing?.title ?? '');
    _selectedColor = widget.existing != null
        ? Color(widget.existing!.colorValue)
        : _kColors[0];
    _selectedIconIdx = widget.existing != null
        ? max(0, _kIconPoints.indexOf(widget.existing!.iconCodePoint))
        : 0;
    _frequency = widget.existing?.frequency ?? 'daily';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.existing == null ? 'New Habit' : 'Edit Habit',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Title
            CupertinoTextField(
              controller: _ctrl,
              placeholder: 'e.g. Read 10 pages',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 16),

            // Color picker
            const Text(
              'Color',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _kColors.map((c) {
                final sel = c.toARGB32() == _selectedColor.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: Border.all(
                        color: sel ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: sel
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Icon picker
            const Text(
              'Icon',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_kIcons.length, (i) {
                final sel = _selectedIconIdx == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: sel
                          ? _selectedColor
                          : _selectedColor.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      _kIcons[i],
                      color: sel ? Colors.white : _selectedColor,
                      size: 20,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Frequency
            const Text(
              'Frequency',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: _kFrequencies.map((f) {
                final sel = _frequency == f;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _frequency = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? _selectedColor
                              : _selectedColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? _selectedColor : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          _kFrequencyLabels[f]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? Colors.white : _selectedColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(14),
                onPressed: () {
                  if (_ctrl.text.trim().isEmpty) return;
                  if (widget.existing != null) {
                    widget.existing!.title = _ctrl.text.trim();
                    widget.existing!.colorValue = _selectedColor.toARGB32();
                    widget.existing!.iconCodePoint =
                        _kIconPoints[_selectedIconIdx];
                    widget.existing!.frequency = _frequency;
                    widget.existing!.save();
                  } else {
                    final h = HabitModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _ctrl.text.trim(),
                      colorValue: _selectedColor.toARGB32(),
                      iconCodePoint: _kIconPoints[_selectedIconIdx],
                      frequency: _frequency,
                    );
                    appState.habitBox.put(h.id, h);
                  }
                  appState.refresh();
                  Navigator.pop(context);
                },
                child: Text(
                  widget.existing == null ? 'Add Habit' : 'Save Changes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ring painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double ratio;
  final Color color;
  final Color bg;
  const _RingPainter({
    required this.ratio,
    required this.color,
    required this.bg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 - 6;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    paint.color = bg;
    canvas.drawCircle(c, r, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * ratio,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ratio != ratio;
}
