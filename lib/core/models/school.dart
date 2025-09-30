import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'school.g.dart';

/// School/Institution model for admin management
@HiveType(typeId: 6)
@JsonSerializable()
class School extends HiveObject {
  /// Unique school identifier
  @HiveField(0)
  final String id;
  
  /// School name
  @HiveField(1)
  final String name;
  
  /// School code/identifier
  @HiveField(2)
  final String code;
  
  /// School address
  @HiveField(3)
  final String? address;
  
  /// School phone number
  @HiveField(4)
  final String? phone;
  
  /// School email
  @HiveField(5)
  final String? email;
  
  /// Principal/Head name
  @HiveField(6)
  final String? principalName;
  
  /// School status (active, inactive)
  @HiveField(7)
  final String status;
  
  /// Total number of students (cached for dashboard)
  @HiveField(8)
  final int totalStudents;
  
  /// Total number of staff (cached for dashboard)
  @HiveField(9)
  final int totalStaff;
  
  /// Total number of classes (cached for dashboard)
  @HiveField(10)
  final int totalClasses;
  
  /// Creation timestamp
  @HiveField(11)
  final DateTime createdAt;
  
  /// Last update timestamp
  @HiveField(12)
  final DateTime updatedAt;
  
  /// Sync status
  @HiveField(13)
  final bool isSynced;
  
  /// Last sync timestamp
  @HiveField(14)
  final DateTime? lastSyncedAt;
  
  School({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.phone,
    this.email,
    this.principalName,
    this.status = 'active',
    this.totalStudents = 0,
    this.totalStaff = 0,
    this.totalClasses = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.lastSyncedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// Create school from JSON
  factory School.fromJson(Map<String, dynamic> json) => _$SchoolFromJson(json);
  
  /// Convert school to JSON
  Map<String, dynamic> toJson() => _$SchoolToJson(this);
  
  /// Create copy with updated fields
  School copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    String? principalName,
    String? status,
    int? totalStudents,
    int? totalStaff,
    int? totalClasses,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncedAt,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      principalName: principalName ?? this.principalName,
      status: status ?? this.status,
      totalStudents: totalStudents ?? this.totalStudents,
      totalStaff: totalStaff ?? this.totalStaff,
      totalClasses: totalClasses ?? this.totalClasses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
  
  /// Get school display name with code
  String get displayName => '$name ($code)';
  
  /// Check if school is active
  bool get isActive => status == 'active';
  
  /// Check if school data needs sync
  bool get needsSync => !isSynced || 
      (lastSyncedAt != null && updatedAt.isAfter(lastSyncedAt!));
  
  /// Get school statistics summary
  Map<String, int> get statistics => {
    'students': totalStudents,
    'staff': totalStaff,
    'classes': totalClasses,
  };
  
  @override
  String toString() {
    return 'School(id: $id, name: $name, code: $code, students: $totalStudents)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is School && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}