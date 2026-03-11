import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int colorValue; // e.g. Colors.blue.value

  @HiveField(3)
  int iconCodePoint;

  CategoryModel({
    required this.id,
    required this.title,
    required this.colorValue,
    required this.iconCodePoint,
  });
}
