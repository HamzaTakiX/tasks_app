// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 1;

  @override
  HabitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitModel(
      id: fields[0] as String,
      title: fields[1] as String,
      streakCount: fields[2] as int,
      lastCompletedDate: fields[3] as DateTime?,
      colorValue: fields[4] as int,
      iconCodePoint: fields[5] as int,
      frequency: fields[6] as String,
      bestStreak: fields[7] as int,
      completedDates: (fields[8] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.streakCount)
      ..writeByte(3)
      ..write(obj.lastCompletedDate)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.iconCodePoint)
      ..writeByte(6)
      ..write(obj.frequency)
      ..writeByte(7)
      ..write(obj.bestStreak)
      ..writeByte(8)
      ..write(obj.completedDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
