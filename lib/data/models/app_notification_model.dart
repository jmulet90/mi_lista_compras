import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/shopping_suggestion_item.dart';

part 'app_notification_model.g.dart';

@HiveType(typeId: 3)
class AppNotificationModel extends HiveObject {
  @HiveField(0)
  String id;

  /// Nombre del enum `AppNotificationType` (`shoppingReminder`, `generic`).
  @HiveField(1)
  String type;

  @HiveField(2)
  String title;

  @HiveField(3)
  String body;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  bool read;

  /// Lista de [ShoppingSuggestionItem] codificada en JSON. Se evita crear un
  /// nuevo typeId de Hive para un objeto anidado; es más simple y suficiente
  /// para una lista pequeña de sugerencias.
  @HiveField(6)
  String suggestionsJson;

  AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.suggestionsJson = '[]',
  });

  factory AppNotificationModel.fromEntity(AppNotification n) {
    final encoded = jsonEncode([
      for (final s in n.suggestions)
        {
          'productKey': s.productKey,
          'categoryKey': s.categoryKey,
          'quantity': s.quantity,
          'unit': s.unit,
          'frequency': s.frequency,
        },
    ]);
    return AppNotificationModel(
      id: n.id,
      type: n.type.name,
      title: n.title,
      body: n.body,
      createdAt: n.createdAt,
      read: n.read,
      suggestionsJson: encoded,
    );
  }

  AppNotification toEntity() {
    final rawList = (jsonDecode(suggestionsJson) as List).cast<Map<String, dynamic>>();
    return AppNotification(
      id: id,
      type: AppNotificationType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => AppNotificationType.generic,
      ),
      title: title,
      body: body,
      createdAt: createdAt,
      read: read,
      suggestions: [
        for (final r in rawList)
          ShoppingSuggestionItem(
            productKey: r['productKey'] as String,
            categoryKey: r['categoryKey'] as String,
            quantity: (r['quantity'] as num?)?.toDouble(),
            unit: r['unit'] as String?,
            frequency: (r['frequency'] as num?)?.toDouble() ?? 0,
          ),
      ],
    );
  }
}
