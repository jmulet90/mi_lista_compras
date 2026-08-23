import 'package:hive/hive.dart';

part 'category_item.g.dart';

@HiveType(typeId: 1)
class CategoryItem extends HiveObject {
  @override
  @HiveField(0)
  String key;

  @HiveField(1)
  String? emoji;

  @HiveField(2)
  String? imagePath;

  @HiveField(3)
  bool isBuyScreen;

  CategoryItem({
    required this.key,
    this.emoji,
    this.imagePath,
    this.isBuyScreen = true,
  });
}