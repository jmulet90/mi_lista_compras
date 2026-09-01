import '../../core/failures.dart';
import '../entities/category_item.dart';
import '../repositories/category_repository.dart';
import '../services/access_guard.dart';

class AddCategoryUseCase {
  AddCategoryUseCase(this._categories, this._guard);

  final CategoryRepository _categories;
  final AccessGuard _guard;

  Future<void> call({
    required String name,
    String? emoji,
    String? imagePath,
  }) async {
    await _guard.ensureCanFullyEdit();

    final key = name.trim();
    if (key.isEmpty) {
      throw const ValidationFailure('El nombre de la categoría es obligatorio');
    }
    if (await _categories.exists(key)) {
      throw const ValidationFailure(
          'Ya existe una categoría con ese nombre');
    }

    await _categories.add(CategoryItem(
      key: key,
      emoji: emoji ?? '📦',
      imagePath: imagePath,
    ));
  }
}
