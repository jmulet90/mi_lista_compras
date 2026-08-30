import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_center_repository.dart';
import '../localization/app_localizations.dart';
import '../widgets/dialog_kit.dart';
import 'shopping_suggestion_screen.dart';

/// Historial local de avisos (leídos o no). Hoy solo existe el recordatorio
/// inteligente de compras, pero la pantalla ya soporta cualquier
/// `AppNotificationType` futuro.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notifications),
        actions: [
          IconButton(
            tooltip: t.markAllRead,
            icon: const Icon(Icons.done_all),
            onPressed: () => sl<NotificationCenterRepository>().markAllRead(),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: sl<NotificationCenterRepository>().watchAll(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <AppNotification>[];
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 72,
                      color: isDark ? Colors.white24 : Colors.blueGrey.shade200,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.notificationCenterEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final n = items[index];
              return _NotificationTile(notification: n);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = !notification.read;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.75),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: unread
              ? DialogAccents.emerald.withValues(alpha: 0.35)
              : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.grey.shade200),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await sl<NotificationCenterRepository>().markRead(notification.id);
          if (!context.mounted) return;
          if (notification.type == AppNotificationType.shoppingReminder) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShoppingSuggestionScreen(notificationId: notification.id),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DialogAccents.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: DialogAccents.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14.5,
                        color: isDark ? Colors.grey.shade100 : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeDate(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: DialogAccents.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${date.day}/${date.month}/${date.year}';
  }
}
