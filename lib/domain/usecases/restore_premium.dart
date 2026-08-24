import '../repositories/premium_repository.dart';

/// Solicita a la tienda restaurar compras previas de esta cuenta.
class RestorePurchasesUseCase {
  RestorePurchasesUseCase(this._repository);

  final PremiumRepository _repository;

  Future<void> call() => _repository.restore();
}
