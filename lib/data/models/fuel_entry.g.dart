// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelEntryAdapter extends TypeAdapter<FuelEntry> {
  @override
  final int typeId = 2;

  @override
  FuelEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelEntry(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      odometerKm: fields[3] as double,
      liters: fields[4] as double,
      pricePerLiter: fields[5] as double,
      amount: fields[6] as double,
      fullTank: fields[7] as bool,
      notes: fields[8] as String?,
      currencyCode: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FuelEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.odometerKm)
      ..writeByte(4)
      ..write(obj.liters)
      ..writeByte(5)
      ..write(obj.pricePerLiter)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.fullTank)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.currencyCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
