// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 0;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      nameKey: fields[0] as String,
      categoryKey: fields[1] as String,
      isToBuy: fields[2] as bool,
      emoji: fields[3] as String?,
      imagePath: fields[4] as String?,
      isBuyScreen: fields[5] as bool,
      imageId: fields[6] as String?,
      quantity: fields[7] as double?,
      unit: fields[8] as String?,
      subcategory: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.nameKey)
      ..writeByte(1)
      ..write(obj.categoryKey)
      ..writeByte(2)
      ..write(obj.isToBuy)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.isBuyScreen)
      ..writeByte(6)
      ..write(obj.imageId)
      ..writeByte(7)
      ..write(obj.quantity)
      ..writeByte(8)
      ..write(obj.unit)
      ..writeByte(9)
      ..write(obj.subcategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
