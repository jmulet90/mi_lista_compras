/// Estado del desbloqueo premium (compra única no consumible).
class PremiumStatus {
  const PremiumStatus({
    required this.isPremium,
    this.pending = false,
    this.priceText,
  });

  final bool isPremium;

  /// True mientras la tienda está confirmando la transacción.
  final bool pending;

  /// Precio formateado por la tienda ("1,99 €"); null si aún no se consultó.
  final String? priceText;

  PremiumStatus copyWith({
    bool? isPremium,
    bool? pending,
    String? priceText,
  }) {
    return PremiumStatus(
      isPremium: isPremium ?? this.isPremium,
      pending: pending ?? this.pending,
      priceText: priceText ?? this.priceText,
    );
  }
}
