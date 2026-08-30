import 'dart:io';

import 'package:flutter/material.dart';

import 'dialog_kit.dart';

class CategoryVisuals {
  static const Map<String, String> _categoryAssets = {
    'Kitchen': 'assets/images/emojis/categories/kitchen.png',
    'Personal care': 'assets/images/emojis/categories/personal_care.png',
    'Cleaning': 'assets/images/emojis/categories/cleaning.png',
    'Meats': 'assets/images/emojis/categories/meats.png',
    'Drinks': 'assets/images/emojis/categories/drinks.png',
    'Breakfast': 'assets/images/emojis/categories/breakfast.png',
    'Fruits': 'assets/images/emojis/categories/fruits.png',
    'Vegetables': 'assets/images/emojis/categories/vegetables.png',
  };

  static String? assetFor(String categoryKey) => _categoryAssets[categoryKey];

  /// Claves canónicas con PNG de categoría (para el selector).
  static List<String> get categoryKeys => _categoryAssets.keys.toList();

  /// Rutas completas de los PNG de categoría disponibles (para el selector).
  static List<String> get assets => _categoryAssets.values.toList();

  static Widget circleChild({
    required String categoryKey,
    String? imagePath,
    String? emoji,
    double emojiSize = 45,
  }) {
    if (imagePath != null) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    final assetPath = assetFor(categoryKey);
    if (assetPath != null) {
      return Image.asset(assetPath, fit: BoxFit.cover);
    }
    if (emoji != null) {
      if (DialogKit.isAssetRef(emoji)) {
        return Image.asset(emoji, fit: BoxFit.cover);
      }
      return Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: emojiSize * 0.65),
        ),
      );
    }
    return Center(
      child: Icon(
        Icons.category_outlined,
        size: emojiSize * 0.65,
        color: Colors.grey.shade400,
      ),
    );
  }
}
