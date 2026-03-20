import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_state.dart';
import '../models/category_model.dart';
import '../widgets/side_menu_drawer.dart';
import 'category_tasks_screen.dart';

class TaskManagementScreen extends StatelessWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final categories = appState.categoryBox.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      drawer: const SideMenuDrawer(),
      body: SafeArea(
        child: categories.isEmpty
            ? Center(
                child: Text(
                  'No categories yet. Tap + to create one!',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final taskCount = appState.getTaskCountForCategory(
                    category.title,
                  );
                  final catColor = Color(category.colorValue);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) =>
                                CategoryTasksScreen(category: category),
                          ),
                        );
                      },
                      onLongPress: () {
                        _showEditCategoryModal(context, appState, category);
                      },
                      child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).shadowColor.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconData(
                                      category.iconCodePoint,
                                      fontFamily: 'CupertinoIcons',
                                      fontPackage: 'cupertino_icons',
                                    ),
                                    color: catColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.title,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$taskCount Task${taskCount == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit icon
                                IconButton(
                                  icon: Icon(
                                    CupertinoIcons.pencil_circle_fill,
                                    color: catColor.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () => _showEditCategoryModal(
                                    context,
                                    appState,
                                    category,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 50 * index))
                          .slideX(begin: 0.1),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateCategoryModal(context, appState);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(CupertinoIcons.folder_badge_plus),
      ),
    );
  }

  // ── Shared icon & colour data ─────────────────────────────────────────────

  static const List<int> _iconOptions = [
    // Productivity / Work
    0xF295, // briefcase_fill
    0xF12A, // pencil
    0xF32B, // book_fill
    0xF334, // doc_fill
    0xF502, // desktopcomputer
    0xF448, // chart_bar_square_fill
    // Health / Fitness
    0xF37B, // heart_fill
    0xF503, // sportscourt_fill
    0xF344, // drop_fill
    0xF310, // bandage_fill
    0xF3AD, // leaf_arrow_circlepath
    0xF3FD, // flame_fill
    // Daily Life
    0xF46D, // house_fill
    0xF408, // music_note
    0xF40C, // moon_fill
    0xF305, // bolt_fill
    0xF46E, // cart_fill
    0xF4B4, // star_fill
    // Finance / Social
    0xF342, // creditcard_fill
    0xF46F, // person_2_fill
    0xF458, // globe
    0xF3B2, // car_fill
    // Creative / Misc
    0xF348, // paintpalette_fill
    0xF3FA, // camera_fill
    0xF41B, // gamecontroller_fill
    0xF3AB, // crown_fill
    0xF36C, // folder_fill
    0xF36D, // folder_badge_plus
    0xF41C, // bell_fill
    0xF4E6, // lock_fill
  ];

  static const List<int> _colorOptions = [
    0xFF6C63FF, // Modern Purple
    0xFF3478F6, // iOS Blue
    0xFF00E5FF, // Vibrant Cyan
    0xFF30D158, // Green
    0xFFFF6B6B, // Salmon Red
    0xFFFF9F0A, // Orange
    0xFFFFB347, // Peach Orange
    0xFF9B59B6, // Deep Purple
    0xFF00C7BE, // Teal
    0xFFFF375F, // Pink
    0xFF64D2FF, // Sky Blue
    0xFF34C759, // Lime Green
    0xFFFFCC00, // Yellow
    0xFFFF453A, // Red
    0xFF8E8E93, // Grey
  ];

  void _showCreateCategoryModal(BuildContext context, AppState appState) {
    _showCategorySheet(context, appState, null);
  }

  void _showEditCategoryModal(
    BuildContext context,
    AppState appState,
    CategoryModel existing,
  ) {
    _showCategorySheet(context, appState, existing);
  }

  void _showCategorySheet(
    BuildContext context,
    AppState appState,
    CategoryModel? existing,
  ) {
    String title = existing?.title ?? '';
    int selectedColor =
        existing?.colorValue ?? _colorOptions[0];
    int selectedIcon =
        existing?.iconCodePoint ?? _iconOptions[0];

    final titleController = TextEditingController(text: title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pill handle
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
                      existing == null ? 'New Category' : 'Edit Category',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    CupertinoTextField(
                      controller: titleController,
                      autofocus: true,
                      placeholder: 'Category Name...',
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onChanged: (val) => title = val,
                    ),
                    const SizedBox(height: 24),

                    // ── Colour selection ─────────────────────────────────
                    const Text(
                      'Color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.map((cValue) {
                        final isSelected = cValue == selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = cValue),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(cValue),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: Colors.transparent,
                                      width: 3,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Color(
                                          cValue,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ── Icon selection ───────────────────────────────────
                    const Text(
                      'Icon',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _iconOptions.map((code) {
                        final isSelected = code == selectedIcon;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = code),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(selectedColor)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Color(
                                          selectedColor,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              IconData(
                                code,
                                fontFamily: 'CupertinoIcons',
                                fontPackage: 'cupertino_icons',
                              ),
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                              size: 22,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // ── Save button ───────────────────────────────────────
                    CupertinoButton(
                      color: Color(selectedColor),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () {
                        final trimmed = titleController.text.trim();
                        if (trimmed.isEmpty) return;
                        if (existing == null) {
                          // Create new
                          final newCat = CategoryModel(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            title: trimmed,
                            colorValue: selectedColor,
                            iconCodePoint: selectedIcon,
                          );
                          appState.categoryBox.put(newCat.id, newCat);
                        } else {
                          // Update existing
                          existing.title = trimmed;
                          existing.colorValue = selectedColor;
                          existing.iconCodePoint = selectedIcon;
                          existing.save();
                        }
                        appState.refresh(); // Fix: was missing before
                        Navigator.pop(context);
                      },
                      child: Text(
                        existing == null ? 'Save Category' : 'Update Category',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ── Delete button (edit mode only) ────────────────────
                    if (existing != null) ...[
                      const SizedBox(height: 12),
                      CupertinoButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(context, appState, existing);
                        },
                        child: const Text(
                          'Delete Category',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppState appState,
    CategoryModel category,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Delete "${category.title}"?'),
        content: const Text(
          'This will only remove the category. Tasks inside it will remain.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              category.delete();
              appState.refresh();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
