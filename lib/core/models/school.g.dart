// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SchoolAdapter extends TypeAdapter<School> {
  @override
  final int typeId = 6;

  @override
  School read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return School(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      address: fields[3] as String?,
      phone: fields[4] as String?,
      email: fields[5] as String?,
      principalName: fields[6] as String?,
      status: fields[7] as String,
      totalStudents: fields[8] as int,
      totalStaff: fields[9] as int,
      totalClasses: fields[10] as int,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
      isSynced: fields[13] as bool,
      lastSyncedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, School obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.principalName)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.totalStudents)
      ..writeByte(9)
      ..write(obj.totalStaff)
      ..writeByte(10)
      ..write(obj.totalClasses)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.isSynced)
      ..writeByte(14)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

School _$SchoolFromJson(Map<String, dynamic> json) => School(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      principalName: json['principalName'] as String?,
      status: json['status'] as String? ?? 'active',
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      totalStaff: (json['totalStaff'] as num?)?.toInt() ?? 0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
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
    );

Map<String, dynamic> _$SchoolToJson(School instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'address': instance.address,
      'phone': instance.phone,
      'email': instance.email,
      'principalName': instance.principalName,
      'status': instance.status,
      'totalStudents': instance.totalStudents,
      'totalStaff': instance.totalStaff,
      'totalClasses': instance.totalClasses,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'lastSyncedAt': instance.lastSyncedAt?.toIso8601String(),
    };
