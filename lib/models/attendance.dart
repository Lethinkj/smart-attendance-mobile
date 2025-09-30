import 'package:uuid/uuid.dart';

class Attendance {
  late String id;
  late String studentId;
  late String schoolId;
  late String className;
  late String section;
  late DateTime date;
  late DateTime? checkInTime;
  late DateTime? checkOutTime;
  late String status; // Present, Absent, Late, HalfDay
  late String markedBy; // Staff ID who marked attendance
  late String method; // RFID, Manual
  late String? remarks;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isSynced;

  Attendance({
    String? id,
    required this.studentId,
    required this.schoolId,
    required this.className,
    required this.section,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.status = 'Absent',
    required this.markedBy,
    this.method = 'Manual',
    this.remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'class_name': className,
      'section': section,
      'date': date.toIso8601String().split('T')[0], // Date only
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status,
      'marked_by': markedBy,
      'method': method,
      'remarks': remarks,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['student_id'],
      schoolId: json['school_id'],
      className: json['class_name'],
      section: json['section'],
      date: DateTime.parse(json['date']),
      checkInTime: json['check_in_time'] != null ? DateTime.parse(json['check_in_time']) : null,
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']) : null,
      status: json['status'] ?? 'Absent',
      markedBy: json['marked_by'],
      method: json['method'] ?? 'Manual',
      remarks: json['remarks'],
      isSynced: json['is_synced'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isPresent => status == 'Present';
  bool get isAbsent => status == 'Absent';
  bool get isLate => status == 'Late';
  bool get isHalfDay => status == 'HalfDay';

  Duration? get totalDuration {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!);
    }
    return null;
  }

  Attendance copyWith({
    String? studentId,
    String? schoolId,
    String? className,
    String? section,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    String? markedBy,
    String? method,
    String? remarks,
    bool? isSynced,
  }) {
    return Attendance(
      id: id,
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      className: className ?? this.className,
      section: section ?? this.section,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      method: method ?? this.method,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }
}