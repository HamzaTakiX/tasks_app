import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../models/journal_model.dart';
import '../models/task_model.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _openEditor({JournalModel? existingEntry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _JournalEditorSheet(dateKey: _dateKey, existingEntry: existingEntry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter journals for selected date
    final dayJournals =
        appState.journalBox.values
            .where((j) => j.dateString == _dateKey)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E10)
          : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Journal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isToday)
            IconButton(
              icon: const Icon(CupertinoIcons.today, size: 22),
              tooltip: 'Go to Today',
              onPressed: () => setState(() => _selectedDate = DateTime.now()),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text(
          'Add Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ).animate().fadeIn().scale(),
      body: Column(
        children: [
          // Date Navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.chevron_left_circle_fill),
                  color: isDark ? Colors.white30 : Colors.black26,
                  iconSize: 28,
                  onPressed: () => _changeDate(-1),
                ),
                Column(
                  children: [
                    Text(
                      isToday
                          ? 'Today'
                          : DateFormat('EEEE').format(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDate),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.chevron_right_circle_fill),
                  color: isDark ? Colors.white30 : Colors.black26,
                  iconSize: 28,
                  onPressed: isToday ? null : () => _changeDate(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Timeline / Entries
          Expanded(
            child: dayJournals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.book,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No entries for today',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: dayJournals.length,
                    itemBuilder: (context, i) {
                      final entry = dayJournals[i];
                      return _JournalEntryCard(
                            entry: entry,
                            onTap: () => _openEditor(existingEntry: entry),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete Entry?'),
                                  content: const Text('This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: CupertinoColors.destructiveRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                appState.deleteJournal(entry);
                              }
                            },
                          )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 50 * i))
                          .slideY(begin: 0.05, duration: 300.ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final JournalModel entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _JournalEntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.onSurface;
    final appState = context.read<AppState>();

    // Find category details
    final cat = appState.categoryBox.values
        .where((c) => c.title == entry.category)
        .firstOrNull;
    final catColor = cat != null
        ? Color(cat.colorValue)
        : Theme.of(context).colorScheme.primary;

    // Find linked tasks
    final linkedTasks = entry.linkedTaskIds
        .map((id) => appState.taskBox.get(id))
        .whereType<TaskModel>()
        .toList();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: surface.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category, Mood, Time
            Row(
              children: [
                if (entry.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: catColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (entry.mood.isNotEmpty) ...[
                  if (entry.category.isNotEmpty) const SizedBox(width: 8),
                  Text(entry.mood, style: const TextStyle(fontSize: 14)),
                ],
                const Spacer(),
                Text(
                  DateFormat('HH:mm').format(entry.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: surface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            if (entry.title.isNotEmpty) ...[
              Text(
                entry.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Content preview (clamped)
            if (entry.content.isNotEmpty)
              Text(
                entry.content,
                maxLines: entry.imagePaths.isNotEmpty ? 3 : 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: surface.withValues(alpha: 0.8),
                ),
              ),

            // Images
            if (entry.imagePaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: entry.imagePaths
                    .take(2)
                    .map(
                      (path) => Expanded(
                        child: Container(
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: surface.withValues(alpha: 0.05),
                            image: DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(path) as ImageProvider
                                  : FileImage(File(path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // Linked Tasks
            if (linkedTasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: linkedTasks
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: surface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              t.isCompleted
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              size: 12,
                              color: t.isCompleted
                                  ? const Color(0xFF30D158)
                                  : surface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 11,
                                color: surface.withValues(alpha: 0.7),
                                decoration: t.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Entry Editor Sheet ────────────────────────────────────────────────────────

class _JournalEditorSheet extends StatefulWidget {
  final String dateKey;
  final JournalModel? existingEntry;

  const _JournalEditorSheet({required this.dateKey, this.existingEntry});

  @override
  State<_JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends State<_JournalEditorSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  String _category = '';
  String _mood = '';
  List<String> _linkedTaskIds = [];
  List<String> _imagePaths = [];

  static const _moods = ['😊', '😐', '😢', '😤', '🤩', '😴'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingEntry?.title ?? '');
    _contentCtrl = TextEditingController(
      text: widget.existingEntry?.content ?? '',
    );
    _category = widget.existingEntry?.category ?? '';
    _mood = widget.existingEntry?.mood ?? '';
    _linkedTaskIds = List.from(widget.existingEntry?.linkedTaskIds ?? []);
    _imagePaths = List.from(widget.existingEntry?.imagePaths ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final appState = context.read<AppState>();

    if (_contentCtrl.text.trim().isEmpty && _imagePaths.isEmpty) {
      Navigator.pop(context); // Don't save empty entries
      return;
    }

    if (widget.existingEntry != null) {
      widget.existingEntry!.title = _titleCtrl.text.trim();
      widget.existingEntry!.content = _contentCtrl.text.trim();
      widget.existingEntry!.category = _category;
      widget.existingEntry!.mood = _mood;
      widget.existingEntry!.linkedTaskIds = _linkedTaskIds;
      widget.existingEntry!.imagePaths = _imagePaths;
      appState.updateJournal(widget.existingEntry!);
    } else {
      final entry = JournalModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateString: widget.dateKey,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        category: _category,
        mood: _mood,
        linkedTaskIds: _linkedTaskIds,
        imagePaths: _imagePaths,
      );
      appState.addJournal(entry);
    }

    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    if (_imagePaths.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 2 images allowed.')),
      );
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _imagePaths.add(file.path);
      });
    }
  }

  void _openTaskLinker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => _TaskLinkPicker(
        dateKey: widget.dateKey,
        initialSelectedIds: _linkedTaskIds,
        onSave: (ids) {
          setState(() => _linkedTaskIds = ids);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final appCategories = context.read<AppState>().categoryBox.values.toList();
    final appSate = context.watch<AppState>();

    // For rendering linked tasks
    final linkedTasks = _linkedTaskIds
        .map((id) => appSate.taskBox.get(id))
        .whereType<TaskModel>()
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: surface.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  widget.existingEntry == null ? 'New Entry' : 'Edit Entry',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: appCategories.map((c) {
                        final isSelected = _category == c.title;
                        final cColor = Color(c.colorValue);
                        return GestureDetector(
                          onTap: () => setState(
                            () => _category = isSelected ? '' : c.title,
                          ),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cColor
                                  : cColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              c.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : cColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Entry Title (optional)',
                      hintStyle: TextStyle(
                        color: surface.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  // Content
                  TextField(
                    controller: _contentCtrl,
                    maxLines: null,
                    minLines: 5,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: surface.withValues(alpha: 0.8),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'What happened? Write your thoughts, add emojis...',
                      hintStyle: TextStyle(
                        color: surface.withValues(alpha: 0.3),
                        fontStyle: FontStyle.italic,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Display Images
                  if (_imagePaths.isNotEmpty) ...[
                    Row(
                      children: _imagePaths
                          .asMap()
                          .entries
                          .map(
                            (e) => Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  margin: const EdgeInsets.only(
                                    right: 12,
                                    bottom: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(e.value)
                                                as ImageProvider
                                          : FileImage(File(e.value)),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _imagePaths.removeAt(e.key),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.clear,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // Display Linked Tasks
                  if (linkedTasks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Linked Tasks:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: surface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: linkedTasks
                          .map(
                            (t) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: surface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    t.isCompleted
                                        ? CupertinoIcons
                                              .check_mark_circled_solid
                                        : CupertinoIcons.circle,
                                    color: primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      style: TextStyle(
                                        decoration: t.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _linkedTaskIds.remove(t.id),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.xmark,
                                      size: 16,
                                      color: surface.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom toolbar (actions + mood)
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              border: Border(
                top: BorderSide(color: surface.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                // Attachments
                IconButton(
                  icon: const Icon(CupertinoIcons.camera_fill),
                  color: primary,
                  tooltip: 'Attach Image',
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.link),
                  color: primary,
                  tooltip: 'Link Tasks',
                  onPressed: _openTaskLinker,
                ),

                // Divider
                Container(
                  width: 1,
                  height: 24,
                  color: surface.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // Mood picker
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _moods.map((m) {
                        final isSelected = _mood == m;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _mood = isSelected ? '' : m),
                          child: AnimatedContainer(
                            duration: 150.ms,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                            ),
                            child: Text(
                              m,
                              style: TextStyle(fontSize: isSelected ? 24 : 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Task Link Picker Sheet ───────────────────────────────────────────────────

class _TaskLinkPicker extends StatefulWidget {
  final String dateKey;
  final List<String> initialSelectedIds;
  final ValueChanged<List<String>> onSave;

  const _TaskLinkPicker({
    required this.dateKey,
    required this.initialSelectedIds,
    required this.onSave,
  });

  @override
  State<_TaskLinkPicker> createState() => _TaskLinkPickerState();
}

class _TaskLinkPickerState extends State<_TaskLinkPicker> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Find tasks for this day. Since we have a dateKey, we parse it back to a DateTime
    // to use the robust tasksForDate logic.
    final targetDate = DateFormat('yyyy-MM-dd').parse(widget.dateKey);
    final dayTasks = appState.tasksForDate(targetDate);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const Text(
                'Link Tasks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () {
                  widget.onSave(_selectedIds);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(),
          if (dayTasks.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No tasks created on this day to link.'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: dayTasks.length,
                itemBuilder: (c, i) {
                  final t = dayTasks[i];
                  final isSelected = _selectedIds.contains(t.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.add(t.id);
                        } else {
                          _selectedIds.remove(t.id);
                        }
                      });
                    },
                    title: Text(t.title),
                    subtitle: Text(
                      t.type,
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      t.isCompleted
                          ? CupertinoIcons.check_mark_circled_solid
                          : CupertinoIcons.circle,
                      color: t.isCompleted
                          ? const Color(0xFF30D158)
                          : Colors.grey,
                    ),
                    activeColor: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
