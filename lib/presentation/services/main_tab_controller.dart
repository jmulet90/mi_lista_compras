import 'package:flutter/foundation.dart';

/// Índice de la pestaña principal (0 = Comprar, 1 = Despensa), compartido
/// entre la pantalla principal y los detalles de categoría/subcategoría.
///
/// Cuando dentro de un detalle se toca el carrito o la casita de la píldora,
/// se cambia este índice y se regresa a la pantalla principal del lado elegido.
class MainTabController {
  MainTabController._();

  static final ValueNotifier<int> index = ValueNotifier(1);

  static void switchTo(int value) => index.value = value;
}