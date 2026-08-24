import '../entities/premium_status.dart';

abstract class PremiumRepository {
  /// Identificador del producto en Google Play (compra única).
  static const String productId = 'premium_unlock';

  /// Estado premium reactivo.
  Stream<PremiumStatus> watch();

  /// Último estado conocido (útil para checks síncronos).
  PremiumStatus current();

  /// Suscribe el stream de compras y refresca precio/compras previas.
  /// Debe llamarse una vez al arrancar la app.
  Future<void> init();

  /// Lanza la compra; resuelve true solo si quedó activado.
  Future<bool> purchase();

  /// Pide a la tienda las compras previas de esta cuenta.
  Future<void> restore();

  /// Solo en builds debug: alterna un override local para probar los
  /// límites sin tener el producto publicado en Play Console.
  Future<void> toggleDebugOverride();
}
