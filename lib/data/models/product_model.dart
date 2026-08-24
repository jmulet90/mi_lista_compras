import 'package:hive/hive.dart';

import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  String nameKey;

  @HiveField(1)
  String categoryKey;

  @HiveField(2)
  bool isToBuy;

  @HiveField(3)
  String? emoji;

  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  bool isBuyScreen;

  ProductModel({
    required this.nameKey,
    required this.categoryKey,
    this.isToBuy = true,
    this.emoji,
    this.imagePath,
    this.isBuyScreen = true,
  });

  String get uniqueKey => '${categoryKey}_${nameKey.trim().toLowerCase()}';

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      nameKey: product.nameKey,
      categoryKey: product.categoryKey,
      isToBuy: product.isToBuy,
      emoji: product.emoji,
      imagePath: product.imagePath,
      isBuyScreen: product.isBuyScreen,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      nameKey: map['nameKey'] as String? ?? '',
      categoryKey: map['categoryKey'] as String? ?? '',
      isToBuy: map['isToBuy'] as bool? ?? false,
      emoji: map['emoji'] as String?,
      isBuyScreen: map['isBuyScreen'] as bool? ?? false,
    );
  }

  Product toEntity() {
    return Product(
      nameKey: nameKey,
      categoryKey: categoryKey,
      isToBuy: isToBuy,
      emoji: emoji,
      imagePath: imagePath,
      isBuyScreen: isBuyScreen,
    );
  }

  /// Campos sincronizados con Firestore (igual que el SyncService original:
  /// imagePath NO se sube a la nube).
  Map<String, dynamic> toMap() {
    return {
      'nameKey': nameKey,
      'categoryKey': categoryKey,
      'isToBuy': isToBuy,
      'emoji': emoji,
      'isBuyScreen': isBuyScreen,
    };
  }
}
