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
                  'Loading categories...',
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
                      child:
                          Container(
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
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.2),
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

  void _showCreateCategoryModal(BuildContext context, AppState appState) {
    String title = '';
    int selectedColor = CupertinoColors.systemIndigo.color.toARGB32();
    int selectedIcon = CupertinoIcons.folder_fill.codePoint;

    final List<int> iconOptions = [
      CupertinoIcons.folder_fill.codePoint,
      CupertinoIcons.moon_fill.codePoint,
      CupertinoIcons.gamecontroller_fill.codePoint,
      CupertinoIcons.money_dollar.codePoint,
      CupertinoIcons.lightbulb_fill.codePoint,
      CupertinoIcons.music_note_2.codePoint,
    ];

    final List<int> colorOptions = [
      CupertinoColors.systemIndigo.color.toARGB32(),
      CupertinoColors.systemPink.color.toARGB32(),
      CupertinoColors.systemYellow.color.toARGB32(),
      CupertinoColors.systemTeal.color.toARGB32(),
      CupertinoColors.activeGreen.color.toARGB32(),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'New Category',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
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

                  // Color Selection
                  const Text(
                    'Color',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: colorOptions.map((cValue) {
                      final isSelected = cValue == selectedColor;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = cValue),
                        child: Container(
                          width: 40,
                          height: 40,
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
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Icon Selection
                  const Text(
                    'Icon',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: iconOptions.map((code) {
                      final isSelected = code == selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = code),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(selectedColor)
                                : Theme.of(context).cardTheme.color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconData(
                              code,
                              fontFamily: 'CupertinoIcons',
                              fontPackage: 'cupertino_icons',
                            ),
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  CupertinoButton.filled(
                    child: const Text('Save Category'),
                    onPressed: () {
                      if (title.isNotEmpty) {
                        final newCat = CategoryModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          colorValue: selectedColor,
                          iconCodePoint: selectedIcon,
                        );
                        appState.categoryBox.put(newCat.id, newCat);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
