import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// User model with Admin/Staff role system
@HiveType(typeId: 3)
@JsonSerializable()
class User extends HiveObject {
  /// Unique user identifier
  @HiveField(0)
  final String id;
  
  /// User email address
  @HiveField(1)
  final String email;
  
  /// User full name
  @HiveField(2)
  final String name;
  
  /// User role (admin or staff only)
  @HiveField(3)
  final UserRole role;
  
  /// User profile photo URL
  @HiveField(4)
  final String? photoUrl;
  
  /// User phone number
  @HiveField(5)
  final String? phone;
  
  /// School/Institution ID (for admin - manages multiple, for staff - belongs to one)
  @HiveField(6)
  final String? schoolId;
  
  /// User status (active, inactive)
  @HiveField(7)
  final String status;
  
  /// Last login timestamp
  @HiveField(8)
  final DateTime? lastLoginAt;
  
  /// Account creation timestamp
  @HiveField(9)
  final DateTime createdAt;
  
  /// Last update timestamp
  @HiveField(10)
  final DateTime updatedAt;
  
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.phone,
    this.schoolId,
    this.status = 'active',
    this.lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// Create user from JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  
  /// Convert user to JSON
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  /// Create copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? photoUrl,
    String? phone,
    String? schoolId,
    String? status,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      schoolId: schoolId ?? this.schoolId,
      status: status ?? this.status,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  /// Get user initials
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
  
  /// Check if user is active
  bool get isActive => status == 'active';
  
  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;
  
  /// Check if user is staff
  bool get isStaff => role == UserRole.staff;
  
  /// Get role display name
  String get roleDisplayName => role.displayName;
  
  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// User roles enum
@HiveType(typeId: 10)
enum UserRole {
  @HiveField(0)
  admin,
  
  @HiveField(1)
  staff;
  
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.staff:
        return 'Staff';
    }
  }
  
  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Manages schools, teachers, and system settings';
      case UserRole.staff:
        return 'Manages students and marks attendance';
    }
  }
}