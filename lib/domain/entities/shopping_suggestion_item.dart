/// Producto sugerido por `ShoppingPatternAnalyzer` para una próxima compra,
/// derivado del historial real del usuario.
class ShoppingSuggestionItem {
  ShoppingSuggestionItem({
    required this.productKey,
    required this.categoryKey,
    this.quantity,
    this.unit,
    required this.frequency,
  });

  /// `nameKey` del producto.
  final String productKey;
  final String categoryKey;

  /// Cantidad/unidad típica con la que el usuario suele comprarlo (moda).
  final double? quantity;
  final String? unit;

  /// Proporción de viajes de compra recientes en los que apareció (0..1).
  final double frequency;
}
