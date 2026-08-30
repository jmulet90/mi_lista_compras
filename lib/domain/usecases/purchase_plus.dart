import '../entities/premium_status.dart';
import '../repositories/premium_repository.dart';

/// Lanza la compra del plan Premium Plus; resuelve cuando la tienda
/// confirma (o rechaza) la transacción.
class PurchasePremiumPlusUseCase {
  PurchasePremiumPlusUseCase(this._repository);

  final PremiumRepository _repository;

  Future<bool> call() => _repository.purchase(AppTier.premiumPlus);
}