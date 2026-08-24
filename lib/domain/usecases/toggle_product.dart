import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/access_guard.dart';

/// Cambia un producto entre la lista de compra y la despensa.
class ToggleProductUseCase {
  ToggleProductUseCase(this._products, this._guard);

  final ProductRepository _products;
  final AccessGuard _guard;

  Future<void> call(Product product) async {
    await _guard.ensureCanMoveItems();

    product.isToBuy = !product.isToBuy;
    await _products.upsert(product);
  }
}
