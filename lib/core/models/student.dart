import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';

/// Student model with RFID support and offline sync
@HiveType(typeId: 1)
@JsonSerializable()
class Student extends HiveObject {
  /// Unique student identifier
  @HiveField(0)
  final String id;
  
  /// Student full name
  @HiveField(1)
  final String name;
  
  /// Student roll number or registration number
  @HiveField(2)
  final String rollNumber;
  
  /// Associated RFID tag identifier
  @HiveField(3)
  final String? rfidTag;
  
  /// Class ID the student belongs to
  @HiveField(4)
  final String classId;
  
  /// Student email address
  @HiveField(5)
  final String? email;
  
  /// Student phone number
  @HiveField(6)
  final String? phone;
  
  /// Student profile photo URL
  @HiveField(7)
  final String? photoUrl;
  
  /// Parent/Guardian name
  @HiveField(8)
  final String? parentName;
  
  /// Parent/Guardian phone number
  @HiveField(9)
  final String? parentPhone;
  
  /// Student address
  @HiveField(10)
  final String? address;
  
  /// Date of birth
  @HiveField(11)
  final DateTime? dateOfBirth;
  
  /// Student status (active, inactive, suspended)
  @HiveField(12)
  final String status;
  
  /// Additional metadata
  @HiveField(13)
  final Map<String, dynamic>? metadata;
  
  /// Creation timestamp
  @HiveField(14)
  final DateTime createdAt;
  
  /// Last update timestamp
  @HiveField(15)
  final DateTime updatedAt;
  
  /// Sync status
  @HiveField(16)
  final bool isSynced;
  
  /// Last sync timestamp
  @HiveField(17)
  final DateTime? lastSyncedAt;
  
  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.rfidTag,
    required this.classId,
    this.email,
    this.phone,
    this.photoUrl,
    this.parentName,
    this.parentPhone,
    this.address,
    this.dateOfBirth,
    this.status = 'active',
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.lastSyncedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// Create student from JSON
  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
  
  /// Convert student to JSON
  Map<String, dynamic> toJson() => _$StudentToJson(this);
  
  /// Create copy with updated fields
  Student copyWith({
    String? id,
    String? name,
    String? rollNumber,
    String? rfidTag,
    String? classId,
    String? email,
    String? phone,
    String? photoUrl,
    String? parentName,
    String? parentPhone,
    String? address,
    DateTime? dateOfBirth,
    String? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncedAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      rfidTag: rfidTag ?? this.rfidTag,
      classId: classId ?? this.classId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
  
  /// Get student's display name (name + roll number)
  String get displayName => '$name ($rollNumber)';
  
  /// Get student's initials
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
  
  /// Check if student has RFID tag assigned
  bool get hasRfidTag => rfidTag != null && rfidTag!.isNotEmpty;
  
  /// Check if student is active
  bool get isActive => status == 'active';
  
  /// Get age in years (if date of birth is available)
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
  
  /// Get formatted date of birth
  String? get formattedDateOfBirth {
    if (dateOfBirth == null) return null;
    return '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}';
  }
  
  /// Check if student data needs sync
  bool get needsSync => !isSynced || 
      (lastSyncedAt != null && updatedAt.isAfter(lastSyncedAt!));
  
  @override
  String toString() {
    return 'Student(id: $id, name: $name, rollNumber: $rollNumber, classId: $classId, rfidTag: $rfidTag)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}