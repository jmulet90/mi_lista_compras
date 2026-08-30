import 'package:hive/hive.dart';

import '../models/purchase_event_model.dart';

/// Fuente local (Hive) del historial de compras. Es un log append-only: cada
/// registro es un evento independiente, sin clave natural, por eso usa
/// claves autoincrementales de Hive (`box.add`).
class PurchaseHistoryLocalDataSource {
  PurchaseHistoryLocalDataSource(this._box);

  static const String boxName = 'purchaseHistoryBox';

  final Box<PurchaseEventModel> _box;

  List<PurchaseEventModel> getAll() => _box.values.toList();

  Stream<List<PurchaseEventModel>> watchAll() async* {
    yield getAll();
    await for (final _ in _box.watch()) {
      yield getAll();
    }
  }

  Future<void> add(PurchaseEventModel model) async {
    await _box.add(model);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
