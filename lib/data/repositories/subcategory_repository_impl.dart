import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/subcategory_item.dart';
import '../../domain/repositories/subcategory_repository.dart';

/// Implementación local de [SubcategoryRepository] sobre una caja Hive de
/// cadenas. Cada entrada almacena el nombre y su visual en JSON con la clave
/// `subcat__<categoria>__<nombre>` (ambas normalizadas a minúsculas):
/// `{"n": nombre, "e": emoji, "p": imagePath}`. Los valores legados que solo
/// contienen el nombre plano también se leen.
///
/// No se sincroniza con la nube: la asignación real vive en el `subcategory`
/// de cada producto (que sí se sincroniza). Esta caja solo hace que una
/// subcategoría recién creada exista aunque aún no tenga productos.
class SubcategoryRepositoryImpl implements SubcategoryRepository {
  SubcategoryRepositoryImpl(this._box);

  final Box<String> _box;

  static const String _prefix = 'subcat__';

  static String _key(String categoryKey, String name) =>
      '$_prefix${categoryKey.trim().toLowerCase()}__${name.trim().toLowerCase()}';

  static String _encode(SubcategoryItem item) => jsonEncode({
        'n': item.name,
        if (item.emoji != null) 'e': item.emoji,
        if (item.imagePath != null) 'p': item.imagePath,
      });

  static SubcategoryItem _decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final name = map['n'] as String?;
      if (name != null) {
        return SubcategoryItem(
          name: name,
          emoji: map['e'] as String?,
          imagePath: map['p'] as String?,
        );
      }
    } catch (_) {}
    return SubcategoryItem(name: raw);
  }

  Map<String, List<SubcategoryItem>> _all() {
    final map = <String, List<SubcategoryItem>>{};
    for (final entry in _box.toMap().entries) {
      final key = entry.key;
      if (!key.startsWith(_prefix)) continue;
      final parts = key.split('__');
      if (parts.length != 3) continue;
      map
          .putIfAbsent(parts[1], () => [])
          .add(_decode(entry.value));
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return map;
  }

  @override
  Stream<Map<String, List<SubcategoryItem>>> watchAll() async* {
    yield _all();
    await for (final _ in _box.watch()) {
      yield _all();
    }
  }

  @override
  Future<List<SubcategoryItem>> itemsFor(String categoryKey) async {
    final normalized = categoryKey.trim().toLowerCase();
    return _all()[normalized] ?? const [];
  }

  @override
  Future<void> create(String categoryKey, SubcategoryItem item) async {
    await _box.put(_key(categoryKey, item.name), _encode(item));
  }

  @override
  Future<void> rename(String categoryKey, String from, SubcategoryItem to) async {
    final key = _key(categoryKey, from);
    final old = _box.get(key);
    if (old == null) return;
    await _box.delete(key);
    await _box.put(_key(categoryKey, to.name), _encode(to));
  }

  @override
  Future<void> delete(String categoryKey, String name) async {
    await _box.delete(_key(categoryKey, name));
  }
}