import 'package:hive_flutter/hive_flutter.dart';

import '../models/category_model.dart';

/// Acceso a Hive para categorías.
class CategoryLocalDataSource {
  CategoryLocalDataSource(this._box);

  static const String boxName = 'categoriesBox';

  final Box<CategoryModel> _box;

  List<CategoryModel> getAll() => _box.values.toList();

  Stream<List<CategoryModel>> watchAll() async* {
    yield getAll();
    await for (final _ in _box.watch()) {
      yield getAll();
    }
  }

  bool exists(String key) {
    final lower = key.trim().toLowerCase();
    return _box.values.any((c) => c.key.trim().toLowerCase() == lower);
  }

  Future<void> add(CategoryModel model) async {
    if (exists(model.key)) return;
    await _box.add(model);
  }

  /// Guarda la categoría usando su clave como clave de caja
  /// (entradas sincronizadas con la nube).
  Future<void> put(CategoryModel model) async {
    await _removeDuplicateSlots(model.key);
    await _box.put(model.key, model);
  }

  /// Reemplaza por completo el contenido local con [models]
  /// de forma atómica para que el watch() nunca emita una lista vacía.
  Future<void> replaceAll(List<CategoryModel> models) async {
    if (models.isEmpty) return;
    final map = <String, CategoryModel>{
      for (final model in models) model.key: model,
    };
    // Primero se ponen los nuevos (sobreescribe existentes).
    await _box.putAll(map);
    // Luego se eliminan las claves antiguas que ya no están.
    final newKeys = map.keys.toSet();
    final toDelete = _box.keys.where((k) => !newKeys.contains(k)).toList();
    if (toDelete.isNotEmpty) await _box.deleteAll(toDelete);
  }

  /// Actualiza la entrada identificada por [currentKey] conservando su
  /// posición cuando es posible; si cambió la clave, reubica el registro.
  Future<bool> update({
    required String currentKey,
    required CategoryModel model,
  }) async {
    for (final slot in _box.keys.toList()) {
      final entry = _box.get(slot);
      if (entry == null || !_sameKey(entry.key, currentKey)) continue;

      entry
        ..key = model.key
        ..emoji = model.emoji
        ..imagePath = model.imagePath;

      // Si la caja usaba la clave antigua como clave física (entradas
      // sincronizadas), reubicamos para evitar duplicados.
      final derivedSlot =
          slot is String && !_sameKey(slot, model.key);
      if (derivedSlot) {
        await _box.delete(slot);
        await _box.put(model.key, entry);
      } else {
        await entry.save();
      }
      return true;
    }
    return false;
  }

  Future<void> delete(String key) async {
    for (final existing in _box.values) {
      if (_sameKey(existing.key, key)) {
        await existing.delete();
        return;
      }
    }
  }

  bool get isEmpty => _box.isEmpty;

  Future<void> addAll(List<CategoryModel> models) async {
    await _box.addAll(models);
  }

  Future<void> _removeDuplicateSlots(String key) async {
    for (final existing in _box.values.toList()) {
      if (_sameKey(existing.key, key)) {
        await existing.delete();
        return;
      }
    }
  }

  bool _sameKey(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();
}
