import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_center_repository.dart';
import '../localization/app_localizations.dart';
import '../screens/notification_center_screen.dart';
import 'premium_limits.dart';

/// Campanita de notificaciones para el `AppBar`: muestra un contador de no
/// leídas y abre el centro de notificaciones. La función completa (avisos
/// inteligentes) es Premium Plus; sin el plan se muestra el paywall.
class NotificationBellIcon extends StatelessWidget {
  const NotificationBellIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return StreamBuilder<List<AppNotification>>(
      stream: sl<NotificationCenterRepository>().watchAll(),
      builder: (context, snapshot) {
        final unread =
            (snapshot.data ?? const <AppNotification>[]).where((n) => !n.read).length;
        return IconButton(
          tooltip: t.notifications,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined),
              if (unread > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () async {
            if (!await PremiumLimits.canUsePremiumPlus(
              context,
              reason: t.notificationsRequirePlus,
            )) {
              return;
            }
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
            );
          },
        );
      },
    );
  }
}
