import '../entities/category_item.dart';

abstract class CategoryRepository {
  Stream<List<CategoryItem>> watchAll();

  Future<List<CategoryItem>> getAll();

  Future<bool> exists(String key);

  Future<void> add(CategoryItem category);

  Future<void> update({
    required String currentKey,
    required CategoryItem category,
  });

  Future<void> delete(String key);

  /// Empieza a escuchar cambios remotos de categorías y los aplica al
  /// almacén local. Es idempotente.
  Future<void> startRemoteSync({bool fullRefresh = false});
}
