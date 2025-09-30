import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/school.dart';
import '../models/staff.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class SupabaseService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Authentication Methods
  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp(String email, String password, Map<String, dynamic> userData) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  // School Management
  static Future<List<School>> getSchools() async {
    try {
      final response = await _client
          .from('schools')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => School.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schools: $e');
    }
  }

  static Future<School> createSchool(School school) async {
    try {
      final response = await _client
          .from('schools')
          .insert(school.toJson())
          .select()
          .single();
      
      return School.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create school: $e');
    }
  }

  static Future<School> updateSchool(School school) async {
    try {
      final response = await _client
          .from('schools')
          .update(school.toJson())
          .eq('id', school.id)
          .select()
          .single();
      
      return School.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update school: $e');
    }
  }

  static Future<void> deleteSchool(String schoolId) async {
    try {
      await _client
          .from('schools')
          .update({'is_active': false})
          .eq('id', schoolId);
    } catch (e) {
      throw Exception('Failed to delete school: $e');
    }
  }

  static Future<bool> isSchoolIdUnique(String uniqueId) async {
    try {
      final response = await _client
          .from('schools')
          .select('id')
          .eq('unique_id', uniqueId)
          .limit(1);
      
      return response.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Staff Management
  static Future<List<Staff>> getStaffBySchool(String schoolId) async {
    try {
      String actualSchoolId = schoolId;
      
      // If schoolId looks like a unique_id (not a UUID), convert to database ID
      if (!schoolId.contains('-')) {
        final schoolResponse = await _client
            .from('schools')
            .select('id')
            .eq('unique_id', schoolId)
            .single();
        actualSchoolId = schoolResponse['id'];
      }
      
      final response = await _client
          .from('staff')
          .select()
          .eq('school_id', actualSchoolId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => Staff.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch staff: $e');
    }
  }

  static Future<Staff> createStaff(Staff staff) async {
    try {
      // If schoolId looks like a unique_id (alphanumeric), convert to database ID
      String actualSchoolId = staff.schoolId;
      
      // Check if it's a unique_id format (not a UUID)
      if (!actualSchoolId.contains('-')) {
        final schoolResponse = await _client
            .from('schools')
            .select('id')
            .eq('unique_id', staff.schoolId)
            .single();
        actualSchoolId = schoolResponse['id'];
      }
      
      // Create JSON manually with only the fields needed for insertion
      final staffData = {
        'staff_id': staff.staffId,
        'school_id': actualSchoolId,
        'name': staff.name,
        'email': staff.email,
        'phone': staff.phone,
        'role': staff.role,
        'assigned_classes': staff.assignedClasses,
        'is_active': staff.isActive,
        'is_first_login': staff.isFirstLogin,
        'password': staff.password,
        // Don't include id, created_at, updated_at - let database handle these
      };
      
      print('Attempting to create staff with data: $staffData');
      
      final response = await _client
          .from('staff')
          .insert(staffData)
          .select()
          .single();
      
      return Staff.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  static Future<Staff> updateStaff(Staff staff) async {
    try {
      final response = await _client
          .from('staff')
          .update(staff.toJson())
          .eq('id', staff.id)
          .select()
          .single();
      
      return Staff.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update staff: $e');
    }
  }

  static Future<String> generateNextStaffId(String schoolUniqueId) async {
    try {
      // Get the actual school database ID from unique_id
      final schoolResponse = await _client
          .from('schools')
          .select('id')
          .eq('unique_id', schoolUniqueId)
          .single();
      
      final schoolDbId = schoolResponse['id'];
      
      final response = await _client
          .from('staff')
          .select('staff_id')
          .eq('school_id', schoolDbId)
          .order('staff_id', ascending: false);
      
      if (response.isEmpty) {
        return '${schoolUniqueId}001';
      } else {
        // Find the highest numeric staff ID
        int highestNumber = 0;
        
        for (final record in response) {
          final staffId = record['staff_id'] as String;
          
          // Check if this is a numeric staff ID (ends with 3 digits)
          final parts = staffId.split('_');
          if (parts.length == 1) {
            // Format: schoolId + 3 digits (e.g., "43211001")
            final suffix = staffId.substring(schoolUniqueId.length);
            if (suffix.length == 3 && RegExp(r'^\d{3}$').hasMatch(suffix)) {
              final number = int.parse(suffix);
              if (number > highestNumber) {
                highestNumber = number;
              }
            }
          }
        }
        
        final nextNumber = (highestNumber + 1).toString().padLeft(3, '0');
        return '$schoolUniqueId$nextNumber';
      }
    } catch (e) {
      throw Exception('Failed to generate staff ID: $e');
    }
  }

  static Future<void> deleteStaff(String staffId) async {
    try {
      final response = await _client
          .from('staff')
          .delete()
          .eq('id', staffId);
      
      if (response.error != null) {
        throw Exception('Failed to delete staff: ${response.error!.message}');
      }
    } catch (e) {
      throw Exception('Failed to delete staff: $e');
    }
  }

  static Future<List<Staff>> getAllStaff() async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((data) => Staff.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to load all staff: $e');
    }
  }

  // Student Management
  static Future<List<Student>> getStudentsBySchool(String schoolId) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('class_name, section, roll_number');
      
      return (response as List)
          .map((json) => Student.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  static Future<List<Student>> getStudentsByClass(String schoolId, String className, String section) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('school_id', schoolId)
          .eq('class_name', className)
          .eq('section', section)
          .eq('is_active', true)
          .order('roll_number');
      
      return (response as List)
          .map((json) => Student.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  static Future<Student> createStudent(Student student) async {
    try {
      final response = await _client
          .from('students')
          .insert(student.toJson())
          .select()
          .single();
      
      return Student.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  static Future<Student> updateStudent(Student student) async {
    try {
      final response = await _client
          .from('students')
          .update(student.toJson())
          .eq('id', student.id)
          .select()
          .single();
      
      return Student.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Attendance Management
  static Future<List<Attendance>> getAttendanceByDate(String schoolId, DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _client
          .from('attendance')
          .select()
          .eq('school_id', schoolId)
          .eq('date', dateString)
          .order('class_name, section, created_at');
      
      return (response as List)
          .map((json) => Attendance.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  static Future<Attendance> markAttendance(Attendance attendance) async {
    try {
      // Check if attendance already exists
      final existing = await _client
          .from('attendance')
          .select()
          .eq('student_id', attendance.studentId)
          .eq('date', attendance.date.toIso8601String().split('T')[0])
          .limit(1);
      
      if (existing.isNotEmpty) {
        // Update existing attendance
        final response = await _client
            .from('attendance')
            .update(attendance.toJson())
            .eq('id', existing[0]['id'])
            .select()
            .single();
        
        return Attendance.fromJson(response);
      } else {
        // Create new attendance
        final response = await _client
            .from('attendance')
            .insert(attendance.toJson())
            .select()
            .single();
        
        return Attendance.fromJson(response);
      }
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  static Future<List<Attendance>> getStudentAttendanceHistory(String studentId, DateTime fromDate, DateTime toDate) async {
    try {
      final response = await _client
          .from('attendance')
          .select()
          .eq('student_id', studentId)
          .gte('date', fromDate.toIso8601String().split('T')[0])
          .lte('date', toDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);
      
      return (response as List)
          .map((json) => Attendance.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance history: $e');
    }
  }

  // Analytics and Reports
  static Future<Map<String, dynamic>> getSchoolStats(String schoolId) async {
    try {
      // Get total students
      final studentsResponse = await _client
          .from('students')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true);
      
      // Get total staff
      final staffResponse = await _client
          .from('staff')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true);
      
      // Get today's attendance
      final today = DateTime.now().toIso8601String().split('T')[0];
      final attendanceResponse = await _client
          .from('attendance')
          .select('status')
          .eq('school_id', schoolId)
          .eq('date', today);
      
      final presentCount = attendanceResponse.where((record) => record['status'] == 'Present').length;
      final totalAttendance = attendanceResponse.length;
      
      return {
        'total_students': studentsResponse.length,
        'total_staff': staffResponse.length,
        'present_today': presentCount,
        'total_attendance_today': totalAttendance,
        'attendance_percentage': totalAttendance > 0 ? (presentCount / totalAttendance * 100).round() : 0,
      };
    } catch (e) {
      throw Exception('Failed to get school stats: $e');
    }
  }

  // Sync methods for offline support
  static Future<void> syncPendingData() async {
    // This would sync any pending local changes to Supabase
    // Implementation would depend on your local storage strategy
  }

  // Helper method to check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Get current user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      // Try to get from staff table first
      final staffResponse = await _client
          .from('staff')
          .select()
          .eq('email', user.email!)
          .limit(1);
      
      if (staffResponse.isNotEmpty) {
        return {
          'type': 'staff',
          'data': staffResponse[0],
        };
      }
      
      // If not found in staff, might be admin (you can add admin table logic here)
      return {
        'type': 'admin',
        'data': {
          'id': user.id,
          'email': user.email,
          'role': 'Admin',
        },
      };
    } catch (e) {
      return null;
    }
  }
}