// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseEventModelAdapter extends TypeAdapter<PurchaseEventModel> {
  @override
  final int typeId = 2;

  @override
  PurchaseEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseEventModel(
      productKey: fields[0] as String,
      categoryKey: fields[1] as String,
      subcategory: fields[2] as String?,
      quantity: fields[3] as double?,
      unit: fields[4] as String?,
      purchasedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseEventModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.productKey)
      ..writeByte(1)
      ..write(obj.categoryKey)
      ..writeByte(2)
      ..write(obj.subcategory)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.purchasedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
