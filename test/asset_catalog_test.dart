import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buy_and_stock/core/utils/product_asset_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el catalogo descubre los PNG por carpeta', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all =
        manifest.listAssets().where((a) => a.contains('emojis/products'));
    // ignore: avoid_print
    print('ASSETS products: ${all.toList()}');

    await ProductAssetCatalog.instance.ensureLoaded();
    // ignore: avoid_print
    print('fruits: ${ProductAssetCatalog.instance.pngsFor('Fruits')}');
    expect(ProductAssetCatalog.instance.pngsFor('Fruits'), isNotEmpty);
  });
}
