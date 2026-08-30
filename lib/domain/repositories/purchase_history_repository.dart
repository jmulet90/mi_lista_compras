import '../entities/purchase_event.dart';

/// Historial local de compras confirmadas, usado para aprender el
/// comportamiento del usuario (frecuencia de compra, productos habituales).
/// No se sincroniza a la nube: es un dato de comportamiento por dispositivo.
abstract class PurchaseHistoryRepository {
  Future<void> record(PurchaseEvent event);

  Future<List<PurchaseEvent>> getAll();

  Stream<List<PurchaseEvent>> watchAll();

  Future<void> clear();
}
