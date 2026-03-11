import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart';

enum CalendarViewMode { day, week, month, year }

class CalendarScreen extends StatefulWidget {
  final CalendarViewMode initialMode;
  const CalendarScreen({super.key, this.initialMode = CalendarViewMode.week});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late CalendarViewMode _mode;
  late DateTime _focusDate;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _focusDate = DateTime.now();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _switchMode(CalendarViewMode m) {
    setState(() => _mode = m);
    _animCtrl.forward(from: 0);
  }

  void _prev() {
    setState(() {
      switch (_mode) {
        case CalendarViewMode.day:
          _focusDate = _focusDate.subtract(const Duration(days: 1));
          break;
        case CalendarViewMode.week:
          _focusDate = _focusDate.subtract(const Duration(days: 7));
          break;
        case CalendarViewMode.month:
          _focusDate = DateTime(_focusDate.year, _focusDate.month - 1, 1);
          break;
        case CalendarViewMode.year:
          _focusDate = DateTime(_focusDate.year - 1);
          break;
      }
    });
    _animCtrl.forward(from: 0);
  }

  void _next() {
    setState(() {
      switch (_mode) {
        case CalendarViewMode.day:
          _focusDate = _focusDate.add(const Duration(days: 1));
          break;
        case CalendarViewMode.week:
          _focusDate = _focusDate.add(const Duration(days: 7));
          break;
        case CalendarViewMode.month:
          _focusDate = DateTime(_focusDate.year, _focusDate.month + 1, 1);
          break;
        case CalendarViewMode.year:
          _focusDate = DateTime(_focusDate.year + 1);
          break;
      }
    });
    _animCtrl.forward(from: 0);
  }

  String get _headerTitle {
    switch (_mode) {
      case CalendarViewMode.day:
        return DateFormat('EEEE, d MMM yyyy').format(_focusDate);
      case CalendarViewMode.week:
        final monday = _focusDate.subtract(
          Duration(days: _focusDate.weekday - 1),
        );
        final sunday = monday.add(const Duration(days: 6));
        if (monday.month == sunday.month) {
          return '${DateFormat('d').format(monday)}–${DateFormat('d MMM yyyy').format(sunday)}';
        }
        return '${DateFormat('d MMM').format(monday)} – ${DateFormat('d MMM yyyy').format(sunday)}';
      case CalendarViewMode.month:
        return DateFormat('MMMM yyyy').format(_focusDate);
      case CalendarViewMode.year:
        return '${_focusDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // context.watch ensures real-time refresh whenever AppState.notifyListeners() fires
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.today),
            tooltip: 'Go to Today',
            onPressed: () => setState(() => _focusDate = DateTime.now()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => const CreateTaskScreen(initialCategory: null),
            ),
          );
        },
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(CupertinoIcons.add, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildModeSelector(primary),
            _buildNavHeader(primary),
            Expanded(
              child: FadeTransition(
                opacity: _animCtrl,
                child: _buildContent(appState, isDark, primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(Color primary) {
    final modes = [
      (CalendarViewMode.day, 'Day'),
      (CalendarViewMode.week, 'Week'),
      (CalendarViewMode.month, 'Month'),
      (CalendarViewMode.year, 'Year'),
    ];
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: modes.map((e) {
          final isActive = _mode == e.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(e.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isActive ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    e.$2,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                      color: isActive
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavHeader(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _prev,
            icon: const Icon(CupertinoIcons.chevron_left, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardTheme.color,
              padding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _headerTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            onPressed: _next,
            icon: const Icon(CupertinoIcons.chevron_right, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardTheme.color,
              padding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppState appState, bool isDark, Color primary) {
    switch (_mode) {
      case CalendarViewMode.day:
        return _DayView(
          date: _focusDate,
          appState: appState,
          primary: primary,
          isDark: isDark,
        );
      case CalendarViewMode.week:
        return _WeekView(
          focusDate: _focusDate,
          appState: appState,
          primary: primary,
          isDark: isDark,
          onDayTap: (d) => setState(() {
            _focusDate = d;
            _switchMode(CalendarViewMode.day);
          }),
        );
      case CalendarViewMode.month:
        return _MonthView(
          focusDate: _focusDate,
          appState: appState,
          primary: primary,
          isDark: isDark,
          onDayTap: (d) => setState(() {
            _focusDate = d;
            _switchMode(CalendarViewMode.day);
          }),
        );
      case CalendarViewMode.year:
        return _YearView(
          focusDate: _focusDate,
          appState: appState,
          primary: primary,
          onMonthTap: (d) => setState(() {
            _focusDate = d;
            _switchMode(CalendarViewMode.month);
          }),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _DayView extends StatelessWidget {
  final DateTime date;
  final AppState appState;
  final Color primary;
  final bool isDark;

  const _DayView({
    required this.date,
    required this.appState,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tasks =
        appState.taskBox.values
            .where(
              (t) =>
                  t.date.year == date.year &&
                  t.date.month == date.month &&
                  t.date.day == date.day,
            )
            .toList()
          ..sort((a, b) {
            if (a.time == null && b.time == null) return 0;
            if (a.time == null) return 1;
            if (b.time == null) return -1;
            return (a.time!.hour * 60 + a.time!.minute).compareTo(
              b.time!.hour * 60 + b.time!.minute,
            );
          });

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.calendar_badge_plus,
              size: 56,
              color: primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks on this day',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<TaskModel>>{};
    for (final t in tasks) {
      (grouped[t.type.isEmpty ? 'Other' : t.type] ??= []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: grouped.entries.indexed.map((entry) {
        final i = entry.$1;
        final catName = entry.$2.key;
        final catTasks = entry.$2.value;
        final catModel = appState.categoryBox.values
            .where((c) => c.title == catName)
            .firstOrNull;
        final catColor = catModel != null
            ? Color(catModel.colorValue)
            : primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF232536) : const Color(0xFFE2E4ED),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: catColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      catName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: catColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${catTasks.where((t) => t.status == "completed").length}/${catTasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: catColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...catTasks.asMap().entries.map((e) {
                final task = e.value;
                final isLast = e.key == catTasks.length - 1;
                final done = task.status == 'completed';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? const Color(0xFF232536)
                                  : const Color(0xFFEEF0F8),
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: done ? catColor : Colors.transparent,
                          border: Border.all(
                            color: catColor.withValues(alpha: done ? 0 : 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: done
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: done ? 0.4 : 1),
                              ),
                            ),
                            if (task.note.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                task.note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (task.time != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${task.time!.hour.toString().padLeft(2, '0')}:${task.time!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: catColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 60 * i)).slideY(begin: 0.08);
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEK VIEW  –  Big tappable day cards with task count + category color bars
// ─────────────────────────────────────────────────────────────────────────────
class _WeekView extends StatelessWidget {
  final DateTime focusDate;
  final AppState appState;
  final Color primary;
  final bool isDark;
  final void Function(DateTime) onDayTap;

  const _WeekView({
    required this.focusDate,
    required this.appState,
    required this.primary,
    required this.isDark,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    // AppState uses ChangeNotifier + context.watch in parent → real-time refresh
    final monday = focusDate.subtract(Duration(days: focusDate.weekday - 1));
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 6,
          childAspectRatio: 0.50,
        ),
        itemCount: 7,
        itemBuilder: (context, i) {
          final day = monday.add(Duration(days: i));
          final isToday =
              day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;

          final dayTasks = appState.taskBox.values
              .where(
                (t) =>
                    t.date.year == day.year &&
                    t.date.month == day.month &&
                    t.date.day == day.day,
              )
              .toList();

          final totalCount = dayTasks.length;
          final doneCount = dayTasks
              .where((t) => t.status == 'completed')
              .length;

          // Gather unique category colors (up to 4)
          final catColors = dayTasks
              .map((t) {
                final cat = appState.categoryBox.values
                    .where((c) => c.title == t.type)
                    .firstOrNull;
                return cat != null ? Color(cat.colorValue) : primary;
              })
              .toSet()
              .take(4)
              .toList();

          return GestureDetector(
            onTap: () => onDayTap(day),
            child:
                AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: isToday
                            ? primary
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                        border: isToday
                            ? null
                            : Border.all(
                                color: isDark
                                    ? const Color(0xFF2A2B3D)
                                    : const Color(0xFFE8EAEF),
                                width: 1,
                              ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Day name
                            Text(
                              DateFormat('E').format(day).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isToday
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                              ),
                            ),
                            // Day number
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isToday
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            // Task count badge + category bars
                            if (totalCount > 0) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$doneCount/$totalCount',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isToday ? Colors.white : primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Column(
                                children: catColors
                                    .map(
                                      (c) => Container(
                                        height: 4,
                                        margin: const EdgeInsets.only(
                                          bottom: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? Colors.white.withValues(
                                                  alpha: 0.6,
                                                )
                                              : c,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .animate(delay: Duration(milliseconds: 40 * i))
                    .fadeIn()
                    .slideY(begin: 0.08),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTH VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _MonthView extends StatelessWidget {
  final DateTime focusDate;
  final AppState appState;
  final Color primary;
  final bool isDark;
  final void Function(DateTime) onDayTap;

  const _MonthView({
    required this.focusDate,
    required this.appState,
    required this.primary,
    required this.isDark,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstOfMonth = DateTime(focusDate.year, focusDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      focusDate.year,
      focusDate.month,
    );
    final startOffset = firstOfMonth.weekday - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((label) {
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 0.75,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();
              final day = index - startOffset + 1;
              final date = DateTime(focusDate.year, focusDate.month, day);
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final dayTasks = appState.taskBox.values
                  .where(
                    (t) =>
                        t.date.year == date.year &&
                        t.date.month == date.month &&
                        t.date.day == date.day,
                  )
                  .toList();
              final catColors = dayTasks
                  .map((t) {
                    final cat = appState.categoryBox.values
                        .where((c) => c.title == t.type)
                        .firstOrNull;
                    return cat != null ? Color(cat.colorValue) : primary;
                  })
                  .toSet()
                  .take(3)
                  .toList();

              return GestureDetector(
                onTap: () => onDayTap(date),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isToday ? primary : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 14,
                            color: isToday
                                ? Colors.white
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(
                                    alpha: date.weekday >= 6 ? 0.4 : 1,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: catColors
                          .map(
                            (c) => Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _MonthTaskList(
            focusDate: focusDate,
            appState: appState,
            primary: primary,
            isDark: isDark,
            onDayTap: onDayTap,
          ),
        ),
      ],
    );
  }
}

class _MonthTaskList extends StatelessWidget {
  final DateTime focusDate;
  final AppState appState;
  final Color primary;
  final bool isDark;
  final void Function(DateTime) onDayTap;

  const _MonthTaskList({
    required this.focusDate,
    required this.appState,
    required this.primary,
    required this.isDark,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      focusDate.year,
      focusDate.month,
    );
    final List<MapEntry<DateTime, List<TaskModel>>> dayGroups = [];
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(focusDate.year, focusDate.month, d);
      final tasks = appState.taskBox.values
          .where(
            (t) =>
                t.date.year == date.year &&
                t.date.month == date.month &&
                t.date.day == date.day,
          )
          .toList();
      if (tasks.isNotEmpty) dayGroups.add(MapEntry(date, tasks));
    }

    if (dayGroups.isEmpty) {
      return Center(
        child: Text(
          'No tasks this month',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: dayGroups.length,
      itemBuilder: (context, i) {
        final entry = dayGroups[i];
        final date = entry.key;
        final tasks = entry.value;
        return GestureDetector(
          onTap: () => onDayTap(date),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF232536)
                    : const Color(0xFFE2E4ED),
              ),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('EEE d').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tasks.map((t) => t.title).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${tasks.length} task${tasks.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YEAR VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _YearView extends StatelessWidget {
  final DateTime focusDate;
  final AppState appState;
  final Color primary;
  final void Function(DateTime) onMonthTap;

  const _YearView({
    required this.focusDate,
    required this.appState,
    required this.primary,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final monthDate = DateTime(focusDate.year, i + 1, 1);
        final isCurrentMonth =
            today.year == monthDate.year && today.month == monthDate.month;
        final daysInMonth = DateUtils.getDaysInMonth(focusDate.year, i + 1);
        final monthTasks = appState.taskBox.values
            .where(
              (t) => t.date.year == focusDate.year && t.date.month == i + 1,
            )
            .toList();
        final done = monthTasks.where((t) => t.status == 'completed').length;
        final total = monthTasks.length;
        final ratio = total == 0 ? 0.0 : done / total;

        return GestureDetector(
          onTap: () => onMonthTap(monthDate),
          child:
              Container(
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? primary.withValues(alpha: 0.12)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCurrentMonth
                            ? primary.withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM').format(monthDate).toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isCurrentMonth
                                ? primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (total > 0) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: primary.withValues(alpha: 0.12),
                              color: primary,
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$done/$total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ] else ...[
                          Text(
                            '$daysInMonth days',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 50 * i))
                  .fadeIn()
                  .scaleXY(begin: 0.95),
        );
      },
    );
  }
}
