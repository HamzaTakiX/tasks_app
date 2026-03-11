import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_state.dart';
import '../models/category_model.dart';
import '../models/task_model.dart';
import 'home_screen.dart' show TaskCard;
import 'create_task_screen.dart';

class CategoryTasksScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryTasksScreen({super.key, required this.category});

  @override
  State<CategoryTasksScreen> createState() => _CategoryTasksScreenState();
}

class _CategoryTasksScreenState extends State<CategoryTasksScreen> {
  final TextEditingController _newSubTypeController = TextEditingController();

  @override
  void dispose() {
    _newSubTypeController.dispose();
    super.dispose();
  }

  void _showAddSubTypeModal(BuildContext context, AppState appState) {
    _newSubTypeController.clear();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => DefaultTextStyle(
        // Reset the underline decoration Cupertino adds inside popups
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(decoration: TextDecoration.none),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New Task Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.category.colorValue),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create a group inside ${widget.category.title}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _newSubTypeController,
                autofocus: true,
                placeholder: 'e.g. Hair Care, Skincare, Workout...',
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              // Button styled with category color
              GestureDetector(
                onTap: () {
                  final name = _newSubTypeController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => CreateTaskScreen(
                        initialCategory: widget.category.title,
                        initialSubType: name,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Color(widget.category.colorValue),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Create',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final catColor = Color(widget.category.colorValue);

    // All tasks in this category
    final categoryTasks =
        appState.taskBox.values
            .where((t) => t.type == widget.category.title)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    // Get distinct sub-types, put '' (General/no type) last
    final subTypes = categoryTasks.map((t) => t.subType).toSet().toList();
    subTypes.sort((a, b) => a.isEmpty ? 1 : (b.isEmpty ? -1 : a.compareTo(b)));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconData(
                widget.category.iconCodePoint,
                fontFamily: 'CupertinoIcons',
                fontPackage: 'cupertino_icons',
              ),
              color: catColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(widget.category.title),
          ],
        ),
      ),
      body: SafeArea(
        child: categoryTasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconData(
                        widget.category.iconCodePoint,
                        fontFamily: 'CupertinoIcons',
                        fontPackage: 'cupertino_icons',
                      ),
                      size: 64,
                      color: catColor.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tasks yet in ${widget.category.title}.\nTap + to add a Task Type!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subTypes.length,
                itemBuilder: (context, sectionIndex) {
                  final subType = subTypes[sectionIndex];
                  final tasksInSection = categoryTasks
                      .where((t) => t.subType == subType)
                      .toList();
                  final sectionLabel = subType.isEmpty ? 'General' : subType;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: catColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              sectionLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${tasksInSection.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Quick add task to THIS sub-type
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => CreateTaskScreen(
                                      initialCategory: widget.category.title,
                                      initialSubType: subType,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.add,
                                  size: 16,
                                  color: catColor,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(
                          delay: Duration(milliseconds: 40 * sectionIndex),
                        ),
                        const SizedBox(height: 12),
                        // Tasks inside section
                        ...tasksInSection.asMap().entries.map((entry) {
                          final task = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Dismissible(
                              key: Key(task.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.destructiveRed,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  CupertinoIcons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) {
                                appState.deleteTask(task);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task deleted'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: TaskCard(task: task)
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(
                                      milliseconds: 30 * entry.key,
                                    ),
                                  )
                                  .slideX(begin: 0.05),
                            ),
                          );
                        }),

                        const Divider(height: 24),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubTypeModal(context, appState),
        backgroundColor: catColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(CupertinoIcons.folder_badge_plus),
        label: const Text('New Type'),
      ),
    );
  }
}

// ignore_for_file: unused_import
// ignore: unused_element
TaskModel _unusedRef = TaskModel(
  id: '',
  title: '',
  type: '',
  date: DateTime.now(),
);
