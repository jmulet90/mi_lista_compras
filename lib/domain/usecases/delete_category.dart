import '../entities/category_item.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../services/access_guard.dart';

/// Elimina una categoría junto con todos sus productos (local y nube).
class DeleteCategoryUseCase {
  DeleteCategoryUseCase(
    this._categories,
    this._products,
    this._guard,
  );

  final CategoryRepository _categories;
  final ProductRepository _products;
  final AccessGuard _guard;

  Future<void> call(CategoryItem category) async {
    await _guard.ensureCanFullyEdit();

    final products = await _products.getAll();
    for (final product in products.where((p) => p.categoryKey == category.key)) {
      await _products.deleteById(product.id);
    }
    await _categories.delete(category.key);
  }
}
