import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/category_model.dart';
import '../models/task_model.dart';
import '../screens/task_timer_sheet.dart';
import '../screens/task_detail_sheet.dart';

/// Full home category list with weekly summary bar + category cards.
/// Replaces the flat task list in list-mode.
class CategoryDayView extends StatelessWidget {
  const CategoryDayView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selectedDate = appState.selectedDate;
    final categories = appState.categoryBox.values.toList();
    final (weekDone, weekTotal) = appState.weekProgress();

    // Only show categories that have tasks on the selected date
    final activeCats = categories.where((cat) {
      final (_, total) = appState.categoryDayProgress(cat.title, selectedDate);
      return total > 0;
    }).toList();

    return CustomScrollView(
      slivers: [
        // ── Weekly progress banner ──────────────────────────────────
        SliverToBoxAdapter(
          child: _WeekBanner(
            done: weekDone,
            total: weekTotal,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Category cards ──────────────────────────────────────────
        activeCats.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.calendar_badge_plus,
                        size: 56,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No tasks for this day',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: activeCats.length,
                  itemBuilder: (context, i) {
                    final cat = activeCats[i];
                    return _CategoryCard(category: cat, date: selectedDate)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 60 * i))
                        .slideY(begin: 0.08);
                  },
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ─── Weekly progress banner ─────────────────────────────────────────────────
class _WeekBanner extends StatelessWidget {
  final int done;
  final int total;
  const _WeekBanner({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekLabel =
        '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d').format(sunday)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.calendar,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'This Week',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$done / $total tasks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            weekLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'No tasks this week yet'
                : '${(ratio * 100).toStringAsFixed(0)}% complete',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category card with daily progress bar ──────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final DateTime date;
  const _CategoryCard({required this.category, required this.date});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cat = widget.category;
    final catColor = Color(cat.colorValue);
    final (done, total) = appState.categoryDayProgress(cat.title, widget.date);
    final ratio = total == 0 ? 0.0 : done / total;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get tasks for this category on this date
    final catTasks = appState
        .tasksForDate(widget.date)
        .where((t) => t.type == cat.title)
        .toList();

    // Group into sub-types
    final subTypes = catTasks.map((t) => t.subType).toSet().toList()
      ..sort((a, b) => a.isEmpty ? 1 : (b.isEmpty ? -1 : a.compareTo(b)));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF232536) : const Color(0xFFE2E4ED),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Column(
            children: [
              // Card header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        IconData(
                          cat.iconCodePoint,
                          fontFamily: 'CupertinoIcons',
                          fontPackage: 'cupertino_icons',
                        ),
                        color: catColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name + progress text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$done / $total tasks done',
                            style: TextStyle(
                              fontSize: 12,
                              color: catColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expand arrow
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, val, _) => LinearProgressIndicator(
                          value: val,
                          minHeight: 8,
                          backgroundColor: catColor.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(catColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(ratio * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded: sub-type cards with tasks
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _ExpandedContent(
                  subTypes: subTypes,
                  catTasks: catTasks,
                  catColor: catColor,
                  isDark: isDark,
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expanded content: sub-type groups → tasks ──────────────────────────────
class _ExpandedContent extends StatelessWidget {
  final List<String> subTypes;
  final List<TaskModel> catTasks;
  final Color catColor;
  final bool isDark;

  const _ExpandedContent({
    required this.subTypes,
    required this.catTasks,
    required this.catColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...subTypes.map((st) {
            final tasks = catTasks.where((t) => t.subType == st).toList();
            final label = st.isEmpty ? 'General' : st;
            final stDone = tasks.where((t) => t.status == 'completed').length;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sub-type header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: catColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: catColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$stDone/${tasks.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: catColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tasks inside sub-type
                  ...tasks.map((task) {
                    return _MiniTaskTile(
                      task: task,
                      catColor: catColor,
                      appState: appState,
                    );
                  }),

                  const SizedBox(height: 6),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Mini task tile inside expanded category ────────────────────────────────
class _MiniTaskTile extends StatelessWidget {
  final TaskModel task;
  final Color catColor;
  final AppState appState;

  const _MiniTaskTile({
    required this.task,
    required this.catColor,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == 'completed';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showTaskDetailSheet(context, task),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Row(
          children: [
            // ○ Checkbox — only this toggles done
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => appState.toggleTaskCompleted(task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? catColor : Colors.transparent,
                  border: Border.all(
                    color: isDone ? catColor : catColor.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(
                        CupertinoIcons.checkmark,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),

            // Title
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: isDone ? 0.4 : 1),
                ),
              ),
            ),

            // Priority dot
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.priority == 'High'
                    ? const Color(0xFFFF453A)
                    : task.priority == 'Low'
                    ? const Color(0xFF30D158)
                    : const Color(0xFFFF9F0A),
              ),
            ),

            // ▶ Timer button
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showTaskTimerSheet(context, task),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.timer, size: 14, color: catColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
