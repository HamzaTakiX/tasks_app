import 'package:hive/hive.dart';

part 'journal_model.g.dart';

@HiveType(typeId: 2)
class JournalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String dateString;

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  String mood;

  @HiveField(5)
  String category; // Reference to CategoryModel.title

  @HiveField(6)
  List<String> linkedTaskIds;

  @HiveField(7)
  List<String> imagePaths;

  @HiveField(8)
  DateTime createdAt;

  JournalModel({
    required this.id,
    required this.dateString,
    this.title = '',
    required this.content,
    this.mood = '',
    this.category = '',
    this.linkedTaskIds = const [],
    this.imagePaths = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
