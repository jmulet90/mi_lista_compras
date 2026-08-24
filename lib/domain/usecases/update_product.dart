import '../../core/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/access_guard.dart';

/// Edita nombre, emoji e imagen de un producto existente.
class UpdateProductUseCase {
  UpdateProductUseCase(this._products, this._guard);

  final ProductRepository _products;
  final AccessGuard _guard;

  Future<void> call({
    required Product product,
    required String newName,
    String? emoji,
    String? imagePath,
  }) async {
    await _guard.ensureCanFullyEdit();

    final nameKey = newName.trim();
    if (nameKey.isEmpty) {
      throw const ValidationFailure('El nombre del producto es obligatorio');
    }

    final oldId = product.id;
    product
      ..nameKey = nameKey
      ..emoji = emoji
      ..imagePath = imagePath;

    await _products.upsert(product);

    // Si cambió el nombre, la clave local anterior queda huérfana: se limpia.
    if (oldId != product.id) {
      await _products.deleteById(oldId);
    }
  }
}
