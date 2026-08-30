import '../../domain/entities/purchase_event.dart';
import '../../domain/repositories/purchase_history_repository.dart';
import '../datasources/purchase_history_local_data_source.dart';
import '../models/purchase_event_model.dart';

class PurchaseHistoryRepositoryImpl implements PurchaseHistoryRepository {
  PurchaseHistoryRepositoryImpl(this._local);

  final PurchaseHistoryLocalDataSource _local;

  @override
  Future<void> record(PurchaseEvent event) async {
    await _local.add(PurchaseEventModel.fromEntity(event));
  }

  @override
  Future<List<PurchaseEvent>> getAll() async {
    return _local.getAll().map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<PurchaseEvent>> watchAll() {
    return _local.watchAll().map((list) => list.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> clear() => _local.clear();
}
