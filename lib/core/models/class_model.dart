import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class_model.g.dart';

/// Class/Course model with schedule and teacher information
@HiveType(typeId: 2)
@JsonSerializable()
class ClassModel extends HiveObject {
  /// Unique class identifier
  @HiveField(0)
  final String id;
  
  /// Class name (e.g., "Grade 10-A", "Computer Science 101")
  @HiveField(1)
  final String name;
  
  /// Class code/identifier (e.g., "10A", "CS101")
  @HiveField(2)
  final String code;
  
  /// Subject or course name
  @HiveField(3)
  final String subject;
  
  /// Academic year or semester
  @HiveField(4)
  final String academicYear;
  
  /// Teacher/Instructor ID
  @HiveField(5)
  final String teacherId;
  
  /// Teacher/Instructor name
  @HiveField(6)
  final String teacherName;
  
  /// Class schedule (JSON string for flexibility)
  @HiveField(7)
  final String? schedule;
  
  /// Classroom or location
  @HiveField(8)
  final String? location;
  
  /// Maximum capacity
  @HiveField(9)
  final int? capacity;
  
  /// Class description
  @HiveField(10)
  final String? description;
  
  /// Class status (active, inactive, completed)
  @HiveField(11)
  final String status;
  
  /// Class start date
  @HiveField(12)
  final DateTime? startDate;
  
  /// Class end date
  @HiveField(13)
  final DateTime? endDate;
  
  /// Additional metadata
  @HiveField(14)
  final Map<String, dynamic>? metadata;
  
  /// Creation timestamp
  @HiveField(15)
  final DateTime createdAt;
  
  /// Last update timestamp
  @HiveField(16)
  final DateTime updatedAt;
  
  /// Sync status
  @HiveField(17)
  final bool isSynced;
  
  /// Last sync timestamp
  @HiveField(18)
  final DateTime? lastSyncedAt;
  
  /// Student count (cached for performance)
  @HiveField(19)
  final int? studentCount;
  
  ClassModel({
    required this.id,
    required this.name,
    required this.code,
    required this.subject,
    required this.academicYear,
    required this.teacherId,
    required this.teacherName,
    this.schedule,
    this.location,
    this.capacity,
    this.description,
    this.status = 'active',
    this.startDate,
    this.endDate,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.lastSyncedAt,
    this.studentCount,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// Create class from JSON
  factory ClassModel.fromJson(Map<String, dynamic> json) => _$ClassModelFromJson(json);
  
  /// Convert class to JSON
  Map<String, dynamic> toJson() => _$ClassModelToJson(this);
  
  /// Create copy with updated fields
  ClassModel copyWith({
    String? id,
    String? name,
    String? code,
    String? subject,
    String? academicYear,
    String? teacherId,
    String? teacherName,
    String? schedule,
    String? location,
    int? capacity,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncedAt,
    int? studentCount,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      subject: subject ?? this.subject,
      academicYear: academicYear ?? this.academicYear,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      studentCount: studentCount ?? this.studentCount,
    );
  }
  
  /// Get display name (name + code)
  String get displayName => '$name ($code)';
  
  /// Get full title with subject
  String get fullTitle => '$subject - $name';
  
  /// Check if class is currently active
  bool get isActive => status == 'active';
  
  /// Check if class is ongoing (within date range)
  bool get isOngoing {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return isActive;
  }
  
  /// Check if class is completed
  bool get isCompleted {
    return status == 'completed' || 
           (endDate != null && DateTime.now().isAfter(endDate!));
  }
  
  /// Get formatted date range
  String get dateRange {
    if (startDate == null && endDate == null) return 'No dates set';
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
    }
    if (startDate != null) {
      return 'From ${_formatDate(startDate!)}';
    }
    if (endDate != null) {
      return 'Until ${_formatDate(endDate!)}';
    }
    return '';
  }
  
  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  /// Get capacity utilization percentage
  double? get capacityUtilization {
    if (capacity == null || studentCount == null) return null;
    if (capacity! == 0) return 0.0;
    return (studentCount! / capacity!) * 100;
  }
  
  /// Check if class is over capacity
  bool get isOverCapacity {
    if (capacity == null || studentCount == null) return false;
    return studentCount! > capacity!;
  }
  
  /// Check if student data needs sync
  bool get needsSync => !isSynced || 
      (lastSyncedAt != null && updatedAt.isAfter(lastSyncedAt!));
  
  /// Get class status color for UI
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return '#4CAF50'; // Green
      case 'inactive':
        return '#9E9E9E'; // Grey
      case 'completed':
        return '#2196F3'; // Blue
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#757575'; // Default grey
    }
  }
  
  @override
  String toString() {
    return 'ClassModel(id: $id, name: $name, code: $code, subject: $subject, teacherName: $teacherName)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassModel && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}