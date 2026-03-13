import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String type;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime? time;

  @HiveField(6)
  int? iconCodePoint;

  @HiveField(7)
  String priority;

  @HiveField(8)
  String note;

  @HiveField(9)
  String repetition;

  @HiveField(10)
  String subType;

  @HiveField(11)
  String status;

  /// JSON array of work sessions:
  /// [{"start":"2026-03-08T08:00:00","end":"2026-03-08T09:00:00"}, ...]
  /// If a session has no "end", it is currently active.
  @HiveField(12)
  String sessionsJson;

  /// JSON list of integers for custom repeat days, or a custom string code
  /// e.g. "[1,3,5]" for Mon/Wed/Fri, or "every_other_day"
  @HiveField(13)
  String? repeatDaysJson;

  /// JSON list of time strings
  /// e.g. ["08:00", "15:30"]
  @HiveField(14)
  String? taskTimesJson;

  /// Remind X minutes before task
  @HiveField(15)
  int? reminderOffset;

  TaskModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.isCompleted = false,
    this.time,
    this.iconCodePoint,
    this.priority = 'Normal',
    this.note = '',
    this.repetition = 'None',
    this.subType = '',
    this.status = 'in_progress',
    this.sessionsJson = '[]',
    this.repeatDaysJson,
    this.taskTimesJson,
    this.reminderOffset = 5,
  });
}
