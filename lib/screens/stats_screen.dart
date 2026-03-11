import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_state.dart';
import '../models/task_model.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _period = 'week'; // week, month, all

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTasks = appState.taskBox.values.toList();
    final allHabits = appState.habitBox.values.toList();
    final now = DateTime.now();

    // ── Filter tasks by period ───────────────────────────────────────────────
    final tasks = _filterTasks(allTasks, now);

    // ── Core numbers ─────────────────────────────────────────────────────────
    final total = tasks.length;
    final completed = tasks.where((t) => t.status == 'completed').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final cancelled = tasks.where((t) => t.status == 'cancelled').length;
    final rate = total == 0 ? 0.0 : completed / total;

    // ── Day-of-week breakdown ─────────────────────────────────────────────────
    final Map<int, int> completedByDow = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
    };
    final Map<int, int> totalByDow = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (final t in tasks) {
      final dow = t.date.weekday;
      totalByDow[dow] = (totalByDow[dow] ?? 0) + 1;
      if (t.status == 'completed') {
        completedByDow[dow] = (completedByDow[dow] ?? 0) + 1;
      }
    }

    // ── Category breakdown ────────────────────────────────────────────────────
    final Map<String, int> catTotal = {};
    final Map<String, int> catDone = {};
    for (final t in tasks) {
      if (t.type.isEmpty) continue;
      catTotal[t.type] = (catTotal[t.type] ?? 0) + 1;
      if (t.status == 'completed') catDone[t.type] = (catDone[t.type] ?? 0) + 1;
    }
    final sortedCats = catTotal.keys.toList()
      ..sort((a, b) => (catTotal[b]! - catTotal[a]!));

    // ── Priority breakdown ────────────────────────────────────────────────────
    final highTotal = tasks.where((t) => t.priority == 'High').length;
    final normTotal = tasks.where((t) => t.priority == 'Normal').length;
    final lowTotal = tasks.where((t) => t.priority == 'Low').length;
    final highDone = tasks
        .where((t) => t.priority == 'High' && t.status == 'completed')
        .length;
    final normDone = tasks
        .where((t) => t.priority == 'Normal' && t.status == 'completed')
        .length;
    final lowDone = tasks
        .where((t) => t.priority == 'Low' && t.status == 'completed')
        .length;

    // ── Habit stats ───────────────────────────────────────────────────────────
    final maxStreak = allHabits.isEmpty
        ? 0
        : allHabits.map((h) => h.streakCount).reduce(max);
    final maxBest = allHabits.isEmpty
        ? 0
        : allHabits.map((h) => h.bestStreak).reduce(max);
    final habitsDoneToday = allHabits.where((h) => h.isCompletedToday).length;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E10)
          : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Stats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── Period selector ──────────────────────────────────────────
          _PeriodSelector(
            period: _period,
            onChanged: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: 16),

          // ── Summary hero ─────────────────────────────────────────────
          _HeroCard(
            rate: rate,
            completed: completed,
            total: total,
            inProgress: inProgress,
            cancelled: cancelled,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

          const SizedBox(height: 16),

          // ── Status breakdown ─────────────────────────────────────────
          _SectionTitle('Task Breakdown'),
          _StatusBreakdown(
            completed: completed,
            inProgress: inProgress,
            cancelled: cancelled,
            total: total,
            isDark: isDark,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // ── Day of week heatmap ──────────────────────────────────────
          _SectionTitle('Best Days of the Week'),
          _DayOfWeekChart(
            completedByDow: completedByDow,
            totalByDow: totalByDow,
            isDark: isDark,
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          // ── Category performance ─────────────────────────────────────
          if (sortedCats.isNotEmpty) ...[
            _SectionTitle('By Category'),
            _CategoryChart(
              cats: sortedCats,
              catTotal: catTotal,
              catDone: catDone,
              isDark: isDark,
              appState: appState,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
          ],

          // ── Priority breakdown ────────────────────────────────────────
          _SectionTitle('By Priority'),
          _PriorityBreakdown(
            highTotal: highTotal,
            highDone: highDone,
            normTotal: normTotal,
            normDone: normDone,
            lowTotal: lowTotal,
            lowDone: lowDone,
            isDark: isDark,
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 16),

          // ── Habit summary ─────────────────────────────────────────────
          _SectionTitle('Habits'),
          Row(
            children: [
              Expanded(
                child: _SmallStatCard(
                  icon: CupertinoIcons.flame_fill,
                  color: Colors.orange,
                  label: 'Top Streak',
                  value: '$maxStreak days',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallStatCard(
                  icon: CupertinoIcons.star_fill,
                  color: const Color(0xFF9B59B6),
                  label: 'Best Ever',
                  value: '$maxBest days',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallStatCard(
                  icon: CupertinoIcons.checkmark_circle_fill,
                  color: const Color(0xFF30D158),
                  label: 'Done Today',
                  value: '$habitsDoneToday/${allHabits.length}',
                  isDark: isDark,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          // ── Journal count ─────────────────────────────────────────────
          _SectionTitle('Journal'),
          _SmallStatCard(
            icon: CupertinoIcons.book_fill,
            color: const Color(0xFF3478F6),
            label: 'Total Journal Entries',
            value: '${appState.journalBox.length}',
            isDark: isDark,
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }

  List<TaskModel> _filterTasks(List<TaskModel> all, DateTime now) {
    switch (_period) {
      case 'week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return all
            .where(
              (t) => !t.date.isBefore(
                DateTime(monday.year, monday.month, monday.day),
              ),
            )
            .toList();
      case 'month':
        return all
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
      default:
        return all;
    }
  }
}

// ─── Period selector ─────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final String period;
  final ValueChanged<String> onChanged;
  const _PeriodSelector({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<String>(
      groupValue: period,
      children: const {
        'week': Text('This Week'),
        'month': Text('This Month'),
        'all': Text('All Time'),
      },
      onValueChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ─── Hero completion card ──────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double rate;
  final int completed, total, inProgress, cancelled;
  final bool isDark;
  const _HeroCard({
    required this.rate,
    required this.completed,
    required this.total,
    required this.inProgress,
    required this.cancelled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
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
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(90, 90),
                  painter: _RingPainter(
                    ratio: rate,
                    color: Colors.white,
                    bg: Colors.white24,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(rate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                  '$completed of $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'tasks completed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PillStat(
                      label: 'Active',
                      value: '$inProgress',
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    _PillStat(
                      label: 'Cancelled',
                      value: '$cancelled',
                      color: Colors.white70,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PillStat({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$value $label',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

// ─── Status breakdown bar ─────────────────────────────────────────────────────
class _StatusBreakdown extends StatelessWidget {
  final int completed, inProgress, cancelled, total;
  final bool isDark;
  const _StatusBreakdown({
    required this.completed,
    required this.inProgress,
    required this.cancelled,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        children: [
          _StatusRow(
            label: 'Completed',
            value: completed,
            total: total,
            color: const Color(0xFF30D158),
          ),
          const SizedBox(height: 10),
          _StatusRow(
            label: 'In Progress',
            value: inProgress,
            total: total,
            color: const Color(0xFF3478F6),
          ),
          const SizedBox(height: 10),
          _StatusRow(
            label: 'Cancelled',
            value: cancelled,
            total: total,
            color: const Color(0xFFFF453A),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int value, total;
  final Color color;
  const _StatusRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (_, v, child) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Day of week chart ───────────────────────────────────────────────────────
class _DayOfWeekChart extends StatelessWidget {
  final Map<int, int> completedByDow, totalByDow;
  final bool isDark;
  const _DayOfWeekChart({
    required this.completedByDow,
    required this.totalByDow,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = totalByDow.values.fold(0, max);
    final primary = Theme.of(context).colorScheme.primary;

    return _Card(
      isDark: isDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final dow = i + 1;
          final t = totalByDow[dow] ?? 0;
          final d = completedByDow[dow] ?? 0;
          final ratio = maxVal == 0 ? 0.0 : t / maxVal;
          final doneRatio = t == 0 ? 0.0 : d / t;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$d/$t',
                    style: TextStyle(
                      fontSize: 10,
                      color: primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 80,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Background bar
                        Container(
                          width: double.infinity,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Total bar
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: ratio),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOut,
                          builder: (_, v, child) => FractionallySizedBox(
                            heightFactor: v,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        // Done bar
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: ratio * doneRatio),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOut,
                          builder: (_, v, child) => FractionallySizedBox(
                            heightFactor: v,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DateTime.now().weekday == dow
                          ? primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Category chart ──────────────────────────────────────────────────────────
class _CategoryChart extends StatelessWidget {
  final List<String> cats;
  final Map<String, int> catTotal, catDone;
  final bool isDark;
  final AppState appState;
  const _CategoryChart({
    required this.cats,
    required this.catTotal,
    required this.catDone,
    required this.isDark,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        children: cats.take(6).map((cat) {
          final t = catTotal[cat] ?? 0;
          final d = catDone[cat] ?? 0;
          final ratio = t == 0 ? 0.0 : d / t;
          // Find category color
          final catModel = appState.categoryBox.values
              .where((c) => c.title == cat)
              .firstOrNull;
          final color = catModel != null
              ? Color(catModel.colorValue)
              : const Color(0xFF3478F6);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (catModel != null)
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconData(
                        catModel.iconCodePoint,
                        fontFamily: 'CupertinoIcons',
                        fontPackage: 'cupertino_icons',
                      ),
                      size: 14,
                      color: color,
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    cat,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (_, v, child) => LinearProgressIndicator(
                        value: v,
                        minHeight: 10,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    '$d/$t',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Priority breakdown ───────────────────────────────────────────────────────
class _PriorityBreakdown extends StatelessWidget {
  final int highTotal, highDone, normTotal, normDone, lowTotal, lowDone;
  final bool isDark;
  const _PriorityBreakdown({
    required this.highTotal,
    required this.highDone,
    required this.normTotal,
    required this.normDone,
    required this.lowTotal,
    required this.lowDone,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Row(
        children: [
          Expanded(
            child: _PriorityPill(
              label: 'High',
              total: highTotal,
              done: highDone,
              color: const Color(0xFFFF453A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PriorityPill(
              label: 'Normal',
              total: normTotal,
              done: normDone,
              color: const Color(0xFFFF9F0A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PriorityPill(
              label: 'Low',
              total: lowTotal,
              done: lowDone,
              color: const Color(0xFF30D158),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String label;
  final int total, done;
  final Color color;
  const _PriorityPill({
    required this.label,
    required this.total,
    required this.done,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$done/$total',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              builder: (_, v, child) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(ratio * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small stat card ──────────────────────────────────────────────────────────
class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final bool isDark;
  const _SmallStatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    ),
  );
}

// ─── Reusable card shell ──────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
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
    child: child,
  );
}

// ─── Section title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
  );
}

// ─── Ring painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double ratio;
  final Color color, bg;
  const _RingPainter({
    required this.ratio,
    required this.color,
    required this.bg,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 - 7;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
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
  bool shouldRepaint(_RingPainter o) => o.ratio != ratio;
}
