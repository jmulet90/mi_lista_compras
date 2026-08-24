class EmojiManager {
  static String getEmojiPath(String emojiName) {
    return 'assets/images/emojis/categories/$emojiName.png';
  }

  static String getCategoryPath(String imageName) {
    return 'assets/images/emojis/categories/$imageName.png';
  }

  static String getProductPath(String imageName) {
    return 'assets/images/emojis/products/$imageName.png';
  }

  static String getCategoryEmoji(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'cocina':
        return getCategoryPath('kitchen');
      case 'limpieza':
        return getCategoryPath('cleaning');
      case 'cuidado personal':
        return getCategoryPath('personal_care');
      case 'carnes':
        return getCategoryPath('meats');
      case 'bebidas':
        return getCategoryPath('drink');
      default:
        return getCategoryPath('default_item');
    }
  }

  // NUEVO: Mapeo automático de productos basado en su nombre
  static String? getProductEmojiByName(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('apple') || name.contains('manzana')) return getProductPath('apples');
    if (name.contains('milk') || name.contains('leche')) return getProductPath('milk');
    if (name.contains('coffee') || name.contains('café') || name.contains('cafe')) return getProductPath('coffee');
    if (name.contains('orange') || name.contains('naranja')) return getProductPath('oranges');
    if (name.contains('tomato') || name.contains('tomate')) return getProductPath('tomatoes');
    return null;
  }
}