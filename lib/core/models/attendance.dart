import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attendance.g.dart';

/// Attendance record model with offline-first sync support
/// Supports multiple data sources (RFID readers, manual entry, etc.)
@HiveType(typeId: 0)
@JsonSerializable()
class Attendance extends HiveObject {
  /// Local unique identifier (used before sync)
  @HiveField(0)
  String? localId;
  
  /// Server-assigned unique identifier (assigned after sync)
  @HiveField(1)
  String? serverId;
  
  /// Student identifier
  @HiveField(2)
  final String studentId;
  
  /// Class identifier
  @HiveField(3)
  final String classId;
  
  /// Timestamp when attendance was marked
  @HiveField(4)
  final DateTime markedAt;
  
  /// Who marked the attendance (teacher ID)
  @HiveField(5)
  final String markedBy;
  
  /// Source of attendance (rfid_bluetooth_classic, rfid_ble, rfid_usb, nfc, manual, qr)
  @HiveField(6)
  final String source;
  
  /// Device UUID that recorded the attendance
  @HiveField(7)
  final String deviceUuid;
  
  /// RFID tag or identifier used (if applicable)
  @HiveField(8)
  final String? rfidTag;
  
  /// Attendance status (present, absent, late)
  @HiveField(9)
  final String status;
  
  /// Additional notes or remarks
  @HiveField(10)
  final String? notes;
  
  /// Sync status
  @HiveField(11)
  bool isSynced;
  
  /// Timestamp when synced to server
  @HiveField(12)
  DateTime? syncedAt;
  
  /// Number of sync attempts
  @HiveField(13)
  int syncAttempts;
  
  /// Last sync error message
  @HiveField(14)
  String? lastSyncError;
  
  /// Geographic coordinates (if available)
  @HiveField(15)
  final double? latitude;
  
  @HiveField(16)
  final double? longitude;
  
  /// Session identifier (for grouping related attendance)
  @HiveField(17)
  final String? sessionId;
  
  /// Creation timestamp (for audit)
  @HiveField(18)
  final DateTime createdAt;
  
  /// Last modification timestamp
  @HiveField(19)
  DateTime updatedAt;
  
  Attendance({
    this.localId,
    this.serverId,
    required this.studentId,
    required this.classId,
    required this.markedAt,
    required this.markedBy,
    required this.source,
    required this.deviceUuid,
    this.rfidTag,
    this.status = 'present',
    this.notes,
    this.isSynced = false,
    this.syncedAt,
    this.syncAttempts = 0,
    this.lastSyncError,
    this.latitude,
    this.longitude,
    this.sessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// Create attendance from JSON (server response)
  factory Attendance.fromJson(Map<String, dynamic> json) => _$AttendanceFromJson(json);
  
  /// Convert attendance to JSON (for API requests)
  Map<String, dynamic> toJson() => _$AttendanceToJson(this);
  
  /// Create copy with updated fields
  Attendance copyWith({
    String? localId,
    String? serverId,
    String? studentId,
    String? classId,
    DateTime? markedAt,
    String? markedBy,
    String? source,
    String? deviceUuid,
    String? rfidTag,
    String? status,
    String? notes,
    bool? isSynced,
    DateTime? syncedAt,
    int? syncAttempts,
    String? lastSyncError,
    double? latitude,
    double? longitude,
    String? sessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      markedAt: markedAt ?? this.markedAt,
      markedBy: markedBy ?? this.markedBy,
      source: source ?? this.source,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      rfidTag: rfidTag ?? this.rfidTag,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  /// Get display-friendly source name
  String get sourceDisplayName {
    switch (source) {
      case 'rfid_bluetooth_classic':
        return 'Bluetooth RFID';
      case 'rfid_ble':
        return 'BLE RFID';
      case 'rfid_usb':
        return 'USB RFID';
      case 'nfc':
        return 'NFC';
      case 'manual':
        return 'Manual Entry';
      case 'qr':
        return 'QR Code';
      case 'hid_keyboard':
        return 'Barcode Scanner';
      default:
        return source.toUpperCase();
    }
  }
  
  /// Check if attendance is from RFID source
  bool get isRfidSource {
    return source.startsWith('rfid_') || source == 'nfc';
  }
  
  /// Check if sync is overdue (more than 1 hour and multiple failed attempts)
  bool get isSyncOverdue {
    if (isSynced) return false;
    final hoursSinceCreation = DateTime.now().difference(createdAt).inHours;
    return hoursSinceCreation > 1 && syncAttempts >= 3;
  }
  
  /// Get unique identifier (server ID if available, otherwise local ID)
  String get uniqueId => serverId ?? localId ?? '';
  
  @override
  String toString() {
    return 'Attendance(localId: $localId, serverId: $serverId, studentId: $studentId, classId: $classId, markedAt: $markedAt, source: $source, isSynced: $isSynced)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendance &&
        other.studentId == studentId &&
        other.classId == classId &&
        other.markedAt == markedAt &&
        other.source == source;
  }
  
  @override
  int get hashCode {
    return studentId.hashCode ^
        classId.hashCode ^
        markedAt.hashCode ^
        source.hashCode;
  }
}