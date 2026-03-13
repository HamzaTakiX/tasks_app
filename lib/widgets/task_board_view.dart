import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_state.dart';
import '../models/task_model.dart';

class TaskBoardView extends StatefulWidget {
  const TaskBoardView({super.key});

  @override
  State<TaskBoardView> createState() => _TaskBoardViewState();
}

class _TaskBoardViewState extends State<TaskBoardView> {
  static const _columns = [
    _Column(
      id: 'in_progress',
      label: 'In Progress',
      emoji: '🔵',
      color: Color(0xFF3478F6),
    ),
    _Column(id: 'next', label: 'Next', emoji: '🟣', color: Color(0xFF9B59B6)),
    _Column(
      id: 'completed',
      label: 'Completed',
      emoji: '🟢',
      color: Color(0xFF30D158),
    ),
    _Column(
      id: 'cancelled',
      label: 'Cancelled',
      emoji: '🔴',
      color: Color(0xFFFF453A),
    ),
  ];

  String _searchQuery = '';
  String _dateFilter = 'All Time';
  String _priorityFilter = 'All';
  String _categoryFilter = 'All';

  final List<String> _dateOptions = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
  ];
  final List<String> _priorityOptions = ['All', 'Low', 'Normal', 'High'];



  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Get distinct categories
    final categories = appState.categoryBox.values
        .map((e) => e.title)
        .toSet()
        .toList();
    final List<String> categoryOptions = ['All', ...categories];

    // Filter tasks
    final List<TaskModel> allTasks = [];
    
    // For Board view, depending on the _dateFilter, we fetch tasks differently
    // If 'Today' or 'This Week' or 'This Month', we iterate through those days to get recurring tasks.
    // If 'All Time', it's harder, but usually we just want raw tasks for 'All Time'.
    if (_dateFilter == 'Today') {
       allTasks.addAll(appState.tasksForDate(DateTime.now()));
    } else if (_dateFilter == 'This Week') {
       var now = DateTime.now();
       var startOfWeek = now.subtract(Duration(days: now.weekday - 1));
       for(int d=0; d<7; d++) {
          allTasks.addAll(appState.tasksForDate(startOfWeek.add(Duration(days: d))));
       }
    } else if (_dateFilter == 'This Month') {
       var now = DateTime.now();
       int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
       for(int d=1; d<=daysInMonth; d++) {
          allTasks.addAll(appState.tasksForDate(DateTime(now.year, now.month, d)));
       }
    } else {
       allTasks.addAll(appState.taskBox.values); // raw list for 'All Time'
    }
    
    // Deduplicate (since a recurring task might match multiple days in a week/month)
    final uniqueTasks = <String, TaskModel>{};
    for(var t in allTasks) {
       uniqueTasks[t.id] = t;
    }

    final finalTasks = uniqueTasks.values.where((t) {
      // 1. Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!t.title.toLowerCase().contains(query) &&
            !t.note.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 3. Priority filter
      if (_priorityFilter != 'All' && t.priority != _priorityFilter) {
        return false;
      }

      // 4. Category filter
      if (_categoryFilter != 'All' && t.type != _categoryFilter) {
        return false;
      }

      return true;
    }).toList();

    return Column(
      children: [
        // filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoSearchTextField(
                placeholder: 'Search tasks or notes...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              // Filter chips (scrollable)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Date
                    _buildDropdownFilter(
                      label: 'Date',
                      value: _dateFilter,
                      options: _dateOptions,
                      onChanged: (v) => setState(() => _dateFilter = v),
                    ),
                    const SizedBox(width: 8),
                    // Priority
                    _buildDropdownFilter(
                      label: 'Priority',
                      value: _priorityFilter,
                      options: _priorityOptions,
                      onChanged: (v) => setState(() => _priorityFilter = v),
                    ),
                    const SizedBox(width: 8),
                    // Category
                    _buildDropdownFilter(
                      label: 'Category',
                      value: _categoryFilter,
                      options: categoryOptions,
                      onChanged: (v) => setState(() => _categoryFilter = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: _columns.length,
            separatorBuilder: (context, _) => const SizedBox(width: 12),
            itemBuilder: (context, colIndex) {
              final col = _columns[colIndex];
              final colTasks = finalTasks.where((t) {
                final s = t.status.isEmpty ? 'in_progress' : t.status;
                return s == col.id;
              }).toList();

              return _KanbanColumn(
                column: col,
                tasks: colTasks,
                onDrop: (task) {
                  appState.updateTaskStatus(task, col.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) {
            return Container(
              height: 250,
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: Column(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(
                        initialItem: options
                            .indexOf(value)
                            .clamp(0, options.length - 1),
                      ),
                      onSelectedItemChanged: (idx) {
                        onChanged(options[idx]);
                      },
                      children: options
                          .map((e) => Center(child: Text(e)))
                          .toList(),
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data class for column meta ────────────────────────────────────────────
class _Column {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  const _Column({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

// ─── One Kanban Column ──────────────────────────────────────────────────────
class _KanbanColumn extends StatefulWidget {
  final _Column column;
  final List<TaskModel> tasks;
  final ValueChanged<TaskModel> onDrop;

  const _KanbanColumn({
    required this.column,
    required this.tasks,
    required this.onDrop,
  });

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final col = widget.column;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragOver = true);
        return details.data.status != col.id;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        widget.onDrop(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 280, // Slightly wider for a clearer view
          decoration: BoxDecoration(
            color: _isDragOver
                ? col.color.withValues(alpha: isDark ? 0.2 : 0.08)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDragOver
                  ? col.color
                  : (isDark
                        ? const Color(0xFF232536)
                        : const Color(0xFFE2E4ED)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Text(col.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        col.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: col.color,
                        ),
                      ),
                    ),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: col.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.tasks.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: col.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, indent: 16, endIndent: 16),

              // Task cards
              Expanded(
                child: widget.tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.tray,
                              color: col.color.withValues(alpha: 0.3),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isDragOver ? 'Drop here' : 'Empty',
                              style: TextStyle(
                                color: col.color.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn()
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: widget.tasks.length,
                        itemBuilder: (context, i) {
                          final task = widget.tasks[i];
                          return _DraggableTaskCard(
                                task: task,
                                columnColor: col.color,
                              )
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 80 * i),
                                duration: 400.ms,
                              )
                              .slideY(begin: 0.1, curve: Curves.easeOutCubic);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Draggable task card ────────────────────────────────────────────────────
class _DraggableTaskCard extends StatelessWidget {
  final TaskModel task;
  final Color columnColor;

  const _DraggableTaskCard({required this.task, required this.columnColor});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Draggable<TaskModel>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 196,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: columnColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            task.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _CardBody(task: task, columnColor: columnColor, isDark: isDark),
      ),
      child: GestureDetector(
        onTap: () => appState.toggleTaskCompleted(task),
        child: _CardBody(task: task, columnColor: columnColor, isDark: isDark),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final TaskModel task;
  final Color columnColor;
  final bool isDark;

  const _CardBody({
    required this.task,
    required this.columnColor,
    required this.isDark,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2135) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF232536) : const Color(0xFFF0F1F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Elegant color indicator line
          Positioned(
            left: -14, // align exactly with padding edge
            top: 2,
            bottom: 2,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: columnColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + icon
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
                      color: columnColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: task.status == 'completed'
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(
                              alpha: task.status == 'cancelled' ? 0.4 : 1,
                            ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (task.type.isNotEmpty || task.subType.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.subType.isNotEmpty
                      ? '${task.type} › ${task.subType}'
                      : task.type,
                  style: TextStyle(
                    fontSize: 11,
                    color: columnColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Row(
                children: [
                  // Priority dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _priorityColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _priorityColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 11,
                      color: _priorityColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  if (task.time != null) ...[
                    Icon(
                      CupertinoIcons.clock_fill,
                      size: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.time!.hour.toString().padLeft(2, '0')}:${task.time!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ] else ...[
                    // Drag hint
                    Icon(
                      CupertinoIcons.arrow_up_down,
                      size: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
