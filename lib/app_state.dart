import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'models/task_model.dart';
import 'models/habit_model.dart';
import 'models/journal_model.dart';
import 'models/category_model.dart';

class AppState extends ChangeNotifier {
  late Box<TaskModel> taskBox;
  late Box<HabitModel> habitBox;
  late Box<JournalModel> journalBox;
  late Box<CategoryModel> categoryBox;

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  DateTime selectedDate = DateTime.now();
  String selectedFilter = 'All'; // All, Health, Work, Study, Personal

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initHive() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(JournalModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());

    // Open Boxes
    try {
      taskBox = await Hive.openBox<TaskModel>('tasks');
    } catch (e) {
      await Hive.deleteBoxFromDisk('tasks');
      taskBox = await Hive.openBox<TaskModel>('tasks');
    }

    try {
      habitBox = await Hive.openBox<HabitModel>('habits');
    } catch (e) {
      await Hive.deleteBoxFromDisk('habits');
      habitBox = await Hive.openBox<HabitModel>('habits');
    }

    try {
      journalBox = await Hive.openBox<JournalModel>('journals');
    } catch (e) {
      await Hive.deleteBoxFromDisk('journals');
      journalBox = await Hive.openBox<JournalModel>('journals');
    }

    try {
      categoryBox = await Hive.openBox<CategoryModel>('categories');
    } catch (e) {
      await Hive.deleteBoxFromDisk('categories');
      categoryBox = await Hive.openBox<CategoryModel>('categories');
    }

    // Seed default categories if empty
    if (categoryBox.isEmpty) {
      final defaultCategories = [
        CategoryModel(
          id: 'cat_health',
          title: 'Health',
          colorValue: 0xFF00E5FF, // Vibrant Cyan
          iconCodePoint: CupertinoIcons.heart_fill.codePoint,
        ),
        CategoryModel(
          id: 'cat_work',
          title: 'Work',
          colorValue: 0xFF6C63FF, // Modern Purple
          iconCodePoint: CupertinoIcons.briefcase_fill.codePoint,
        ),
        CategoryModel(
          id: 'cat_study',
          title: 'Study',
          colorValue: 0xFFFF6B6B, // Vibrant Salmon
          iconCodePoint: CupertinoIcons.book_fill.codePoint,
        ),
        CategoryModel(
          id: 'cat_personal',
          title: 'Personal',
          colorValue: 0xFFFFB347, // Vibrant Orange
          iconCodePoint: CupertinoIcons.person_fill.codePoint,
        ),
      ];
      for (var cat in defaultCategories) {
        await categoryBox.put(cat.id, cat);
      }
    }

    // Initialize notifications
    if (!kIsWeb) {
      try {
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings iosSettings =
            DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            );
        const InitializationSettings initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );
        await notificationsPlugin.initialize(initSettings);

        // Required for Android 13+ to show notifications
        if (defaultTargetPlatform == TargetPlatform.android) {
          await notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();

          await notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestExactAlarmsPermission();
        }
      } catch (e) {
        debugPrint('Error init notifications: $e');
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  // Helper method: get tasks count for a category
  int getTaskCountForCategory(String categoryTitle) {
    return taskBox.values.where((t) => t.type == categoryTitle).length;
  }

  /// Public refresh — triggers a UI rebuild for all listeners.
  void refresh() => notifyListeners();

  // Tasks for a specific date
  List<TaskModel> tasksForDate(DateTime date) {
    return taskBox.values
        .where(
          (t) =>
              t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day,
        )
        .toList();
  }

  // Day progress for a category: [completed, total]
  (int, int) categoryDayProgress(String categoryTitle, DateTime date) {
    final tasks = tasksForDate(
      date,
    ).where((t) => t.type == categoryTitle).toList();
    final done = tasks.where((t) => t.status == 'completed').length;
    return (done, tasks.length);
  }

  // Week progress: [completed, total] for current week (Mon–Sun) up to today
  (int, int) weekProgress() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekTasks = taskBox.values.where((t) {
      return !t.date.isBefore(
            DateTime(monday.year, monday.month, monday.day),
          ) &&
          !t.date.isAfter(
            DateTime(sunday.year, sunday.month, sunday.day, 23, 59),
          );
    }).toList();
    final done = weekTasks.where((t) => t.status == 'completed').length;
    return (done, weekTasks.length);
  }

  // --- Date & Filtering Logic ---

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  // Get tasks for the highly currently selected date and filter
  List<TaskModel> get filteredTasks {
    final tasksForDay = taskBox.values.where((task) {
      return task.date.year == selectedDate.year &&
          task.date.month == selectedDate.month &&
          task.date.day == selectedDate.day;
    }).toList();

    if (selectedFilter == 'All') {
      return tasksForDay;
    }
    return tasksForDay.where((task) => task.type == selectedFilter).toList();
  }

  // --- Task Operations ---

  Future<void> addAdvancedTask({
    required String title,
    required String type,
    required DateTime date,
    DateTime? time,
    int? iconCodePoint,
    String priority = 'Normal',
    String note = '',
    String repetition = 'None',
    String subType = '',
  }) async {
    final newTask = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      date: date,
      time: time,
      iconCodePoint: iconCodePoint,
      priority: priority,
      note: note,
      repetition: repetition,
      subType: subType,
    );
    await taskBox.put(newTask.id, newTask);
    await _scheduleNotification(newTask);
    notifyListeners();
  }

  Future<void> updateAdvancedTask({
    required TaskModel existingTask,
    required String title,
    required String type,
    required DateTime date,
    DateTime? time,
    int? iconCodePoint,
    String priority = 'Normal',
    String note = '',
    String repetition = 'None',
    String subType = '',
  }) async {
    existingTask.title = title;
    existingTask.type = type;
    existingTask.date = date;
    existingTask.time = time;
    existingTask.iconCodePoint = iconCodePoint;
    existingTask.priority = priority;
    existingTask.note = note;
    existingTask.repetition = repetition;
    existingTask.subType = subType;

    await existingTask.save();
    await _scheduleNotification(existingTask);
    notifyListeners();
  }

  Future<void> _scheduleNotification(TaskModel task) async {
    if (kIsWeb) return;

    try {
      // Cancel any existing notification for this task
      final int notifId = task.id.hashCode;
      await notificationsPlugin.cancel(notifId);

      if (task.status == 'completed' || task.status == 'cancelled') return;
      if (task.time == null) return;

      // Combine task.date and task.time
      final scheduleTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time!.hour,
        task.time!.minute,
      );

      if (scheduleTime.isBefore(DateTime.now())) return;

      await notificationsPlugin.zonedSchedule(
        notifId,
        'Task Reminder: ${task.title}',
        task.note.isNotEmpty ? task.note : 'It is time for your task!',
        tz.TZDateTime.from(scheduleTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tasks_channel',
            'Task Reminders',
            channelDescription: 'Reminders for your scheduled tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> toggleTaskCompleted(TaskModel task) async {
    task.isCompleted = !task.isCompleted;
    task.status = task.isCompleted ? 'completed' : 'in_progress';
    await task.save();
    notifyListeners();
  }

  Future<void> updateTaskStatus(TaskModel task, String newStatus) async {
    task.status = newStatus;
    task.isCompleted = newStatus == 'completed';
    await task.save();
    notifyListeners();
  }

  Future<void> deleteTask(TaskModel task) async {
    if (!kIsWeb) {
      try {
        await notificationsPlugin.cancel(task.id.hashCode);
      } catch (_) {}
    }
    await task.delete();
    notifyListeners();
  }

  // --- Journal Operations ---

  Future<void> addJournal(JournalModel journal) async {
    await journalBox.put(journal.id, journal);
    notifyListeners();
  }

  Future<void> updateJournal(JournalModel journal) async {
    await journal.save();
    notifyListeners();
  }

  Future<void> deleteJournal(JournalModel journal) async {
    await journal.delete();
    notifyListeners();
  }
}
