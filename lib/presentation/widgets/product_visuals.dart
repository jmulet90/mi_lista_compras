import 'dart:io';

import 'package:flutter/material.dart';

import 'dialog_kit.dart';

/// Renderiza el visual de un producto con esta prioridad:
/// foto del usuario > PNG del catálogo (emoji guarda ruta asset) > glifo.
class ProductVisuals {
  ProductVisuals._();

  static Widget circleChild({
    String? imagePath,
    String? emoji,
    double emojiSize = 45,
    String fallbackEmoji = '📦',
  }) {
    if (imagePath != null) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (DialogKit.isAssetRef(emoji)) {
      // Sin margen interno: el PNG llena el círculo al máximo.
      return Image.asset(emoji!, fit: BoxFit.contain);
    }
    // El glifo escala solo hasta caber completo, con aire respecto al borde.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            emoji ?? fallbackEmoji,
            style: TextStyle(fontSize: emojiSize),
          ),
        ),
      ),
    );
  }
}
