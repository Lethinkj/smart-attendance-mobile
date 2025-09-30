// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassModelAdapter extends TypeAdapter<ClassModel> {
  @override
  final int typeId = 2;

  @override
  ClassModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassModel(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      subject: fields[3] as String,
      academicYear: fields[4] as String,
      teacherId: fields[5] as String,
      teacherName: fields[6] as String,
      schedule: fields[7] as String?,
      location: fields[8] as String?,
      capacity: fields[9] as int?,
      description: fields[10] as String?,
      status: fields[11] as String,
      startDate: fields[12] as DateTime?,
      endDate: fields[13] as DateTime?,
      metadata: (fields[14] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[15] as DateTime?,
      updatedAt: fields[16] as DateTime?,
      isSynced: fields[17] as bool,
      lastSyncedAt: fields[18] as DateTime?,
      studentCount: fields[19] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ClassModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.academicYear)
      ..writeByte(5)
      ..write(obj.teacherId)
      ..writeByte(6)
      ..write(obj.teacherName)
      ..writeByte(7)
      ..write(obj.schedule)
      ..writeByte(8)
      ..write(obj.location)
      ..writeByte(9)
      ..write(obj.capacity)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.startDate)
      ..writeByte(13)
      ..write(obj.endDate)
      ..writeByte(14)
      ..write(obj.metadata)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.isSynced)
      ..writeByte(18)
      ..write(obj.lastSyncedAt)
      ..writeByte(19)
      ..write(obj.studentCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassModel _$ClassModelFromJson(Map<String, dynamic> json) => ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      subject: json['subject'] as String,
      academicYear: json['academicYear'] as String,
      teacherId: json['teacherId'] as String,
      teacherName: json['teacherName'] as String,
      schedule: json['schedule'] as String?,
      location: json['location'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
      studentCount: (json['studentCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ClassModelToJson(ClassModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'subject': instance.subject,
      'academicYear': instance.academicYear,
      'teacherId': instance.teacherId,
      'teacherName': instance.teacherName,
      'schedule': instance.schedule,
      'location': instance.location,
      'capacity': instance.capacity,
      'description': instance.description,
      'status': instance.status,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'lastSyncedAt': instance.lastSyncedAt?.toIso8601String(),
      'studentCount': instance.studentCount,
    };
