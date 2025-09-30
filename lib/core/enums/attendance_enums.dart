import 'package:hive/hive.dart';

part 'attendance_enums.g.dart';

/// Attendance status enumeration
@HiveType(typeId: 10)
enum AttendanceStatus {
  @HiveField(0)
  present,
  
  @HiveField(1)
  absent,
  
  @HiveField(2)
  late,
  
  @HiveField(3)
  excused,
}

/// Sync status for offline-first functionality
@HiveType(typeId: 11)
enum SyncStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  synced,
  
  @HiveField(2)
  failed,
  
  @HiveField(3)
  conflict,
}

/// User permissions enumeration
@HiveType(typeId: 12)
enum Permission {
  @HiveField(0)
  viewAttendance,
  
  @HiveField(1)
  markAttendance,
  
  @HiveField(2)
  editStudentRecords,
  
  @HiveField(3)
  generateReports,
  
  @HiveField(4)
  manageClasses,
  
  @HiveField(5)
  accessSettings,
  
  @HiveField(6)
  manageStaff,
  
  @HiveField(7)
  deleteRecords,
  
  @HiveField(8)
  adminAccess,
}

/// Device connection status
@HiveType(typeId: 13)
enum DeviceStatus {
  @HiveField(0)
  connected,
  
  @HiveField(1)
  disconnected,
  
  @HiveField(2)
  connecting,
  
  @HiveField(3)
  error,
}

/// RFID reader type
@HiveType(typeId: 14)
enum RfidReaderType {
  @HiveField(0)
  bluetoothClassic,
  
  @HiveField(1)
  bluetoothLE,
  
  @HiveField(2)
  usb,
  
  @HiveField(3)
  nfc,
  
  @HiveField(4)
  wifi,
}

/// Extension methods for better usability
extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }
  
  String get shortName {
    switch (this) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.late:
        return 'L';
      case AttendanceStatus.excused:
        return 'E';
    }
  }
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending Sync';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Sync Failed';
      case SyncStatus.conflict:
        return 'Sync Conflict';
    }
  }
}

extension PermissionExtension on Permission {
  String get displayName {
    switch (this) {
      case Permission.viewAttendance:
        return 'View Attendance';
      case Permission.markAttendance:
        return 'Mark Attendance';
      case Permission.editStudentRecords:
        return 'Edit Student Records';
      case Permission.generateReports:
        return 'Generate Reports';
      case Permission.manageClasses:
        return 'Manage Classes';
      case Permission.accessSettings:
        return 'Access Settings';
      case Permission.manageStaff:
        return 'Manage Staff';
      case Permission.deleteRecords:
        return 'Delete Records';
      case Permission.adminAccess:
        return 'Admin Access';
    }
  }
  
  String get description {
    switch (this) {
      case Permission.viewAttendance:
        return 'View attendance records and reports';
      case Permission.markAttendance:
        return 'Mark student attendance';
      case Permission.editStudentRecords:
        return 'Edit student information and records';
      case Permission.generateReports:
        return 'Generate attendance and analytics reports';
      case Permission.manageClasses:
        return 'Create and manage class rosters';
      case Permission.accessSettings:
        return 'Access system settings';
      case Permission.manageStaff:
        return 'Manage staff accounts and roles';
      case Permission.deleteRecords:
        return 'Delete attendance and student records';
      case Permission.adminAccess:
        return 'Full administrative access';
    }
  }
}