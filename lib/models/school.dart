import 'package:uuid/uuid.dart';

class School {
  late String id;
  late String name;
  late String address;
  late String phone;
  late String email;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String schoolType;
  late String uniqueId;
  late bool isActive;
  late int totalStudents;
  late int totalStaff;
  late List<String> classes;

  School({
    String? id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.schoolType,
    required this.uniqueId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    this.totalStudents = 0,
    this.totalStaff = 0,
    List<String>? classes,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
    this.classes = classes ?? [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'school_type': schoolType,
      'unique_id': uniqueId,
      'is_active': isActive,
      'total_students': totalStudents,
      'total_staff': totalStaff,
      'classes': classes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      schoolType: json['school_type'] ?? 'Primary School',
      uniqueId: json['unique_id'],
      isActive: json['is_active'] ?? true,
      totalStudents: json['total_students'] ?? 0,
      totalStaff: json['total_staff'] ?? 0,
      classes: List<String>.from(json['classes'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  School copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? schoolType,
    String? uniqueId,
    bool? isActive,
    int? totalStudents,
    int? totalStaff,
    List<String>? classes,
  }) {
    return School(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      schoolType: schoolType ?? this.schoolType,
      uniqueId: uniqueId ?? this.uniqueId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      totalStudents: totalStudents ?? this.totalStudents,
      totalStaff: totalStaff ?? this.totalStaff,
      classes: classes ?? this.classes,
    );
  }
}