// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceEntryAdapter extends TypeAdapter<ServiceEntry> {
  @override
  final int typeId = 3;

  @override
  ServiceEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceEntry(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      odometerKm: fields[3] as double,
      description: fields[4] as String,
      totalAmount: fields[5] as double,
      invoicePhotoPath: fields[6] as String?,
      notes: fields[7] as String?,
      currencyCode: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.odometerKm)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.totalAmount)
      ..writeByte(6)
      ..write(obj.invoicePhotoPath)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.currencyCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
