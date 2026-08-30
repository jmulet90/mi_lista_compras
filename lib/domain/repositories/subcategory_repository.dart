import '../entities/subcategory_item.dart';

/// Repositorio de subcategorías.
///
/// Una subcategoría pertenece a una categoría; los productos la referencian
/// por su nombre. Se persisten de forma local para que existan aunque aún no
/// tengan productos, conservando su visual (emoji o foto).
abstract class SubcategoryRepository {
  Stream<Map<String, List<SubcategoryItem>>> watchAll();

  Future<List<SubcategoryItem>> itemsFor(String categoryKey);

  Future<void> create(String categoryKey, SubcategoryItem item);

  Future<void> rename(String categoryKey, String from, SubcategoryItem to);

  Future<void> delete(String categoryKey, String name);
}