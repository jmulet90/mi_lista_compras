import 'package:hive/hive.dart';

import '../../domain/entities/category_item.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @override
  @HiveField(0)
  String key;

  @HiveField(1)
  String? emoji;

  @HiveField(2)
  String? imagePath;

  CategoryModel({
    required this.key,
    this.emoji,
    this.imagePath,
  });

  factory CategoryModel.fromEntity(CategoryItem category) {
    return CategoryModel(
      key: category.key,
      emoji: category.emoji,
      imagePath: category.imagePath,
    );
  }

  CategoryItem toEntity() {
    return CategoryItem(
      key: key,
      emoji: emoji,
      imagePath: imagePath,
    );
  }
}
