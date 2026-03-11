import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/task_model.dart';

class CreateTaskScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialSubType;
  final TaskModel? existingTask;

  const CreateTaskScreen({
    super.key,
    this.initialCategory,
    this.initialSubType,
    this.existingTask,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();

  // Advanced fields
  String _selectedType = 'Work';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedTime;
  String _priority = 'Normal';
  String _repetition = 'None';
  int? _selectedIconCode;
  String _subType = ''; // e.g. "Hair Care" inside "Health"

  // Dynamic categories loaded from Hive — see build() where we use context.read<AppState>()
  final List<int> _iconOptions = [
    CupertinoIcons.heart_fill.codePoint,
    CupertinoIcons.briefcase_fill.codePoint,
    CupertinoIcons.book_fill.codePoint,
    CupertinoIcons.person_fill.codePoint,
    CupertinoIcons.cart_fill.codePoint,
    CupertinoIcons.home.codePoint,
    CupertinoIcons.airplane.codePoint,
    CupertinoIcons.money_dollar.codePoint,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _noteController.text = task.note;
      _selectedType = task.type;
      _selectedDate = task.date;
      _selectedTime = task.time;
      _priority = task.priority;
      _repetition = task.repetition;
      _selectedIconCode = task.iconCodePoint;
      _subType = task.subType;
    } else {
      _subType = widget.initialSubType ?? '';
      if (widget.initialCategory != null) {
        _selectedType = widget.initialCategory!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) return;
    final appState = context.read<AppState>();
    // _selectedType is already the exact category title from Hive
    final finalType = _selectedType.isEmpty ? 'General' : _selectedType;

    if (widget.existingTask != null) {
      appState.updateAdvancedTask(
        existingTask: widget.existingTask!,
        title: _titleController.text.trim(),
        type: finalType,
        date: _selectedDate,
        time: _selectedTime,
        iconCodePoint: _selectedIconCode,
        priority: _priority,
        note: _noteController.text.trim(),
        repetition: _repetition,
        subType: _subType,
      );
    } else {
      appState.addAdvancedTask(
        title: _titleController.text.trim(),
        type: finalType,
        date: _selectedDate,
        time: _selectedTime,
        iconCodePoint: _selectedIconCode,
        priority: _priority,
        note: _noteController.text.trim(),
        repetition: _repetition,
        subType: _subType,
      );
    }

    Navigator.pop(context);
  }

  void _pickTime() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedTime ?? DateTime.now(),
                onDateTimeChanged: (val) {
                  setState(() => _selectedTime = val);
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                onDateTimeChanged: (val) {
                  setState(() => _selectedDate = val);
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask != null ? 'Edit Task' : 'Create Task'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: _titleController.text.trim().isEmpty ? null : _saveTask,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              CupertinoTextField(
                controller: _titleController,
                placeholder: 'Task Title',
                padding: const EdgeInsets.all(16),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Category/Type — driven from Hive
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final appState = context.watch<AppState>();
                  final categories = appState.categoryBox.values.toList();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = cat.title == _selectedType;
                      final catColor = Color(cat.colorValue);
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedType = cat.title;
                          _subType = ''; // reset sub-type when category changes
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? catColor.withValues(alpha: 0.15)
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? catColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                IconData(
                                  cat.iconCodePoint,
                                  fontFamily: 'CupertinoIcons',
                                  fontPackage: 'cupertino_icons',
                                ),
                                size: 14,
                                color: isSelected
                                    ? catColor
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.title,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? catColor
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Sub-Type — shows existing sub-types for the selected category
              if (_selectedType.isNotEmpty) ...[
                const Text(
                  'Task Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final appState = context.watch<AppState>();
                    // Get distinct sub-types already used in this category
                    final existingSubTypes = appState.taskBox.values
                        .where(
                          (t) =>
                              t.type == _selectedType && t.subType.isNotEmpty,
                        )
                        .map((t) => t.subType)
                        .toSet()
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (existingSubTypes.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // "None" chip
                              GestureDetector(
                                onTap: () => setState(() => _subType = ''),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _subType.isEmpty
                                        ? Theme.of(context).colorScheme.primary
                                              .withValues(alpha: 0.15)
                                        : Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _subType.isEmpty
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    'General',
                                    style: TextStyle(
                                      fontWeight: _subType.isEmpty
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _subType.isEmpty
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              ...existingSubTypes.map((st) {
                                final isSelected = st == _subType;
                                return GestureDetector(
                                  onTap: () => setState(() => _subType = st),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.15)
                                          : Theme.of(context).cardTheme.color,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      st,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        const SizedBox(height: 10),
                        // Free-text field to type a new sub-type
                        CupertinoTextField(
                          controller: _customTypeController,
                          placeholder:
                              'Or type a new Task Type (e.g. Hair Care)...',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (val) =>
                              setState(() => _subType = val.trim()),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: _buildSettingTile(
                      context,
                      icon: CupertinoIcons.calendar,
                      title: 'Date',
                      value:
                          '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSettingTile(
                      context,
                      icon: CupertinoIcons.clock,
                      title: 'Time',
                      value: _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'None',
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Priority
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _priority,
                  children: const {
                    'Low': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Low'),
                    ),
                    'Normal': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Normal'),
                    ),
                    'High': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('High'),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Repetition
              const Text(
                'Repetition',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['None', 'Daily', 'Weekdays', 'Weekly'].map((rep) {
                    final isSelected = rep == _repetition;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(rep),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _repetition = rep),
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        backgroundColor: Theme.of(context).cardTheme.color,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Optional Icon
              Row(
                children: [
                  const Text(
                    'Icon',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Spacer(),
                  if (_selectedIconCode != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 14),
                      ),
                      onPressed: () => setState(() => _selectedIconCode = null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _iconOptions.map((code) {
                  final isSelected = _selectedIconCode == code;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconCode = code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
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
              const SizedBox(height: 24),

              // Note
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _noteController,
                placeholder: 'Add description or sub-tasks...',
                maxLines: 4,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
