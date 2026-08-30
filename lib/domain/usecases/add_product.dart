import '../../core/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/access_guard.dart';

class AddProductUseCase {
  AddProductUseCase(this._products, this._guard);

  final ProductRepository _products;
  final AccessGuard _guard;

  Future<void> call({
    required String name,
    required String categoryKey,
    required bool isBuyScreen,
    String? emoji,
    String? imagePath,
    double? quantity,
    String? unit,
    String? subcategory,
  }) async {
    await _guard.ensureCanFullyEdit();

    final nameKey = name.trim();
    if (nameKey.isEmpty || categoryKey.isEmpty) {
      throw const ValidationFailure('El nombre y la categoría son obligatorios');
    }

    await _products.deleteWhere(
      (p) =>
          p.nameKey.trim().toLowerCase() == nameKey.toLowerCase() &&
          p.categoryKey == categoryKey &&
          p.isToBuy == isBuyScreen,
    );

    await _products.upsert(Product(
      nameKey: nameKey,
      categoryKey: categoryKey,
      isToBuy: isBuyScreen,
      isBuyScreen: isBuyScreen,
      emoji: emoji,
      imagePath: imagePath,
      quantity: quantity,
      unit: unit,
      subcategory: subcategory,
    ));
  }
}
