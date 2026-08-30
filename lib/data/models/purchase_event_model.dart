import 'package:hive/hive.dart';

import '../../domain/entities/purchase_event.dart';

part 'purchase_event_model.g.dart';

@HiveType(typeId: 2)
class PurchaseEventModel extends HiveObject {
  @HiveField(0)
  String productKey;

  @HiveField(1)
  String categoryKey;

  @HiveField(2)
  String? subcategory;

  @HiveField(3)
  double? quantity;

  @HiveField(4)
  String? unit;

  @HiveField(5)
  DateTime purchasedAt;

  PurchaseEventModel({
    required this.productKey,
    required this.categoryKey,
    this.subcategory,
    this.quantity,
    this.unit,
    required this.purchasedAt,
  });

  factory PurchaseEventModel.fromEntity(PurchaseEvent event) {
    return PurchaseEventModel(
      productKey: event.productKey,
      categoryKey: event.categoryKey,
      subcategory: event.subcategory,
      quantity: event.quantity,
      unit: event.unit,
      purchasedAt: event.purchasedAt,
    );
  }

  PurchaseEvent toEntity() {
    return PurchaseEvent(
      productKey: productKey,
      categoryKey: categoryKey,
      subcategory: subcategory,
      quantity: quantity,
      unit: unit,
      purchasedAt: purchasedAt,
    );
  }
}
