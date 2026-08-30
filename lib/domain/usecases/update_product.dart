import '../../core/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/access_guard.dart';

/// Edita nombre, emoji e imagen de un producto existente.
class UpdateProductUseCase {
  UpdateProductUseCase(this._products, this._guard);

  final ProductRepository _products;
  final AccessGuard _guard;

  /// Valor que indica que el llamador no tocó la subcategoría: se conserva
  /// la actual. Si se quiere sacar el producto de su subcategoría hay que
  /// pasar `subcategory: null`.
  static const Object _preserveSubcategory = Object();

  Future<void> call({
    required Product product,
    required String newName,
    String? emoji,
    String? imagePath,
    double? quantity,
    String? unit,
    Object? subcategory = _preserveSubcategory,
    String? categoryKey,
    bool clearSubcategory = false,
  }) async {
    await _guard.ensureCanFullyEdit();

    final nameKey = newName.trim();
    if (nameKey.isEmpty) {
      throw const ValidationFailure('El nombre del producto es obligatorio');
    }

    final String? newSubcategory = clearSubcategory
        ? null
        : identical(subcategory, _preserveSubcategory)
            ? product.subcategory
            : subcategory as String?;

    final oldId = product.id;
    product
      ..nameKey = nameKey
      ..emoji = emoji
      ..imagePath = imagePath
      ..quantity = quantity
      ..unit = unit
      ..subcategory = newSubcategory;
    if (categoryKey != null && categoryKey.isNotEmpty) {
      product.categoryKey = categoryKey;
    }

    await _products.upsert(product, previousId: oldId);

    if (oldId.trim().toLowerCase() != product.id.trim().toLowerCase()) {
      await _products.deleteById(oldId);
    }
  }
}
