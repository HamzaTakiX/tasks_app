import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 1)
class HabitModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int streakCount;

  @HiveField(3)
  DateTime? lastCompletedDate;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  int iconCodePoint;

  @HiveField(6)
  String frequency; // daily, weekdays, weekends, custom

  @HiveField(7)
  int bestStreak;

  @HiveField(8)
  List<DateTime> completedDates; // full history

  HabitModel({
    required this.id,
    required this.title,
    this.streakCount = 0,
    this.lastCompletedDate,
    this.colorValue = 0xFF3478F6,
    this.iconCodePoint = 0xF46D, // star
    this.frequency = 'daily',
    this.bestStreak = 0,
    List<DateTime>? completedDates,
  }) : completedDates = completedDates ?? [];

  bool get isCompletedToday {
    final now = DateTime.now();
    return lastCompletedDate != null &&
        lastCompletedDate!.year == now.year &&
        lastCompletedDate!.month == now.month &&
        lastCompletedDate!.day == now.day;
  }

  bool wasCompletedOn(DateTime date) {
    return completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }
}
