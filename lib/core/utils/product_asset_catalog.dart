import 'package:flutter/services.dart';

/// Catálogo de PNG de producto organizados en carpetas por categoría:
///
///     assets/images/emojis/products/<categoria>/<producto>.png
///
/// `<categoria>` es la clave canónica de la categoría en snake_case
/// ('Fruits' -> fruits/, 'Personal care' -> personal_care/).
///
/// Los PNG se descubren leyendo el AssetManifest, así que basta con
/// soltar archivos nuevos en la carpeta (y declararla en pubspec.yaml)
/// para que aparezcan en el selector sin tocar código.
class ProductAssetCatalog {
  ProductAssetCatalog._();

  static final ProductAssetCatalog instance = ProductAssetCatalog._();

  static const String _base = 'assets/images/emojis/products/';

  final Map<String, List<String>> _byCategory = {};
  bool _loaded = false;

  /// 'Personal care' -> 'personal_care'
  static String folderKeyFor(String categoryKey) =>
      categoryKey.trim().toLowerCase().replaceAll(' ', '_');

  /// Carga (una vez) el inventario de PNG desde el AssetManifest.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final asset in manifest.listAssets()) {
        if (!asset.startsWith(_base) || !asset.endsWith('.png')) continue;
        final rest = asset.substring(_base.length);
        final slash = rest.indexOf('/');
        if (slash <= 0 || slash == rest.length - 1) continue;
        final folder = rest.substring(0, slash);
        _byCategory.putIfAbsent(folder, () => []).add(asset);
      }
      for (final list in _byCategory.values) {
        list.sort();
      }
    } catch (_) {
      // Sin manifiesto: el catálogo queda vacío y la UI cae a emojis.
    }
  }

  /// Rutas completas de los PNG disponibles para esa categoría.
  List<String> pngsFor(String categoryKey) =>
      _byCategory[folderKeyFor(categoryKey)] ?? const [];

  bool hasPngs(String categoryKey) => pngsFor(categoryKey).isNotEmpty;
}
