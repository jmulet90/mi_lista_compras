/// Registro histórico de "producto comprado": se crea cada vez que un
/// producto pasa de la lista de compras a la despensa (ver
/// `ToggleProductUseCase`). Es la materia prima del análisis de patrones de
/// compra (`ShoppingPatternAnalyzer`). Vive 100% en el dispositivo (Hive), no
/// se sincroniza a la nube.
class PurchaseEvent {
  PurchaseEvent({
    required this.productKey,
    required this.categoryKey,
    this.subcategory,
    this.quantity,
    this.unit,
    required this.purchasedAt,
  });

  /// `nameKey` del producto comprado.
  final String productKey;
  final String categoryKey;
  final String? subcategory;

  /// Cantidad/unidad que tenía el producto en la lista justo antes de
  /// marcarse como comprado (se limpian del producto al pasar a despensa).
  final double? quantity;
  final String? unit;

  final DateTime purchasedAt;
}
