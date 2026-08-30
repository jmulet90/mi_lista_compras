import '../entities/product.dart';
import '../entities/purchase_event.dart';
import '../repositories/product_repository.dart';
import '../repositories/purchase_history_repository.dart';
import '../services/access_guard.dart';

/// Cambia un producto entre la lista de compra y la despensa.
///
/// Cuando la transición es "estaba por comprar -> pasó a despensa" se
/// interpreta como una compra confirmada y se registra en el historial local
/// (`PurchaseHistoryRepository`), que alimenta el recordatorio inteligente de
/// compras (`ShoppingReminderCoordinator`).
class ToggleProductUseCase {
  ToggleProductUseCase(this._products, this._guard, this._history);

  final ProductRepository _products;
  final AccessGuard _guard;
  final PurchaseHistoryRepository _history;

  Future<void> call(Product product) async {
    await _guard.ensureCanMoveItems();

    final wasToBuy = product.isToBuy;
    final quantityBeforeToggle = product.quantity;
    final unitBeforeToggle = product.unit;

    product.isToBuy = !product.isToBuy;

    if (!product.isToBuy) {
      product.quantity = null;
      product.unit = null;
    }

    await _products.upsert(product);

    if (wasToBuy && !product.isToBuy) {
      try {
        await _history.record(PurchaseEvent(
          productKey: product.nameKey,
          categoryKey: product.categoryKey,
          subcategory: product.subcategory,
          quantity: quantityBeforeToggle,
          unit: unitBeforeToggle,
          purchasedAt: DateTime.now(),
        ));
      } catch (_) {
        // El historial es una mejora opcional: nunca debe romper el toggle.
      }
    }
  }
}
