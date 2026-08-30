import '../entities/app_notification.dart';

/// Centro de notificaciones in-app: historial local de avisos (leídos o no),
/// independiente de las notificaciones push del sistema operativo.
abstract class NotificationCenterRepository {
  Stream<List<AppNotification>> watchAll();

  Future<List<AppNotification>> getAll();

  Future<AppNotification?> getById(String id);

  Future<void> upsert(AppNotification notification);

  Future<void> markRead(String id);

  Future<void> markAllRead();

  Future<void> clear();
}
