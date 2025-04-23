// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EditResultAdapter extends TypeAdapter<EditResult> {
  @override
  final int typeId = 2;

  @override
  EditResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EditResult(
      id: fields[0] as String,
      requestId: fields[1] as String,
      imageId: fields[2] as String,
      editedImagePath: fields[3] as String,
      createdAt: fields[4] as DateTime,
      metadata: (fields[5] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, EditResult obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.requestId)
      ..writeByte(2)
      ..write(obj.imageId)
      ..writeByte(3)
      ..write(obj.editedImagePath)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
