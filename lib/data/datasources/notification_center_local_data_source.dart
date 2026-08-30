import 'package:hive/hive.dart';

import '../models/app_notification_model.dart';

/// Fuente local (Hive) del centro de notificaciones in-app. A diferencia del
/// historial de compras, cada notificación tiene un id propio (clave de la
/// caja) para poder actualizarla (marcar leída) o reemplazarla.
class NotificationCenterLocalDataSource {
  NotificationCenterLocalDataSource(this._box);

  static const String boxName = 'notificationCenterBox';

  final Box<AppNotificationModel> _box;

  List<AppNotificationModel> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<AppNotificationModel>> watchAll() async* {
    yield getAll();
    await for (final _ in _box.watch()) {
      yield getAll();
    }
  }

  AppNotificationModel? getById(String id) => _box.get(id);

  Future<void> put(AppNotificationModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
