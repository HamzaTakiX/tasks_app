import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../widgets/week_calendar.dart';
import '../widgets/side_menu_drawer.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import 'create_task_screen.dart';

import '../widgets/task_board_view.dart';
import '../widgets/category_day_view.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBoard = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isInitialized) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }

    final currentDateTitle = _getDateTitle(appState.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusDay'),
        actions: [
          // List / Board view toggle
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CupertinoSlidingSegmentedControl<bool>(
              groupValue: _showBoard,
              children: const {
                false: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(CupertinoIcons.list_bullet, size: 16),
                ),
                true: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(CupertinoIcons.square_grid_2x2, size: 16),
                ),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _showBoard = val);
              },
            ),
          ),
        ],
      ),
      drawer: const SideMenuDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Header: date
            if (!_showBoard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  currentDateTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),

            if (!_showBoard) ...[
              const SizedBox(height: 12),
              // "This Week" header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'This Week',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const CalendarScreen(
                            initialMode: CalendarViewMode.week,
                          ),
                        ),
                      ),
                      child: Text(
                        'See All →',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const WeekCalendar().animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
            ],

            if (_showBoard)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Text(
                  'Board',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

            // Content: list (category cards) or board
            Expanded(
              child: _showBoard
                  ? const TaskBoardView()
                  : const CategoryDayView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final filter = appState.selectedFilter;
          final preCategory = filter == 'All' ? null : filter;
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => CreateTaskScreen(initialCategory: preCategory),
            ),
          );
        },
        backgroundColor: const Color(0xFF7A75E4),
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(CupertinoIcons.add, size: 28),
      ),
    );
  }

  String _getDateTitle(DateTime date) {
    if (DateUtils.isSameDay(date, DateTime.now())) return 'Today';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get color dynamically from category model
    final catModel = appState.categoryBox.values.firstWhere(
      (c) => c.title == task.type,
      orElse: () => CategoryModel(
        id: '',
        title: task.type,
        colorValue: 0xFF6C63FF, // Default purple
        iconCodePoint: CupertinoIcons.folder.codePoint,
      ),
    );
    final categoryColor = Color(catModel.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Trigger the animation and logic for tap
          appState.toggleTaskCompleted(task);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Circular Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted ? categoryColor : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted
                        ? categoryColor
                        : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                          .animate()
                          .scale(duration: 250.ms, curve: Curves.easeOutBack)
                          .fadeIn()
                    : null,
              ),
              const SizedBox(width: 16),

              // Task Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: task.isCompleted
                                      ? Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.4)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                            child: Text(task.title),
                          ),
                        ),
                        if (task.priority == 'High')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.destructiveRed.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'HIGH',
                              style: TextStyle(
                                fontSize: 10,
                                color: CupertinoColors.destructiveRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (task.iconCodePoint != null) ...[
                          Icon(
                            IconData(
                              task.iconCodePoint!,
                              fontFamily: 'CupertinoIcons',
                              fontPackage: 'cupertino_icons',
                            ),
                            size: 14,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          task.type,
                          style: TextStyle(
                            fontSize: 12,
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (task.time != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            CupertinoIcons.clock,
                            size: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.time!.hour.toString().padLeft(2, '0')}:${task.time!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (task.repetition != 'None') ...[
                          const SizedBox(width: 12),
                          Icon(
                            CupertinoIcons.arrow_2_squarepath,
                            size: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.repetition,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
