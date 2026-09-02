import '../../core/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/access_guard.dart';

class AddProductUseCase {
  AddProductUseCase(this._products, this._guard, {String Function(String)? canonicalize})
      : _canonicalize = canonicalize ?? ((s) => s);

  final ProductRepository _products;
  final AccessGuard _guard;
  final String Function(String) _canonicalize;

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

    // Un producto es único por categoría + nombre canónico (resuelto contra el
    // diccionario), sea cual sea la pestaña (compra/stock): el almacén local y
    // Firestore usan el nameKey como clave, así que dos filas con el mismo
    // nombre no pueden coexistir sin pisotearse.
    final catKey = categoryKey.trim().toLowerCase();
    final canonicalName = _canonicalize(nameKey).trim().toLowerCase();
    final existing = await _products.getAll();
    final hasDuplicate = existing.any(
      (p) =>
          p.categoryKey.trim().toLowerCase() == catKey &&
          _canonicalize(p.nameKey).trim().toLowerCase() == canonicalName,
    );
    if (hasDuplicate) {
      throw const ValidationFailure(
          'Ya existe un producto con ese nombre en esta categoría');
    }

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
