import '../entities/premium_status.dart';
import '../repositories/premium_repository.dart';

/// Expone el estado premium como stream reactivo.
class CheckPremiumUseCase {
  CheckPremiumUseCase(this._repository);

  final PremiumRepository _repository;

  Stream<PremiumStatus> call() => _repository.watch();
}
