/// Plan de pago del usuario.
///
/// Orden creciente de capacidad: `free` < `premium` < `premiumPlus`.
enum AppTier {
  free(0),
  premium(1),
  premiumPlus(2);

  const AppTier(this.value);

  final int value;

  static AppTier fromValue(int value) {
    switch (value) {
      case 1:
        return AppTier.premium;
      case 2:
        return AppTier.premiumPlus;
      default:
        return AppTier.free;
    }
  }

  bool get isPremium => this != AppTier.free;

  bool get isPremiumPlus => this == AppTier.premiumPlus;
}

/// Estado del plan de pago (suscripción mensual: Premium y Premium Plus).
class PremiumStatus {
  const PremiumStatus({
    this.tier = AppTier.free,
    this.pending = false,
    this.priceText,
    this.priceTextPlus,
  });

  /// Plan actual del usuario (libre, premium o premium plus).
  final AppTier tier;

  /// True mientras la tienda está confirmando la transacción.
  final bool pending;

  /// Precio formateado del plan Premium ("1,99 €"); null si aún no se consultó.
  final String? priceText;

  /// Precio formateado del plan Premium Plus ("2,99 €"); null si aún no se consultó.
  final String? priceTextPlus;

  bool get isPremium => tier.isPremium;

  bool get isPremiumPlus => tier.isPremiumPlus;

  PremiumStatus copyWith({
    AppTier? tier,
    bool? pending,
    String? priceText,
    String? priceTextPlus,
  }) {
    return PremiumStatus(
      tier: tier ?? this.tier,
      pending: pending ?? this.pending,
      priceText: priceText ?? this.priceText,
      priceTextPlus: priceTextPlus ?? this.priceTextPlus,
    );
  }
}