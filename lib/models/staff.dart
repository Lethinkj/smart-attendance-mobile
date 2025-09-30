import 'package:uuid/uuid.dart';

class Staff {
  late String id;
  late String staffId;
  late String schoolId;
  late String name;
  late String email;
  late String phone;
  late String role;
  late List<String> assignedClasses;
  late String rfidTag;
  late bool isActive;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isFirstLogin;
  late String password;

  Staff({
    String? id,
    required this.staffId,
    required this.schoolId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    List<String>? assignedClasses,
    this.rfidTag = '',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFirstLogin = true,
    this.password = 'staff123', // Default password - should be changed on first login
  }) {
    this.id = id ?? const Uuid().v4();
    this.assignedClasses = assignedClasses ?? [];
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'school_id': schoolId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'assigned_classes': assignedClasses,
      'rfid_tag': rfidTag,
      'is_active': isActive,
      'is_first_login': isFirstLogin,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      staffId: json['staff_id'],
      schoolId: json['school_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      assignedClasses: List<String>.from(json['assigned_classes'] ?? []),
      rfidTag: json['rfid_tag'] ?? '',
      isActive: json['is_active'] ?? true,
      isFirstLogin: json['is_first_login'] ?? true,
      password: json['password'] ?? 'staff123',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Staff copyWith({
    String? staffId,
    String? schoolId,
    String? name,
    String? email,
    String? phone,
    String? role,
    List<String>? assignedClasses,
    String? rfidTag,
    bool? isActive,
    bool? isFirstLogin,
    String? password,
  }) {
    return Staff(
      id: id,
      staffId: staffId ?? this.staffId,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      rfidTag: rfidTag ?? this.rfidTag,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      password: password ?? this.password,
    );
  }

  @override
  String toString() {
    return 'Staff(staffId: $staffId, schoolId: $schoolId, name: $name, email: $email, role: $role, assignedClasses: $assignedClasses)';
  }
}