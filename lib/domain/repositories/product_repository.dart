import '../entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchAll();

  Future<List<Product>> getAll();

  /// Guarda el producto localmente usando su [Product.id] como clave
  /// y lo sincroniza con la nube.
  ///
  /// Si se proporciona [previousId] y es distinto del id actual, elimina
  /// el documento antiguo de la nube para evitar duplicados al renombrar.
  Future<void> upsert(Product product, {String? previousId});

  /// Elimina el producto por id (local y en la nube).
  Future<void> deleteById(String id);

  /// Elimina localmente todos los productos que cumplan el test
  /// (sin tocar la nube).
  Future<void> deleteWhere(bool Function(Product product) test);

  /// Empieza a escuchar cambios remotos y los aplica al almacén local.
  /// Es idempotente.
  Future<void> startRemoteSync({bool fullRefresh = false});
}
