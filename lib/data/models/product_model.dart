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

  @HiveField(6)
  String? imageId;

  @HiveField(7)
  double? quantity;

  @HiveField(8)
  String? unit;

  ProductModel({
    required this.nameKey,
    required this.categoryKey,
    this.isToBuy = true,
    this.emoji,
    this.imagePath,
    this.isBuyScreen = true,
    this.imageId,
    this.quantity,
    this.unit,
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
      imageId: product.imageId,
      quantity: product.quantity,
      unit: product.unit,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      nameKey: map['nameKey'] as String? ?? '',
      categoryKey: map['categoryKey'] as String? ?? '',
      isToBuy: map['isToBuy'] as bool? ?? false,
      emoji: map['emoji'] as String?,
      imagePath: map['imagePath'] as String?,
      isBuyScreen: map['isBuyScreen'] as bool? ?? false,
      imageId: map['imageId'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
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
      imageId: imageId,
      quantity: quantity,
      unit: unit,
    );
  }

  /// Campos sincronizados con Firestore. Los bytes de la imagen viajan en la
  /// subcolección `product_images` referenciada por [imageId]; el archivo
  /// local [imagePath] nunca se sube.
  Map<String, dynamic> toMap() {
    return {
      'nameKey': nameKey,
      'categoryKey': categoryKey,
      'isToBuy': isToBuy,
      'emoji': emoji,
      'isBuyScreen': isBuyScreen,
      'imageId': imageId,
      'quantity': quantity,
      'unit': unit,
    };
  }
}
