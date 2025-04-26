// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImageStatusAdapter extends TypeAdapter<ImageStatus> {
  @override
  final int typeId = 0;

  @override
  ImageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ImageStatus.pending;
      case 1:
        return ImageStatus.uploading;
      case 2:
        return ImageStatus.uploaded;
      case 3:
        return ImageStatus.processing;
      case 4:
        return ImageStatus.completed;
      case 5:
        return ImageStatus.failed;
      default:
        return ImageStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ImageStatus obj) {
    switch (obj) {
      case ImageStatus.pending:
        writer.writeByte(0);
        break;
      case ImageStatus.uploading:
        writer.writeByte(1);
        break;
      case ImageStatus.uploaded:
        writer.writeByte(2);
        break;
      case ImageStatus.processing:
        writer.writeByte(3);
        break;
      case ImageStatus.completed:
        writer.writeByte(4);
        break;
      case ImageStatus.failed:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
