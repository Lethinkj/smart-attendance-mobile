// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceAdapter extends TypeAdapter<Device> {
  @override
  final int typeId = 4;

  @override
  Device read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Device(
      uuid: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      platform: fields[3] as String,
      osVersion: fields[4] as String,
      appVersion: fields[5] as String,
      model: fields[6] as String?,
      userId: fields[7] as String,
      status: fields[8] as String,
      lastActiveAt: fields[9] as DateTime?,
      registeredAt: fields[10] as DateTime?,
      pushToken: fields[11] as String?,
      rfidCapabilities: (fields[12] as List).cast<String>(),
      settings: (fields[13] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Device obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.platform)
      ..writeByte(4)
      ..write(obj.osVersion)
      ..writeByte(5)
      ..write(obj.appVersion)
      ..writeByte(6)
      ..write(obj.model)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.lastActiveAt)
      ..writeByte(10)
      ..write(obj.registeredAt)
      ..writeByte(11)
      ..write(obj.pushToken)
      ..writeByte(12)
      ..write(obj.rfidCapabilities)
      ..writeByte(13)
      ..write(obj.settings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      platform: json['platform'] as String,
      osVersion: json['osVersion'] as String,
      appVersion: json['appVersion'] as String,
      model: json['model'] as String?,
      userId: json['userId'] as String,
      status: json['status'] as String? ?? 'active',
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.parse(json['lastActiveAt'] as String),
      registeredAt: json['registeredAt'] == null
          ? null
          : DateTime.parse(json['registeredAt'] as String),
      pushToken: json['pushToken'] as String?,
      rfidCapabilities: (json['rfidCapabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      settings: json['settings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'type': instance.type,
      'platform': instance.platform,
      'osVersion': instance.osVersion,
      'appVersion': instance.appVersion,
      'model': instance.model,
      'userId': instance.userId,
      'status': instance.status,
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
      'registeredAt': instance.registeredAt.toIso8601String(),
      'pushToken': instance.pushToken,
      'rfidCapabilities': instance.rfidCapabilities,
      'settings': instance.settings,
    };
