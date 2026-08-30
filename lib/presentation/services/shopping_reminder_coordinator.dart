import 'dart:async';

import '../../core/di.dart';
import '../../data/bootstrap/app_initializer.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/purchase_event.dart';
import '../../domain/repositories/notification_center_repository.dart';
import '../../domain/repositories/purchase_history_repository.dart';
import '../../domain/services/shopping_pattern_analyzer.dart';
import '../localization/app_localizations.dart';
import '../widgets/premium_limits.dart';
import 'local_notification_service.dart';

/// Une las piezas del recordatorio inteligente de compras:
/// [PurchaseHistoryRepository] (qué compró y cuándo) + [ShoppingPatternAnalyzer]
/// (cuándo va a volver a comprar y qué) + [LocalNotificationService] (avisa
/// por el sistema) + [NotificationCenterRepository] (queda en el historial
/// in-app). Es una función Premium Plus: sin el plan no programa nada.
class ShoppingReminderCoordinator {
  ShoppingReminderCoordinator({
    required PurchaseHistoryRepository history,
    required NotificationCenterRepository center,
    required LocalNotificationService notifications,
    ShoppingPatternAnalyzer analyzer = const ShoppingPatternAnalyzer(),
  })  : _history = history,
        _center = center,
        _notifications = notifications,
        _analyzer = analyzer;

  final PurchaseHistoryRepository _history;
  final NotificationCenterRepository _center;
  final LocalNotificationService _notifications;
  final ShoppingPatternAnalyzer _analyzer;

  StreamSubscription<List<PurchaseEvent>>? _sub;

  /// Empieza a escuchar el historial: recalcula automáticamente cada vez que
  /// se registra una nueva compra (y una vez de entrada, con lo que ya haya).
  void start() {
    _sub ??= _history.watchAll().listen((_) => refresh());
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> refresh() async {
    if (!PremiumLimits.isPremiumPlusEffectiveSync) {
      await _notifications.cancelShoppingReminder();
      return;
    }

    final events = await _history.getAll();
    final prediction = _analyzer.analyze(events);
    if (prediction == null || prediction.items.isEmpty) {
      await _notifications.cancelShoppingReminder();
      return;
    }

    final t = _localizations();
    final day = prediction.nextDate;
    final notificationId = 'shopping_reminder_${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';

    final itemNames = prediction.items.take(4).map((i) => t.getProductName(i.productKey)).toList();
    final extra = prediction.items.length - itemNames.length;
    final itemsText = extra > 0
        ? '${itemNames.join(', ')} y $extra más'
        : itemNames.join(', ');

    final title = t.shoppingReminderTitle;
    final body = t.shoppingReminderBody(itemsText);

    await _notifications.scheduleShoppingReminder(
      when: prediction.nextDate,
      title: title,
      body: body,
      payload: notificationId,
    );

    final existing = await _center.getById(notificationId);
    await _center.upsert(AppNotification(
      id: notificationId,
      type: AppNotificationType.shoppingReminder,
      title: title,
      body: body,
      createdAt: existing?.createdAt ?? DateTime.now(),
      read: existing?.read ?? false,
      suggestions: prediction.items,
    ));
  }

  AppLocalizations _localizations() {
    try {
      final code = sl<AppInitializer>().settings.get('language') as String? ?? 'es';
      return AppLocalizations(AppLocalizations.isSupported(code) ? code : 'es');
    } catch (_) {
      return AppLocalizations('es');
    }
  }
}
