import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/access_guard.dart';

class DeleteProductUseCase {
  DeleteProductUseCase(this._products, this._guard);

  final ProductRepository _products;
  final AccessGuard _guard;

  Future<void> call(Product product) async {
    await _guard.ensureCanFullyEdit();
    await _products.deleteById(product.id);
  }
}
