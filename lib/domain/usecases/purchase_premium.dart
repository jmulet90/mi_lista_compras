import '../repositories/premium_repository.dart';

/// Lanza la compra del desbloqueo premium; resuelve cuando la tienda
/// confirma (o rechaza) la transacción.
class PurchasePremiumUseCase {
  PurchasePremiumUseCase(this._repository);

  final PremiumRepository _repository;

  Future<bool> call() => _repository.purchase();
}
