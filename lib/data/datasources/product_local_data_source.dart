import 'package:hive_flutter/hive_flutter.dart';

import '../models/product_model.dart';

/// Acceso a Hive para productos. Encapsula claves, deduplicación y eventos.
class ProductLocalDataSource {
  ProductLocalDataSource(this._box);

  static const String boxName = 'productsBox';

  final Box<ProductModel> _box;

  List<ProductModel> getAll() {
    final unique = <String, ProductModel>{};
    for (final model in _box.values) {
      unique[model.uniqueKey] = model;
    }
    return unique.values.toList();
  }

  Stream<List<ProductModel>> watchAll() async* {
    yield getAll();
    await for (final _ in _box.watch()) {
      yield getAll();
    }
  }

  ProductModel? getByKey(String key) {
    final exact = _box.get(key);
    if (exact != null) return exact;
    // Fallback case-insensitive: claves legadas o escritas con mayúsculas
    // (p. ej. la lista de un colaborador poblada por replaceAll antiguo).
    final lower = key.trim().toLowerCase();
    for (final model in _box.values) {
      if (model.nameKey.trim().toLowerCase() == lower) return model;
    }
    return null;
  }

  Future<void> put(ProductModel model, {String? key}) async {
    await _box.put(key ?? model.nameKey.trim().toLowerCase(), model);
  }

  /// Reemplaza por completo el contenido local con [models]
  /// de forma atómica para que el watch() nunca emita una lista vacía.
  /// Las claves siempre se normalizan a minúsculas para que borrados y
  /// actualizaciones (que usan nameKey en minúsculas) acierten siempre.
  Future<void> replaceAll(List<ProductModel> models) async {
    if (models.isEmpty) return;
    final map = <String, ProductModel>{
      for (final model in models)
        model.nameKey.trim().toLowerCase(): model,
    };
    // Primero se ponen los nuevos (sobreescribe existentes).
    await _box.putAll(map);
    // Luego se eliminan las claves antiguas que ya no están (realiza limpia
    // de claves en mayúsculas/legadas que representen el mismo producto o
    // productos que ya no existen en la nube).
    final newKeys = map.keys.toSet();
    final toDelete = _box.keys
        .where((k) => !newKeys.contains(k))
        .toList();
    if (toDelete.isNotEmpty) await _box.deleteAll(toDelete);
  }

  Future<void> deleteByKey(String key) async {
    final lower = key.trim().toLowerCase();
    if (containsKey(lower)) {
      await _box.delete(lower);
      return;
    }
    final stale = _box.keys
        .where((k) =>
            _box.get(k)?.nameKey.trim().toLowerCase() == lower)
        .toList();
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }

  /// Elimina localmente todos los modelos que cumplan el test.
  Future<void> deleteWhere(bool Function(ProductModel model) test) async {
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final model = _box.get(key);
      if (model != null && test(model)) {
        keysToDelete.add(key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
  }

  bool containsKey(String key) => _box.containsKey(key);

  bool get isEmpty => _box.isEmpty;
}
