import 'shopping_suggestion_item.dart';

/// Tipo de notificación interna. Hoy solo existe el recordatorio de compras
/// inteligente, pero el enum deja espacio para futuros tipos (colaboradores,
/// premium, etc.) sin romper el almacenamiento existente.
enum AppNotificationType {
  shoppingReminder,
  generic,
}

/// Entrada del centro de notificaciones in-app. Vive 100% en el dispositivo
/// (Hive), independiente de si el push del sistema llegó a mostrarse o no.
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.suggestions = const [],
  });

  /// Identificador estable (se usa también como payload del push del
  /// sistema para poder abrir el detalle correcto al tocarlo).
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  /// Productos sugeridos asociados (solo aplica a [AppNotificationType.shoppingReminder]).
  final List<ShoppingSuggestionItem> suggestions;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        suggestions: suggestions,
      );
}
