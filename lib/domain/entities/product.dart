class Product {
  Product({
    required this.nameKey,
    required this.categoryKey,
    this.isToBuy = true,
    this.emoji,
    this.imagePath,
    this.isBuyScreen = true,
  });

  String nameKey;
  String categoryKey;
  bool isToBuy;
  String? emoji;
  String? imagePath;
  bool isBuyScreen;

  String get id => nameKey.trim();

  String get uniqueKey => '${categoryKey}_${nameKey.trim().toLowerCase()}';

  Product copyWith({
    String? nameKey,
    String? categoryKey,
    bool? isToBuy,
    String? emoji,
    String? imagePath,
    bool? isBuyScreen,
  }) {
    return Product(
      nameKey: nameKey ?? this.nameKey,
      categoryKey: categoryKey ?? this.categoryKey,
      isToBuy: isToBuy ?? this.isToBuy,
      emoji: emoji ?? this.emoji,
      imagePath: imagePath ?? this.imagePath,
      isBuyScreen: isBuyScreen ?? this.isBuyScreen,
    );
  }
}
