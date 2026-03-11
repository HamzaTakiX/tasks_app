// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalModelAdapter extends TypeAdapter<JournalModel> {
  @override
  final int typeId = 2;

  @override
  JournalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalModel(
      id: fields[0] as String,
      dateString: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      mood: fields[4] as String,
      category: fields[5] as String,
      linkedTaskIds: (fields[6] as List).cast<String>(),
      imagePaths: (fields[7] as List).cast<String>(),
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, JournalModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateString)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.linkedTaskIds)
      ..writeByte(7)
      ..write(obj.imagePaths)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
