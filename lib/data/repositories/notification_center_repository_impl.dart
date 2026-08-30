import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_center_repository.dart';
import '../datasources/notification_center_local_data_source.dart';
import '../models/app_notification_model.dart';

class NotificationCenterRepositoryImpl implements NotificationCenterRepository {
  NotificationCenterRepositoryImpl(this._local);

  final NotificationCenterLocalDataSource _local;

  @override
  Stream<List<AppNotification>> watchAll() {
    return _local.watchAll().map((list) => list.map((m) => m.toEntity()).toList());
  }

  @override
  Future<List<AppNotification>> getAll() async {
    return _local.getAll().map((m) => m.toEntity()).toList();
  }

  @override
  Future<AppNotification?> getById(String id) async {
    return _local.getById(id)?.toEntity();
  }

  @override
  Future<void> upsert(AppNotification notification) async {
    await _local.put(AppNotificationModel.fromEntity(notification));
  }

  @override
  Future<void> markRead(String id) async {
    final existing = _local.getById(id);
    if (existing == null || existing.read) return;
    existing.read = true;
    await existing.save();
  }

  @override
  Future<void> markAllRead() async {
    for (final model in _local.getAll()) {
      if (!model.read) {
        model.read = true;
        await model.save();
      }
    }
  }

  @override
  Future<void> clear() => _local.clear();
}
