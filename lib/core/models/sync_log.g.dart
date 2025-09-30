// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncLogAdapter extends TypeAdapter<SyncLog> {
  @override
  final int typeId = 5;

  @override
  SyncLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncLog(
      id: fields[0] as String,
      syncType: fields[1] as String,
      operation: fields[2] as String,
      status: fields[3] as String,
      recordsAttempted: fields[4] as int,
      recordsSucceeded: fields[5] as int,
      recordsFailed: fields[6] as int,
      startedAt: fields[7] as DateTime?,
      completedAt: fields[8] as DateTime?,
      errorMessage: fields[9] as String?,
      errorDetails: (fields[10] as Map?)?.cast<String, dynamic>(),
      deviceUuid: fields[11] as String,
      userId: fields[12] as String?,
      networkType: fields[13] as String?,
      durationMs: fields[14] as int?,
      metadata: (fields[15] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncLog obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.syncType)
      ..writeByte(2)
      ..write(obj.operation)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.recordsAttempted)
      ..writeByte(5)
      ..write(obj.recordsSucceeded)
      ..writeByte(6)
      ..write(obj.recordsFailed)
      ..writeByte(7)
      ..write(obj.startedAt)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.errorMessage)
      ..writeByte(10)
      ..write(obj.errorDetails)
      ..writeByte(11)
      ..write(obj.deviceUuid)
      ..writeByte(12)
      ..write(obj.userId)
      ..writeByte(13)
      ..write(obj.networkType)
      ..writeByte(14)
      ..write(obj.durationMs)
      ..writeByte(15)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncLog _$SyncLogFromJson(Map<String, dynamic> json) => SyncLog(
      id: json['id'] as String,
      syncType: json['syncType'] as String,
      operation: json['operation'] as String,
      status: json['status'] as String,
      recordsAttempted: (json['recordsAttempted'] as num).toInt(),
      recordsSucceeded: (json['recordsSucceeded'] as num).toInt(),
      recordsFailed: (json['recordsFailed'] as num).toInt(),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      errorDetails: json['errorDetails'] as Map<String, dynamic>?,
      deviceUuid: json['deviceUuid'] as String,
      userId: json['userId'] as String?,
      networkType: json['networkType'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SyncLogToJson(SyncLog instance) => <String, dynamic>{
      'id': instance.id,
      'syncType': instance.syncType,
      'operation': instance.operation,
      'status': instance.status,
      'recordsAttempted': instance.recordsAttempted,
      'recordsSucceeded': instance.recordsSucceeded,
      'recordsFailed': instance.recordsFailed,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'errorDetails': instance.errorDetails,
      'deviceUuid': instance.deviceUuid,
      'userId': instance.userId,
      'networkType': instance.networkType,
      'durationMs': instance.durationMs,
      'metadata': instance.metadata,
    };
