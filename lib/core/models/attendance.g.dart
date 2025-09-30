// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 0;

  @override
  Attendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Attendance(
      localId: fields[0] as String?,
      serverId: fields[1] as String?,
      studentId: fields[2] as String,
      classId: fields[3] as String,
      markedAt: fields[4] as DateTime,
      markedBy: fields[5] as String,
      source: fields[6] as String,
      deviceUuid: fields[7] as String,
      rfidTag: fields[8] as String?,
      status: fields[9] as String,
      notes: fields[10] as String?,
      isSynced: fields[11] as bool,
      syncedAt: fields[12] as DateTime?,
      syncAttempts: fields[13] as int,
      lastSyncError: fields[14] as String?,
      latitude: fields[15] as double?,
      longitude: fields[16] as double?,
      sessionId: fields[17] as String?,
      createdAt: fields[18] as DateTime?,
      updatedAt: fields[19] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Attendance obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.localId)
      ..writeByte(1)
      ..write(obj.serverId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.classId)
      ..writeByte(4)
      ..write(obj.markedAt)
      ..writeByte(5)
      ..write(obj.markedBy)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.deviceUuid)
      ..writeByte(8)
      ..write(obj.rfidTag)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(12)
      ..write(obj.syncedAt)
      ..writeByte(13)
      ..write(obj.syncAttempts)
      ..writeByte(14)
      ..write(obj.lastSyncError)
      ..writeByte(15)
      ..write(obj.latitude)
      ..writeByte(16)
      ..write(obj.longitude)
      ..writeByte(17)
      ..write(obj.sessionId)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attendance _$AttendanceFromJson(Map<String, dynamic> json) => Attendance(
      localId: json['localId'] as String?,
      serverId: json['serverId'] as String?,
      studentId: json['studentId'] as String,
      classId: json['classId'] as String,
      markedAt: DateTime.parse(json['markedAt'] as String),
      markedBy: json['markedBy'] as String,
      source: json['source'] as String,
      deviceUuid: json['deviceUuid'] as String,
      rfidTag: json['rfidTag'] as String?,
      status: json['status'] as String? ?? 'present',
      notes: json['notes'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
      syncAttempts: (json['syncAttempts'] as num?)?.toInt() ?? 0,
      lastSyncError: json['lastSyncError'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sessionId: json['sessionId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AttendanceToJson(Attendance instance) =>
    <String, dynamic>{
      'localId': instance.localId,
      'serverId': instance.serverId,
      'studentId': instance.studentId,
      'classId': instance.classId,
      'markedAt': instance.markedAt.toIso8601String(),
      'markedBy': instance.markedBy,
      'source': instance.source,
      'deviceUuid': instance.deviceUuid,
      'rfidTag': instance.rfidTag,
      'status': instance.status,
      'notes': instance.notes,
      'isSynced': instance.isSynced,
      'syncedAt': instance.syncedAt?.toIso8601String(),
      'syncAttempts': instance.syncAttempts,
      'lastSyncError': instance.lastSyncError,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'sessionId': instance.sessionId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
