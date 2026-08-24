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

  Future<void> put(ProductModel model, {String? key}) async {
    await _box.put(key ?? model.nameKey.trim(), model);
  }

  /// Reemplaza por completo el contenido local con [models]
  /// (usado cuando un colaborador recibe la foto inicial del dueño).
  Future<void> replaceAll(List<ProductModel> models) async {
    final map = <String, ProductModel>{
      for (final model in models) model.nameKey.trim(): model,
    };
    await _box.clear();
    await _box.putAll(map);
  }

  Future<void> deleteByKey(String key) async {
    if (_box.containsKey(key)) {
      await _box.delete(key);
    }
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
