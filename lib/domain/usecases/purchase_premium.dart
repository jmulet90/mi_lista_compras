import '../entities/premium_status.dart';
import '../repositories/premium_repository.dart';

/// Lanza la compra del plan Premium; resuelve cuando la tienda
/// confirma (o rechaza) la transacción.
class PurchasePremiumUseCase {
  PurchasePremiumUseCase(this._repository);

  final PremiumRepository _repository;

  Future<bool> call() => _repository.purchase(AppTier.premium);
}