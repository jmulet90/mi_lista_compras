/// Subcategoría persistida: nombre + visual (emoji o foto).
///
/// Un nombre por sí solo no bastaba para el diseño pedido: cada fila de
/// subcategoría debe mostrar la misma tarjeta que las categorías, con un
/// círculo redondo que lleva su imagen.
class SubcategoryItem {
  const SubcategoryItem({
    required this.name,
    this.emoji,
    this.imagePath,
  });

  final String name;
  final String? emoji;
  final String? imagePath;
}