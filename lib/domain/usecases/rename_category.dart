import '../../core/failures.dart';
import '../entities/category_item.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../services/access_guard.dart';

/// Renombra/actualiza una categoría y propaga el cambio a todos sus productos.
class RenameCategoryUseCase {
  RenameCategoryUseCase(
    this._categories,
    this._products,
    this._guard,
  );

  final CategoryRepository _categories;
  final ProductRepository _products;
  final AccessGuard _guard;

  Future<void> call({
    required CategoryItem category,
    required String newName,
    String? emoji,
    String? imagePath,
  }) async {
    await _guard.ensureCanFullyEdit();

    final newKey = newName.trim();
    if (newKey.isEmpty) {
      throw const ValidationFailure('El nombre de la categoría es obligatorio');
    }

    final oldKey = category.key;

    // No permitir renombrar a una clave que ya ocupa otra categoría: el
    // datasource nunca debe sobrescribir silenciosamente una entrada con otra.
    if (newKey.trim().toLowerCase() != oldKey.trim().toLowerCase() &&
        await _categories.exists(newKey)) {
      throw const ValidationFailure(
          'Ya existe una categoría con ese nombre');
    }

    await _categories.update(
      currentKey: oldKey,
      category: CategoryItem(key: newKey, emoji: emoji, imagePath: imagePath),
    );

    final products = await _products.getAll();
    for (final product in products.where((p) => p.categoryKey == oldKey)) {
      product.categoryKey = newKey;
      await _products.upsert(product);
    }
  }
}
