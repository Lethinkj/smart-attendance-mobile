// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  final int typeId = 10;

  @override
  AttendanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceStatus.present;
      case 1:
        return AttendanceStatus.absent;
      case 2:
        return AttendanceStatus.late;
      case 3:
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.present;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    switch (obj) {
      case AttendanceStatus.present:
        writer.writeByte(0);
        break;
      case AttendanceStatus.absent:
        writer.writeByte(1);
        break;
      case AttendanceStatus.late:
        writer.writeByte(2);
        break;
      case AttendanceStatus.excused:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 11;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.synced;
      case 2:
        return SyncStatus.failed;
      case 3:
        return SyncStatus.conflict;
      default:
        return SyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.pending:
        writer.writeByte(0);
        break;
      case SyncStatus.synced:
        writer.writeByte(1);
        break;
      case SyncStatus.failed:
        writer.writeByte(2);
        break;
      case SyncStatus.conflict:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PermissionAdapter extends TypeAdapter<Permission> {
  @override
  final int typeId = 12;

  @override
  Permission read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Permission.viewAttendance;
      case 1:
        return Permission.markAttendance;
      case 2:
        return Permission.editStudentRecords;
      case 3:
        return Permission.generateReports;
      case 4:
        return Permission.manageClasses;
      case 5:
        return Permission.accessSettings;
      case 6:
        return Permission.manageStaff;
      case 7:
        return Permission.deleteRecords;
      case 8:
        return Permission.adminAccess;
      default:
        return Permission.viewAttendance;
    }
  }

  @override
  void write(BinaryWriter writer, Permission obj) {
    switch (obj) {
      case Permission.viewAttendance:
        writer.writeByte(0);
        break;
      case Permission.markAttendance:
        writer.writeByte(1);
        break;
      case Permission.editStudentRecords:
        writer.writeByte(2);
        break;
      case Permission.generateReports:
        writer.writeByte(3);
        break;
      case Permission.manageClasses:
        writer.writeByte(4);
        break;
      case Permission.accessSettings:
        writer.writeByte(5);
        break;
      case Permission.manageStaff:
        writer.writeByte(6);
        break;
      case Permission.deleteRecords:
        writer.writeByte(7);
        break;
      case Permission.adminAccess:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeviceStatusAdapter extends TypeAdapter<DeviceStatus> {
  @override
  final int typeId = 13;

  @override
  DeviceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DeviceStatus.connected;
      case 1:
        return DeviceStatus.disconnected;
      case 2:
        return DeviceStatus.connecting;
      case 3:
        return DeviceStatus.error;
      default:
        return DeviceStatus.disconnected;
    }
  }

  @override
  void write(BinaryWriter writer, DeviceStatus obj) {
    switch (obj) {
      case DeviceStatus.connected:
        writer.writeByte(0);
        break;
      case DeviceStatus.disconnected:
        writer.writeByte(1);
        break;
      case DeviceStatus.connecting:
        writer.writeByte(2);
        break;
      case DeviceStatus.error:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RfidReaderTypeAdapter extends TypeAdapter<RfidReaderType> {
  @override
  final int typeId = 14;

  @override
  RfidReaderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RfidReaderType.bluetoothClassic;
      case 1:
        return RfidReaderType.bluetoothLE;
      case 2:
        return RfidReaderType.usb;
      case 3:
        return RfidReaderType.nfc;
      case 4:
        return RfidReaderType.wifi;
      default:
        return RfidReaderType.bluetoothClassic;
    }
  }

  @override
  void write(BinaryWriter writer, RfidReaderType obj) {
    switch (obj) {
      case RfidReaderType.bluetoothClassic:
        writer.writeByte(0);
        break;
      case RfidReaderType.bluetoothLE:
        writer.writeByte(1);
        break;
      case RfidReaderType.usb:
        writer.writeByte(2);
        break;
      case RfidReaderType.nfc:
        writer.writeByte(3);
        break;
      case RfidReaderType.wifi:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RfidReaderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}