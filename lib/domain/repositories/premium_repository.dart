import '../entities/premium_status.dart';

abstract class PremiumRepository {
  /// Identificador del producto del plan Premium en Google Play (mensual).
  static const String productId = 'premium_unlock';

  /// Identificador del producto del plan Premium Plus en Google Play (mensual).
  static const String premiumPlusId = 'premium_plus_unlock';

  /// Estado del plan reactivo.
  Stream<PremiumStatus> watch();

  /// Último estado conocido (útil para checks síncronos).
  PremiumStatus current();

  /// Suscribe el stream de compras y refresca precio/compras previas.
  /// Debe llamarse una vez al arrancar la app.
  Future<void> init();

  /// Se invoca cuando el plan del usuario cambia, notificando el [AppTier]
  /// completo (premium o premiumPlus) para que el owner pueda propagarlo a
  /// sus colaboradores.
  void Function(AppTier tier)? get onPremiumChanged;

  /// Lanza la compra del plan [tier] (Premium o Premium Plus); resuelve
  /// true solo si quedó activado (o ya estaba activo).
  Future<bool> purchase(AppTier tier);

  /// Pide a la tienda las compras previas de esta cuenta.
  Future<void> restore();

  /// Solo en builds debug: alterna un override local para probar los límites
  /// sin tener los productos publicados en Play Console.
  /// Cicla: libre -> Premium -> Premium Plus -> libre.
  Future<void> toggleDebugOverride();
}