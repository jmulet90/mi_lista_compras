class Product {
  Product({
    required this.nameKey,
    required this.categoryKey,
    this.isToBuy = true,
    this.emoji,
    this.imagePath,
    this.isBuyScreen = true,
    this.imageId,
    this.quantity,
    this.unit,
    this.subcategory,
  });

  String nameKey;
  String categoryKey;
  bool isToBuy;
  String? emoji;
  String? imagePath;
  bool isBuyScreen;
  String? imageId;
  double? quantity;
  String? unit;

  /// Subcategoría (grupo) dentro de la categoría. Solo Premium Plus.
  String? subcategory;

  String get id => nameKey.trim();

  String get uniqueKey => '${categoryKey}_${nameKey.trim().toLowerCase()}';

  Product copyWith({
    String? nameKey,
    String? categoryKey,
    bool? isToBuy,
    String? emoji,
    String? imagePath,
    bool? isBuyScreen,
    String? imageId,
    double? quantity,
    String? unit,
    String? subcategory,
  }) {
    return Product(
      nameKey: nameKey ?? this.nameKey,
      categoryKey: categoryKey ?? this.categoryKey,
      isToBuy: isToBuy ?? this.isToBuy,
      emoji: emoji ?? this.emoji,
      imagePath: imagePath ?? this.imagePath,
      isBuyScreen: isBuyScreen ?? this.isBuyScreen,
      imageId: imageId ?? this.imageId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      subcategory: subcategory ?? this.subcategory,
    );
  }
}
