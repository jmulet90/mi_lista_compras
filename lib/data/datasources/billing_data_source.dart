import 'package:in_app_purchase/in_app_purchase.dart';

/// Envoltorio fino sobre el plugin in_app_purchase para poder mokearlo
/// en tests. No contiene lógica de negocio.
class BillingDataSource {
  BillingDataSource({InAppPurchase? api})
      : _api = api ?? InAppPurchase.instance;

  final InAppPurchase _api;

  Stream<List<PurchaseDetails>> get purchaseStream => _api.purchaseStream;

  Future<bool> isAvailable() => _api.isAvailable();

  Future<List<ProductDetails>> queryProduct(String productId) async {
    final response = await _api.queryProductDetails({productId});
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) =>
      _api.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  Future<void> restore() => _api.restorePurchases();

  Future<void> complete(PurchaseDetails purchase) =>
      purchase.pendingCompletePurchase
          ? _api.completePurchase(purchase)
          : Future.value();
}
