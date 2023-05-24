// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogAdapter extends TypeAdapter<Log> {
  @override
  final int typeId = 3;

  @override
  Log read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Log(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      type: fields[2] as LogType,
      initiator: fields[3] as LogInitiator,
      payload: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Log obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.initiator)
      ..writeByte(4)
      ..write(obj.payload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogTypeAdapter extends TypeAdapter<LogType> {
  @override
  final int typeId = 1;

  @override
  LogType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogType.taskCreated;
      case 1:
        return LogType.taskDeleted;
      case 2:
        return LogType.taskStarted;
      case 3:
        return LogType.taskStopped;
      case 4:
        return LogType.updatedLocation;
      default:
        return LogType.taskCreated;
    }
  }

  @override
  void write(BinaryWriter writer, LogType obj) {
    switch (obj) {
      case LogType.taskCreated:
        writer.writeByte(0);
        break;
      case LogType.taskDeleted:
        writer.writeByte(1);
        break;
      case LogType.taskStarted:
        writer.writeByte(2);
        break;
      case LogType.taskStopped:
        writer.writeByte(3);
        break;
      case LogType.updatedLocation:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogInitiatorAdapter extends TypeAdapter<LogInitiator> {
  @override
  final int typeId = 2;

  @override
  LogInitiator read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogInitiator.user;
      case 1:
        return LogInitiator.system;
      default:
        return LogInitiator.user;
    }
  }

  @override
  void write(BinaryWriter writer, LogInitiator obj) {
    switch (obj) {
      case LogInitiator.user:
        writer.writeByte(0);
        break;
      case LogInitiator.system:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogInitiatorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
