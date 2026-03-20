// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      date: fields[3] as DateTime,
      isCompleted: fields[4] as bool,
      time: fields[5] as DateTime?,
      iconCodePoint: fields[6] as int?,
      priority: fields[7] as String,
      note: fields[8] as String,
      repetition: fields[9] as String,
      subType: fields[10] as String,
      status: fields[11] as String,
      sessionsJson: fields[12] as String,
      repeatDaysJson: fields[13] as String?,
      taskTimesJson: fields[14] as String?,
      reminderOffset: fields[15] as int?,
      subTasksJson: fields[16] as String?,
      sortOrder: (fields[17] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.time)
      ..writeByte(6)
      ..write(obj.iconCodePoint)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.repetition)
      ..writeByte(10)
      ..write(obj.subType)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.sessionsJson)
      ..writeByte(13)
      ..write(obj.repeatDaysJson)
      ..writeByte(14)
      ..write(obj.taskTimesJson)
      ..writeByte(15)
      ..write(obj.reminderOffset)
      ..writeByte(16)
      ..write(obj.subTasksJson)
      ..writeByte(17)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
