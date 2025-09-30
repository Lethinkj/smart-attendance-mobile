// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 1;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      id: fields[0] as String,
      name: fields[1] as String,
      rollNumber: fields[2] as String,
      rfidTag: fields[3] as String?,
      classId: fields[4] as String,
      email: fields[5] as String?,
      phone: fields[6] as String?,
      photoUrl: fields[7] as String?,
      parentName: fields[8] as String?,
      parentPhone: fields[9] as String?,
      address: fields[10] as String?,
      dateOfBirth: fields[11] as DateTime?,
      status: fields[12] as String,
      metadata: (fields[13] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[14] as DateTime?,
      updatedAt: fields[15] as DateTime?,
      isSynced: fields[16] as bool,
      lastSyncedAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.rollNumber)
      ..writeByte(3)
      ..write(obj.rfidTag)
      ..writeByte(4)
      ..write(obj.classId)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.phone)
      ..writeByte(7)
      ..write(obj.photoUrl)
      ..writeByte(8)
      ..write(obj.parentName)
      ..writeByte(9)
      ..write(obj.parentPhone)
      ..writeByte(10)
      ..write(obj.address)
      ..writeByte(11)
      ..write(obj.dateOfBirth)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.metadata)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.isSynced)
      ..writeByte(17)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
      id: json['id'] as String,
      name: json['name'] as String,
      rollNumber: json['rollNumber'] as String,
      rfidTag: json['rfidTag'] as String?,
      classId: json['classId'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      parentName: json['parentName'] as String?,
      parentPhone: json['parentPhone'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      status: json['status'] as String? ?? 'active',
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
    );

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rollNumber': instance.rollNumber,
      'rfidTag': instance.rfidTag,
      'classId': instance.classId,
      'email': instance.email,
      'phone': instance.phone,
      'photoUrl': instance.photoUrl,
      'parentName': instance.parentName,
      'parentPhone': instance.parentPhone,
      'address': instance.address,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'status': instance.status,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'lastSyncedAt': instance.lastSyncedAt?.toIso8601String(),
    };
