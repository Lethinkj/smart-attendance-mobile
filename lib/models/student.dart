import 'package:uuid/uuid.dart';

class Student {
  late String id;
  late String studentId;
  late String schoolId;
  late String name;
  late String className;
  late String section;
  late String rollNumber;
  late String rfidTag;
  late String parentName;
  late String parentPhone;
  late String parentEmail;
  late DateTime dateOfBirth;
  late String address;
  late bool isActive;
  late DateTime createdAt;
  late DateTime updatedAt;

  Student({
    String? id,
    required this.studentId,
    required this.schoolId,
    required this.name,
    required this.className,
    required this.section,
    required this.rollNumber,
    this.rfidTag = '',
    required this.parentName,
    required this.parentPhone,
    this.parentEmail = '',
    required this.dateOfBirth,
    required this.address,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      'name': name,
      'class_name': className,
      'section': section,
      'roll_number': rollNumber,
      'rfid_tag': rfidTag,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_email': parentEmail,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'address': address,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      studentId: json['student_id'],
      schoolId: json['school_id'],
      name: json['name'],
      className: json['class_name'],
      section: json['section'],
      rollNumber: json['roll_number'],
      rfidTag: json['rfid_tag'] ?? '',
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      parentEmail: json['parent_email'] ?? '',
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      address: json['address'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  int get age {
    final now = DateTime.now();
    final birthDate = dateOfBirth;
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Student copyWith({
    String? studentId,
    String? schoolId,
    String? name,
    String? className,
    String? section,
    String? rollNumber,
    String? rfidTag,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    DateTime? dateOfBirth,
    String? address,
    bool? isActive,
  }) {
    return Student(
      id: id,
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      className: className ?? this.className,
      section: section ?? this.section,
      rollNumber: rollNumber ?? this.rollNumber,
      rfidTag: rfidTag ?? this.rfidTag,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}