import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/school.dart';
import '../models/staff.dart';
import '../models/student.dart';

/// Real Supabase PostgreSQL service using REST API
class SupabasePostgreSQLService {
  
  // Supabase project configuration
  static const String supabaseUrl = 'https://qctrtvzuazdvuwhwyops.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjdHJ0dnp1YXpkdnV3aHd5b3BzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NzAzODksImV4cCI6MjA3NDM0NjM4OX0.1s53aIR3F8cqev5Jv7W6Zuc5kzmxdQvgA0RCLmiosjM';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
  };

  // Initialize database tables
  static Future<void> initializeDatabase() async {
    print('🔄 Initializing Supabase PostgreSQL database...');
    
    try {
      // Test connection
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=count'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        print('✅ Connected to Supabase PostgreSQL successfully');
        print('📊 Database URL: $supabaseUrl');
        return;
      } else {
        print('⚠️ Database connection test failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Database initialization error: $e');
    }
  }

  // School Management
  static Future<List<School>> getSchools() async {
    try {
      print('📋 Loading schools from Supabase...');
      
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=*&is_active=eq.true'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final schools = data.map((json) => School.fromJson(json)).toList();
        print('✅ Loaded ${schools.length} schools from database');
        return schools;
      } else {
        print('⚠️ Failed to load schools: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ getSchools error: $e');
      return [];
    }
  }
  
  static Future<School> createSchool(School school) async {
    try {
      print('🔄 Creating school in database: ${school.name}');
      
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/schools'),
        headers: _headers,
        body: json.encode(school.toJson()),
      );
      
      if (response.statusCode == 201) {
        print('✅ School created successfully: ${school.name}');
        return school;
      } else {
        print('❌ Failed to create school: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to create school: ${response.body}');
      }
    } catch (e) {
      print('❌ createSchool error: $e');
      rethrow;
    }
  }
  
  static Future<School> updateSchool(School school) async {
    try {
      print('🔄 Updating school: ${school.name}');
      
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/schools?id=eq.${school.id}'),
        headers: _headers,
        body: json.encode(school.toJson()),
      );
      
      if (response.statusCode == 204) {
        print('✅ School updated: ${school.name}');
        return school;
      } else {
        print('❌ Failed to update school: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to update school: ${response.body}');
      }
    } catch (e) {
      print('❌ updateSchool error: $e');
      rethrow;
    }
  }
  
  static Future<void> deleteSchool(String schoolId) async {
    try {
      print('🔄 Deleting school: $schoolId');
      
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/schools?id=eq.$schoolId'),
        headers: _headers,
        body: json.encode({'is_active': false}),
      );
      
      if (response.statusCode == 204) {
        print('✅ School deleted: $schoolId');
      } else {
        print('❌ Failed to delete school: ${response.statusCode}');
        throw Exception('Failed to delete school');
      }
    } catch (e) {
      print('❌ deleteSchool error: $e');
      rethrow;
    }
  }
  
  static Future<bool> isSchoolIdUnique(String uniqueId) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=id&unique_id=eq.$uniqueId&is_active=eq.true'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isEmpty;
      }
      return true;
    } catch (e) {
      print('❌ isSchoolIdUnique error: $e');
      return true;
    }
  }

  // Staff Management
  static Future<List<Staff>> getStaffBySchool(String schoolId) async {
    try {
      print('📋 Loading staff for school: $schoolId');
      
      String actualSchoolId = schoolId;
      
      // If schoolId is not a UUID (like "111", "121"), convert it to UUID
      if (!_isValidUUID(schoolId)) {
        print('🔍 Converting unique_id to UUID: $schoolId');
        
        // Get the school UUID from unique_id
        final schoolResponse = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/schools?select=id&unique_id=eq.$schoolId'),
          headers: _headers,
        );
        
        if (schoolResponse.statusCode == 200) {
          final List<dynamic> schoolData = json.decode(schoolResponse.body);
          if (schoolData.isNotEmpty) {
            actualSchoolId = schoolData.first['id'];
            print('✅ Found school UUID: $actualSchoolId for unique_id: $schoolId');
          } else {
            print('❌ No school found with unique_id: $schoolId');
            return [];
          }
        } else {
          print('❌ Failed to get school UUID: ${schoolResponse.statusCode}');
          return [];
        }
      }
      
      // Now get staff using the actual UUID
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*&school_id=eq.$actualSchoolId'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('🔍 Staff found for school $schoolId (UUID: $actualSchoolId): ${data.length}');
        
        // Try to convert to Staff objects
        List<Staff> staff = [];
        for (var json in data) {
          try {
            staff.add(Staff.fromJson(json));
          } catch (e) {
            print('❌ Failed to parse staff record: $json');
            print('❌ Parse error: $e');
          }
        }
        
        print('✅ Successfully loaded ${staff.length} staff members for school');
        return staff;
      } else {
        print('❌ Failed to load staff for school: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ getStaffBySchool error: $e');
      return [];
    }
  }
  
  // Helper method to check if a string is a valid UUID
  static bool _isValidUUID(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }
  
  static Future<List<Staff>> getAllStaff() async {
    try {
      print('📋 Loading all staff...');
      
      // First try without is_active filter to see all records
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('🔍 Raw staff data count: ${data.length}');
        
        // Debug: print first few records
        if (data.isNotEmpty) {
          print('📋 First staff record: ${data.first}');
          print('📋 Available fields: ${data.first.keys.join(', ')}');
        }
        
        // Try to convert to Staff objects
        List<Staff> staff = [];
        for (var json in data) {
          try {
            staff.add(Staff.fromJson(json));
          } catch (e) {
            print('❌ Failed to parse staff record: $json');
            print('❌ Parse error: $e');
          }
        }
        
        print('✅ Successfully parsed ${staff.length} staff members out of ${data.length} records');
        return staff;
      } else {
        print('❌ Failed to load staff: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ getAllStaff error: $e');
      return [];
    }
  }
  
  static Future<Staff> createStaff(Staff staff) async {
    try {
      print('🔄 Creating staff: ${staff.name} (${staff.staffId})');
      
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/staff'),
        headers: _headers,
        body: json.encode(staff.toJson()),
      );
      
      if (response.statusCode == 201) {
        print('✅ Staff created: ${staff.name}');
        return staff;
      } else {
        print('❌ Failed to create staff: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to create staff: ${response.body}');
      }
    } catch (e) {
      print('❌ createStaff error: $e');
      rethrow;
    }
  }
  
  static Future<Staff> updateStaff(Staff staff) async {
    try {
      print('🔄 Updating staff: ${staff.name}');
      
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/staff?id=eq.${staff.id}'),
        headers: _headers,
        body: json.encode(staff.toJson()),
      );
      
      if (response.statusCode == 204) {
        print('✅ Staff updated: ${staff.name}');
        return staff;
      } else {
        print('❌ Failed to update staff: ${response.statusCode}');
        throw Exception('Failed to update staff');
      }
    } catch (e) {
      print('❌ updateStaff error: $e');
      rethrow;
    }
  }
  
  static Future<void> deleteStaff(String staffId) async {
    try {
      print('🔄 Permanently deleting staff: $staffId');
      
      final response = await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/staff?id=eq.$staffId'),
        headers: _headers,
      );
      
      if (response.statusCode == 204) {
        print('✅ Staff permanently deleted: $staffId');
      } else {
        print('❌ Failed to delete staff: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to delete staff: ${response.body}');
      }
    } catch (e) {
      print('❌ deleteStaff error: $e');
      rethrow;
    }
  }
  
  static Future<String> generateNextStaffId(String schoolId) async {
    try {
      // Get school info
      final schoolResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=unique_id&id=eq.$schoolId'),
        headers: _headers,
      );
      
      if (schoolResponse.statusCode != 200) {
        throw Exception('Failed to get school info');
      }
      
      final schoolData = json.decode(schoolResponse.body) as List;
      if (schoolData.isEmpty) {
        throw Exception('School not found');
      }
      
      final schoolUniqueId = schoolData.first['unique_id'] as String;
      
      // Count existing staff for this school
      final staffResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=id&school_id=eq.$schoolId'),
        headers: _headers,
      );
      
      if (staffResponse.statusCode != 200) {
        throw Exception('Failed to count staff');
      }
      
      final staffData = json.decode(staffResponse.body) as List;
      final count = staffData.length;
      final staffId = '${schoolUniqueId}STF${(count + 1).toString().padLeft(3, '0')}';
      
      print('📋 Generated staff ID: $staffId');
      return staffId;
    } catch (e) {
      print('❌ generateNextStaffId error: $e');
      return 'STF001';
    }
  }

  // Student Management
  static Future<List<Student>> getStudentsBySchool(String schoolId) async {
    try {
      print('📋 Loading students for school: $schoolId');
      
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/students?select=*&school_id=eq.$schoolId&is_active=eq.true'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final students = data.map((json) => Student.fromJson(json)).toList();
        print('✅ Loaded ${students.length} students');
        return students;
      } else {
        print('⚠️ Failed to load students: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ getStudentsBySchool error: $e');
      return [];
    }
  }

  static Future<List<Student>> getAllStudents() async {
    try {
      print('📋 Loading ALL students from database...');
      
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/students?select=*&is_active=eq.true'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final students = data.map((json) => Student.fromJson(json)).toList();
        print('✅ Loaded ${students.length} total students from all schools');
        return students;
      } else {
        print('⚠️ Failed to load all students: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ getAllStudents error: $e');
      return [];
    }
  }
  
  static Future<Student> createStudent(Student student) async {
    try {
      print('🔄 Creating student: ${student.name}');
      
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/students'),
        headers: _headers,
        body: json.encode(student.toJson()),
      );
      
      if (response.statusCode == 201) {
        print('✅ Student created: ${student.name}');
        return student;
      } else {
        print('❌ Failed to create student: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to create student: ${response.body}');
      }
    } catch (e) {
      print('❌ createStudent error: $e');
      rethrow;
    }
  }

  // Database Schema Creation
  static Future<void> createTables() async {
    print('🔄 Creating database tables in Supabase...');
    print('💡 Note: Tables should be created through Supabase Dashboard SQL Editor');
    print('📋 Required tables: schools, staff, students, attendance');
    
    // The actual table creation should be done through Supabase Dashboard
    // But we can check if tables exist
    await initializeDatabase();
  }

  // Statistics
  static Future<Map<String, dynamic>> getSchoolStats(String schoolId) async {
    try {
      // Get staff count
      final staffResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=id&school_id=eq.$schoolId&is_active=eq.true'),
        headers: _headers,
      );
      
      final staffCount = staffResponse.statusCode == 200 
          ? (json.decode(staffResponse.body) as List).length 
          : 0;
      
      // Get student count
      final studentResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/students?select=id&school_id=eq.$schoolId&is_active=eq.true'),
        headers: _headers,
      );
      
      final studentCount = studentResponse.statusCode == 200 
          ? (json.decode(studentResponse.body) as List).length 
          : 0;
      
      return {
        'totalStaff': staffCount,
        'totalStudents': studentCount,
        'activeClasses': 0, // TODO: Calculate from students/staff
      };
    } catch (e) {
      print('❌ getSchoolStats error: $e');
      return {
        'totalStaff': 0,
        'totalStudents': 0,
        'activeClasses': 0,
      };
    }
  }

  // ADMIN AUTHENTICATION METHODS
  
  /// Create admin table if it doesn't exist
  static Future<void> createAdminTableIfNotExists() async {
    try {
      // Test if admin table exists by trying to query it
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/admins?select=count'),
        headers: _headers,
      );
      
      if (response.statusCode != 200) {
        print('📋 Admin table needs to be created in Supabase dashboard');
        // Note: Table creation should be done through Supabase dashboard
        // SQL: CREATE TABLE admins (
        //   id TEXT PRIMARY KEY,
        //   username TEXT UNIQUE NOT NULL,
        //   password TEXT NOT NULL,
        //   name TEXT NOT NULL,
        //   email TEXT,
        //   role TEXT DEFAULT 'Admin',
        //   school_id TEXT,
        //   created_at TIMESTAMP DEFAULT NOW(),
        //   is_active BOOLEAN DEFAULT TRUE
        // );
      }
    } catch (e) {
      print('⚠️ Admin table check error: $e');
    }
  }

  /// Get admin by credentials
  static Future<Map<String, dynamic>?> getAdminByCredentials(String username, String password) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/admins?select=*&username=eq.$username&password=eq.$password&is_active=eq.true'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> admins = json.decode(response.body);
        if (admins.isNotEmpty) {
          print('✅ Admin authentication successful for: $username');
          return admins.first as Map<String, dynamic>;
        }
      }
      
      print('❌ Admin authentication failed for: $username');
      return null;
    } catch (e) {
      print('❌ Admin authentication error: $e');
      return null;
    }
  }

  /// Create new admin
  static Future<void> createAdmin(Map<String, dynamic> adminData) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/admins'),
        headers: _headers,
        body: json.encode(adminData),
      );

      if (response.statusCode == 201) {
        print('✅ Admin created successfully: ${adminData['username']}');
      } else {
        print('❌ Failed to create admin: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Create admin error: $e');
    }
  }

  /// Authenticate staff by staff_id and password
  static Future<Map<String, dynamic>?> authenticateStaff(String staffId, String password) async {
    try {
      print('🔐 Authenticating staff: $staffId');
      
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*&staff_id=eq.$staffId&password=eq.$password&is_active=eq.true'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> staff = json.decode(response.body);
        if (staff.isNotEmpty) {
          final staffData = staff.first as Map<String, dynamic>;
          print('✅ Staff authentication successful for: $staffId');
          return staffData;
        }
      }
      
      print('❌ Staff authentication failed for: $staffId');
      return null;
    } catch (e) {
      print('❌ Staff authentication error: $e');
      return null;
    }
  }

  /// Update staff password
  static Future<bool> updateStaffPassword(String staffId, String newPassword) async {
    try {
      print('🔐 Updating password for staff: $staffId');
      
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/staff?staff_id=eq.$staffId'),
        headers: _headers,
        body: json.encode({
          'password': newPassword,
          'is_first_login': false,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 204) {
        print('✅ Staff password updated successfully for: $staffId');
        return true;
      } else {
        print('❌ Failed to update staff password: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Update staff password error: $e');
      return false;
    }
  }

  /// Get staff by staff_id (for data download)
  static Future<Map<String, dynamic>?> getStaffByStaffId(String staffId) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*&staff_id=eq.$staffId&is_active=eq.true'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> staff = json.decode(response.body);
        if (staff.isNotEmpty) {
          return staff.first as Map<String, dynamic>;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Get staff by staff_id error: $e');
      return null;
    }
  }
}