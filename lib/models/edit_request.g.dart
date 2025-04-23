// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EditRequestAdapter extends TypeAdapter<EditRequest> {
  @override
  final int typeId = 1;

  @override
  EditRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EditRequest(
      id: fields[0] as String,
      imageId: fields[1] as String,
      instruction: fields[2] as String,
      markers: (fields[3] as List)
          .map((dynamic e) => (e as Map).cast<String, double>())
          .toList(),
      createdAt: fields[4] as DateTime,
      status: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EditRequest obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageId)
      ..writeByte(2)
      ..write(obj.instruction)
      ..writeByte(3)
      ..write(obj.markers)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
