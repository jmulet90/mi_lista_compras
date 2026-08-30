import 'dart:io';

import 'package:flutter/material.dart';

import 'dialog_kit.dart';

/// Renderiza el visual de un producto con esta prioridad:
/// foto del usuario > PNG del catálogo (emoji guarda ruta asset) > ícono por defecto.
class ProductVisuals {
  ProductVisuals._();

  static Widget circleChild({
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
    if (DialogKit.isAssetRef(emoji)) {
      return Image.asset(
        emoji!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // El asset referenciado no está en el bundle: cae al ícono por defecto
          // en vez de mostrar el placeholder de imagen rota.
          return Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: emojiSize * 0.65,
              color: Colors.grey.shade400,
            ),
          );
        },
      );
    }
    // Sin emoji ni foto: ícono por defecto.
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: emojiSize * 0.65,
        color: Colors.grey.shade400,
      ),
    );
  }
}
