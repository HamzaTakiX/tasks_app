import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alarm/alarm.dart';
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
    return taskBox.values.where((t) {
      // 1. Exact match
      if (t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day) {
        return true;
      }

      // 2. Recurring match
      final tDateOnly = DateTime(t.date.year, t.date.month, t.date.day);
      final checkDateOnly = DateTime(date.year, date.month, date.day);
      if (checkDateOnly.isBefore(tDateOnly)) return false;

      if (t.repetition == 'Daily') return true;
      if (t.repetition == 'Weekdays' && date.weekday >= 1 && date.weekday <= 5) return true;
      if (t.repetition == 'Weekly' && date.weekday == t.date.weekday) return true;

      // Custom
      if (t.repeatDaysJson != null) {
        if (t.repeatDaysJson == 'every_other_day') {
          final diff = checkDateOnly.difference(tDateOnly).inDays;
          if (diff % 2 == 0) return true;
        } else {
          try {
            final List<dynamic> daysList = jsonDecode(t.repeatDaysJson!);
            if (daysList.contains(date.weekday)) return true;
          } catch (_) {}
        }
      }

      return false;
    }).toList();
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
    String? repeatDaysJson,
    String? taskTimesJson,
    int? reminderOffset,
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
      repeatDaysJson: repeatDaysJson,
      taskTimesJson: taskTimesJson,
      reminderOffset: reminderOffset,
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
    String? repeatDaysJson,
    String? taskTimesJson,
    int? reminderOffset,
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
    existingTask.repeatDaysJson = repeatDaysJson;
    existingTask.taskTimesJson = taskTimesJson;
    existingTask.reminderOffset = reminderOffset;

    await existingTask.save();
    await _scheduleNotification(existingTask);
    notifyListeners();
  }

  Future<void> _scheduleNotification(TaskModel task) async {
    if (kIsWeb) return;

    try {
      final baseIdStr = task.id;
      
      // Cancel previous variations (up to 5 times per day max)
      for (int i = 0; i < 5; i++) {
        await Alarm.stop("${baseIdStr}_$i".hashCode.abs() % 2147483647);
        await notificationsPlugin.cancel("${baseIdStr}_${i}_pre".hashCode.abs() % 2147483647);
        for (int j = 0; j < 10; j++) {
           await notificationsPlugin.cancel("${baseIdStr}_${i}_post_$j".hashCode.abs() % 2147483647);
        }
      }
      // Also cancel any old single ones
      await notificationsPlugin.cancel(task.id.hashCode.abs() % 2147483647);
      await Alarm.stop(task.id.hashCode.abs() % 2147483647);

      if (task.status == 'completed' || task.status == 'cancelled') return;

      // Extract times
      List<TimeOfDay> timesToSchedule = [];
      if (task.taskTimesJson != null && task.taskTimesJson!.isNotEmpty) {
        try {
          final List<dynamic> timesList = jsonDecode(task.taskTimesJson!);
          for (var t in timesList) {
            final parts = t.toString().split(':');
            timesToSchedule.add(TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
          }
        } catch (_) {}
      } else if (task.time != null) {
        timesToSchedule.add(TimeOfDay(hour: task.time!.hour, minute: task.time!.minute));
      }

      if (timesToSchedule.isEmpty) return;

      DateTime now = DateTime.now();

      for (int i = 0; i < timesToSchedule.length; i++) {
         final tod = timesToSchedule[i];
         
         DateTime? nextSchedule;
         // Search next 14 days for the upcoming occurrence
         for (int d = 0; d < 14; d++) {
            final checkDate = DateTime(now.year, now.month, now.day).add(Duration(days: d));
            final tDateOnly = DateTime(task.date.year, task.date.month, task.date.day);
            if (checkDate.isBefore(tDateOnly)) continue;
            
            bool matches = false;
            if (task.repetition == 'Daily') {
                matches = true;
            } else if (task.repetition == 'Weekdays' && checkDate.weekday >= 1 && checkDate.weekday <= 5) {
                matches = true;
            } else if (task.repetition == 'Weekly' && checkDate.weekday == task.date.weekday) {
                matches = true;
            } else if (task.repeatDaysJson == 'every_other_day') {
                if (checkDate.difference(tDateOnly).inDays % 2 == 0) matches = true;
            } else if (task.repeatDaysJson != null && task.repeatDaysJson != 'every_other_day') {
               try {
                  final List<dynamic> daysList = jsonDecode(task.repeatDaysJson!);
                  if (daysList.contains(checkDate.weekday)) matches = true;
               } catch (_) {}
            } else if (checkDate.year == task.date.year && checkDate.month == task.date.month && checkDate.day == task.date.day) {
               matches = true;
            }

            if (matches) {
               final potentialSchedule = DateTime(checkDate.year, checkDate.month, checkDate.day, tod.hour, tod.minute);
               if (potentialSchedule.isAfter(now)) {
                  nextSchedule = potentialSchedule;
                  break;
               }
            }
         }

         if (nextSchedule == null) continue;

         final baseAlarmId = "${baseIdStr}_$i".hashCode.abs() % 2147483647;
         final preNotifId = "${baseIdStr}_${i}_pre".hashCode.abs() % 2147483647;

         // 1. Persistent main alarm
         final alarmSettings = AlarmSettings(
            id: baseAlarmId,
            dateTime: nextSchedule,
            assetAudioPath: 'assets/alarm.mp3',
            loopAudio: true,
            vibrate: true,
            notificationSettings: NotificationSettings(
              title: '⏰ Task Alarm: ${task.title}',
              body: task.note.isNotEmpty ? task.note : 'It is time for your task!',
              stopButton: 'Stop',
            ),
            volumeSettings: VolumeSettings.fixed(volume: 0.8),
         );
         await Alarm.set(alarmSettings: alarmSettings);

         // 2. Early notification 
         final offset = task.reminderOffset ?? 5;
         if (offset > 0) {
            final preTime = nextSchedule.subtract(Duration(minutes: offset));
            if (preTime.isAfter(now)) {
               await notificationsPlugin.zonedSchedule(
                  preNotifId,
                  '⏰ Upcoming Task: ${task.title}',
                  'Starts in $offset minutes. ${task.note}',
                  tz.TZDateTime.from(preTime, tz.local),
                  const NotificationDetails(
                     android: AndroidNotificationDetails('tasks_alarm_channel_pre', 'Task Early Reminders', channelDescription: 'Pre-alarms', importance: Importance.high, priority: Priority.high, enableVibration: true, playSound: true),
                     iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
                  ),
                  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
               );
            }
         }

         // 3. Ten post notifications spanning 1 to 10 mins
         for (int j = 0; j < 10; j++) {
            final postTime = nextSchedule.add(Duration(minutes: j + 1));
            final postNotifId = "${baseIdStr}_${i}_post_$j".hashCode.abs() % 2147483647;
            await notificationsPlugin.zonedSchedule(
               postNotifId,
               '⏰ Missed Task?: ${task.title}',
               'Task started at ${tod.hour.toString().padLeft(2,'0')}:${tod.minute.toString().padLeft(2,'0')}. Please check your list!',
               tz.TZDateTime.from(postTime, tz.local),
               const NotificationDetails(
                  android: AndroidNotificationDetails('tasks_alarm_channel_post', 'Task Late Reminders', channelDescription: 'Reminders for missed tasks', importance: Importance.max, priority: Priority.high, enableVibration: true, playSound: true),
                  iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
               ),
               androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
               uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            );
         }
      }
    } catch (e) {
      debugPrint('Error scheduling alarm/notification: $e');
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
