import 'dart:convert';
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
  List<TimeOfDay> _selectedTimes = [];
  int _reminderOffset = 5;
  String _priority = 'Normal';
  String _repetition = 'None';
  List<int> _customDays = []; // 1=Mon, ..., 7=Sun
  int? _selectedIconCode;
  String _subType = ''; // e.g. "Hair Care" inside "Health"

  // Dynamic categories loaded from Hive
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
      _priority = task.priority;
      _selectedIconCode = task.iconCodePoint;
      _subType = task.subType;
      
      _reminderOffset = task.reminderOffset ?? 5;
      
      if (task.taskTimesJson != null && task.taskTimesJson!.isNotEmpty) {
        try {
          final List<dynamic> timesList = jsonDecode(task.taskTimesJson!);
          _selectedTimes = timesList.map((t) {
            final parts = t.toString().split(':');
            return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }).toList();
        } catch (_) {}
      } else if (task.time != null) {
        _selectedTimes.add(TimeOfDay(hour: task.time!.hour, minute: task.time!.minute));
      }

      if (task.repeatDaysJson == 'every_other_day') {
        _repetition = 'Nhar Ah Nhar La';
      } else if (task.repeatDaysJson != null && task.repeatDaysJson!.isNotEmpty) {
        try {
          final List<dynamic> daysList = jsonDecode(task.repeatDaysJson!);
          _customDays = daysList.cast<int>();
          _repetition = 'Custom Days';
        } catch (_) {}
      } else {
        _repetition = task.repetition;
      }
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
    final finalType = _selectedType.isEmpty ? 'General' : _selectedType;

    String? timesJson;
    if (_selectedTimes.isNotEmpty) {
      timesJson = jsonEncode(_selectedTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList());
    }

    String? daysJson;
    String repToSave = _repetition;
    if (_repetition == 'Nhar Ah Nhar La') {
      daysJson = 'every_other_day';
      repToSave = 'Custom';
    } else if (_repetition == 'Custom Days') {
      daysJson = jsonEncode(_customDays);
      repToSave = 'Custom';
    }

    DateTime? firstTime;
    if (_selectedTimes.isNotEmpty) {
      firstTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTimes.first.hour,
        _selectedTimes.first.minute,
      );
    }

    if (widget.existingTask != null) {
      appState.updateAdvancedTask(
        existingTask: widget.existingTask!,
        title: _titleController.text.trim(),
        type: finalType,
        date: _selectedDate,
        time: firstTime,
        iconCodePoint: _selectedIconCode,
        priority: _priority,
        note: _noteController.text.trim(),
        repetition: repToSave,
        subType: _subType,
        repeatDaysJson: daysJson,
        taskTimesJson: timesJson,
        reminderOffset: _reminderOffset,
      );
    } else {
      appState.addAdvancedTask(
        title: _titleController.text.trim(),
        type: finalType,
        date: _selectedDate,
        time: firstTime,
        iconCodePoint: _selectedIconCode,
        priority: _priority,
        note: _noteController.text.trim(),
        repetition: repToSave,
        subType: _subType,
        repeatDaysJson: daysJson,
        taskTimesJson: timesJson,
        reminderOffset: _reminderOffset,
      );
    }

    Navigator.pop(context);
  }

  void _pickTime() {
    TimeOfDay tempTime = TimeOfDay.now();
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
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (val) {
                  tempTime = TimeOfDay.fromDateTime(val);
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Add Time'),
              onPressed: () {
                setState(() {
                  _selectedTimes.add(tempTime);
                });
                Navigator.pop(context);
              },
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
  
  void _pickCustomDays() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return Container(
            height: 350,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                const Text('Select Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final dayNum = index + 1;
                      final isSelected = _customDays.contains(dayNum);
                      return CupertinoListTile(
                        title: Text(days[index]),
                        trailing: isSelected ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue) : null,
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              _customDays.remove(dayNum);
                            } else {
                              _customDays.add(dayNum);
                            }
                          });
                          setState((){});
                        },
                      );
                    },
                  ),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
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

              // Repetition First (to hide Date if Daily)
              const Text(
                'Repetition',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['None', 'Daily', 'Nhar Ah Nhar La', 'Custom Days'].map((rep) {
                    final isSelected = rep == _repetition;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(rep),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _repetition = rep);
                          if (rep == 'Custom Days') {
                            _pickCustomDays();
                          }
                        },
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

              // Date & Times
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSettingTile(
                      context,
                      icon: CupertinoIcons.calendar,
                      title: 'Start Date',
                      value:
                          '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.clock,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Times',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _pickTime,
                                child: Icon(CupertinoIcons.add_circled, color: Theme.of(context).colorScheme.primary)
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_selectedTimes.isEmpty) 
                            const Text('No times selected', style: TextStyle(fontSize: 14))
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTimes.map((t) {
                                return Chip(
                                  label: Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedTimes.remove(t);
                                    });
                                  },
                                );
                              }).toList()
                            )
                        ],
                      ),
                    )
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reminder Offset
              const Text(
                'Reminder',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _reminderOffset,
                  children: const {
                    0: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('0 min')),
                    5: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('5 min')),
                    15: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('15 min')),
                    30: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('30 min')),
                  },
                  onValueChanged: (val) {
                    if (val != null) setState(() => _reminderOffset = val);
                  },
                ),
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
