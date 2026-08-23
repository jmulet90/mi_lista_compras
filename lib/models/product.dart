import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 1)
class Product extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String categoryKey;

  @HiveField(2)
  bool isBought;

  @HiveField(3)
  int quantity;

  Product({
    required this.name,
    required this.categoryKey,
    this.isBought = false,
    this.quantity = 1,
  });
}