// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssignmentAdapter extends TypeAdapter<Assignment> {
  @override
  final int typeId = 0;

  @override
  Assignment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Assignment(
      id: fields[0] as String,
      userId: fields[1] as String,
      taskId: fields[2] as String,
      siteId: fields[3] as String,
      schedule: fields[4] as Schedule,
      windowStart: fields[5] as Timestamp?,
      windowEnd: fields[6] as Timestamp?,
      status: fields[7] as String,
      blockedReason: fields[8] as String?,
      evidence: fields[9] as Evidence?,
      lastUpdateAt: fields[10] as Timestamp?,
      createdAt: fields[11] as Timestamp?,
    );
  }

  @override
  void write(BinaryWriter writer, Assignment obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.taskId)
      ..writeByte(3)
      ..write(obj.siteId)
      ..writeByte(4)
      ..write(obj.schedule)
      ..writeByte(5)
      ..write(obj.windowStart)
      ..writeByte(6)
      ..write(obj.windowEnd)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.blockedReason)
      ..writeByte(9)
      ..write(obj.evidence)
      ..writeByte(10)
      ..write(obj.lastUpdateAt)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleAdapter extends TypeAdapter<Schedule> {
  @override
  final int typeId = 1;

  @override
  Schedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Schedule(
      at: fields[0] as Timestamp?,
      times: (fields[1] as List?)?.cast<String>(),
      daysOfWeek: (fields[2] as List?)?.cast<int>(),
      dateRange: fields[3] as DateRange?,
    );
  }

  @override
  void write(BinaryWriter writer, Schedule obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.at)
      ..writeByte(1)
      ..write(obj.times)
      ..writeByte(2)
      ..write(obj.daysOfWeek)
      ..writeByte(3)
      ..write(obj.dateRange);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EvidenceAdapter extends TypeAdapter<Evidence> {
  @override
  final int typeId = 2;

  @override
  Evidence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Evidence(
      storagePath: fields[0] as String?,
      url: fields[1] as String?,
      takenAt: fields[2] as Timestamp?,
    );
  }

  @override
  void write(BinaryWriter writer, Evidence obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.storagePath)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.takenAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
