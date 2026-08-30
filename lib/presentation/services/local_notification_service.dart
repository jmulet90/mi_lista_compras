import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/logger.dart';

/// Envoltorio de `flutter_local_notifications`: inicialización, canal
/// Android, zona horaria y programación del recordatorio de compras.
///
/// Todo lo referido a notificaciones del sistema (push locales, no hay
/// backend) vive acá. El centro de notificaciones in-app es un concepto
/// aparte (`NotificationCenterRepository`) que no depende de este servicio.
class LocalNotificationService {
  LocalNotificationService({this._logger = const AppLogger()});

  final AppLogger _logger;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String reminderChannelId = 'shopping_reminders';
  static const String reminderChannelName = 'Recordatorios de compras';
  static const String reminderChannelDescription =
      'Avisos inteligentes de cuándo conviene ir de compras';
  static const int reminderNotificationId = 9001;

  /// Payload (id de `AppNotification`) de la última notificación tocada por
  /// el usuario, ya sea con la app abierta o al abrirla desde cero. La app
  /// escucha este valor para navegar al detalle correspondiente.
  final ValueNotifier<String?> tappedPayload = ValueNotifier<String?>(null);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      tz_data.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      _logger.info('No se pudo resolver la zona horaria local: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        tappedPayload.value = response.payload;
      },
    );

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      reminderChannelId,
      reminderChannelName,
      description: reminderChannelDescription,
      importance: Importance.high,
    ));

    // Si la app se abrió justo al tocar una notificación (estaba cerrada),
    // captura ese payload para poder navegar al detalle también en ese caso.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      tappedPayload.value = launchDetails!.notificationResponse?.payload;
    }
  }

  Future<void> scheduleShoppingReminder({
    required DateTime when,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.zonedSchedule(
        reminderNotificationId,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannelId,
            reminderChannelName,
            channelDescription: reminderChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // Programar el recordatorio es una mejora opcional: si el SO lo
      // rechaza (permiso denegado, OEM restrictivo, etc.) no debe afectar
      // el resto de la app.
      _logger.info('No se pudo programar el recordatorio de compras: $e');
    }
  }

  Future<void> cancelShoppingReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(reminderNotificationId);
  }
}
