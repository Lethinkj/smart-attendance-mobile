import 'package:postgres/postgres.dart';
import '../models/school.dart';
import '../models/staff.dart';
import '../models/student.dart';

/// PostgreSQL service connecting to Supabase database
class PostgreSQLService {
  
  // Supabase PostgreSQL connection details
  static const String _host = 'db.qctrtvzuazdvuwhwyops.supabase.co';
  static const int _port = 5432;
  static const String _database = 'postgres';
  static const String _username = 'postgres';
  static const String _password = 'smartattendence';
  
  /// Get database connection
  static Future<Connection> _getConnection() async {
    try {
      final connection = await Connection.open(
        Endpoint(
          host: _host,
          port: _port,
          database: _database,
          username: _username,
          password: _password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.require, // Supabase requires SSL
        ),
      );
      
      print('✅ Connected to Supabase PostgreSQL');
      return connection;
    } catch (e) {
      print('❌ Failed to connect to Supabase PostgreSQL: $e');
      rethrow;
    }
  }
  
  // School Management
  static Future<List<School>> getSchools() async {
    try {
      final connection = await _getConnection();
      
      final result = await connection.execute(
        'SELECT * FROM schools WHERE is_active = true ORDER BY created_at DESC'
      );
      
      await connection.close();
      
      return result.map((row) => School.fromJson({
        'id': row[0],
        'name': row[1],
        'address': row[2],
        'phone': row[3],
        'email': row[4],
        'school_type': row[5],
        'unique_id': row[6],
        'is_active': row[7],
        'total_students': row[8],
        'total_staff': row[9],
        'classes': row[10],
        'created_at': row[11].toString(),
        'updated_at': row[12].toString(),
      })).toList();
    } catch (e) {
      print('⚠️ getSchools error: $e');
      // Return empty list on error to prevent app crash
      return [];
    }
  }
  
  static Future<School> createSchool(School school) async {
    try {
      final connection = await _getConnection();
      
      final result = await connection.execute(
        "INSERT INTO schools (name, address, phone, email, school_type, unique_id, is_active, total_students, total_staff, classes) VALUES ('\${school.name}', '\${school.address}', '\${school.phone}', '\${school.email}', '\${school.schoolType}', '\${school.uniqueId}', \${school.isActive}, \${school.totalStudents}, \${school.totalStaff}, \${school.classes.length}) RETURNING *"
      );
      
      await connection.close();
      
      final row = result.first;
      return School.fromJson({
        'id': row[0],
        'name': row[1],
        'address': row[2],
        'phone': row[3],
        'email': row[4],
        'school_type': row[5],
        'unique_id': row[6],
        'is_active': row[7],
        'total_students': row[8],
        'total_staff': row[9],
        'classes': row[10],
        'created_at': row[11].toString(),
        'updated_at': row[12].toString(),
      });
    } catch (e) {
      print('⚠️ createSchool error: $e');
      // Return the original school object on error
      return school;
    }
  }
  
  static Future<School> updateSchool(School school) async {
    try {
      final connection = await _getConnection();
      
      final result = await connection.execute(
        "UPDATE schools SET name = '\${school.name}', address = '\${school.address}', phone = '\${school.phone}', email = '\${school.email}', school_type = '\${school.schoolType}', is_active = \${school.isActive}, total_students = \${school.totalStudents}, total_staff = \${school.totalStaff}, classes = \${school.classes.length}, updated_at = NOW() WHERE id = '\${school.id}' RETURNING *"
      );
      
      await connection.close();
      
      final row = result.first;
      return School.fromJson({
        'id': row[0],
        'name': row[1],
        'address': row[2],
        'phone': row[3],
        'email': row[4],
        'school_type': row[5],
        'unique_id': row[6],
        'is_active': row[7],
        'total_students': row[8],
        'total_staff': row[9],
        'classes': row[10],
        'created_at': row[11].toString(),
        'updated_at': row[12].toString(),
      });
    } catch (e) {
      print('⚠️ updateSchool error: $e');
      return school;
    }
  }
  
  static Future<void> deleteSchool(String schoolId) async {
    try {
      final connection = await _getConnection();
      await connection.execute(
        "UPDATE schools SET is_active = false WHERE id = '$schoolId'"
      );
      await connection.close();
    } catch (e) {
      print('⚠️ deleteSchool error: $e');
    }
  }
  
  static Future<bool> isSchoolIdUnique(String uniqueId) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "SELECT COUNT(*) FROM schools WHERE unique_id = '$uniqueId'"
      );
      await connection.close();
      return result.first[0] == 0;
    } catch (e) {
      print('⚠️ isSchoolIdUnique error: $e');
      return true; // Assume unique on error
    }
  }
  
  // Staff Management
  static Future<List<Staff>> getStaffBySchool(String schoolId) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "SELECT * FROM staff WHERE school_id = '$schoolId' AND is_active = true ORDER BY created_at DESC"
      );
      await connection.close();
      
      return result.map((row) => Staff.fromJson({
        'id': row[0],
        'staff_id': row[1],
        'school_id': row[2],
        'name': row[3],
        'email': row[4],
        'phone': row[5],
        'role': row[6],
        'assigned_classes': row[7],
        'rfid_tag': row[8],
        'is_active': row[9],
        'is_first_login': row[10],
        'password': row[11],
        'created_at': row[12].toString(),
        'updated_at': row[13].toString(),
      })).toList();
    } catch (e) {
      print('⚠️ getStaffBySchool error: $e');
      return [];
    }
  }
  
  static Future<List<Staff>> getAllStaff() async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        'SELECT * FROM staff WHERE is_active = true ORDER BY created_at DESC'
      );
      await connection.close();
      
      return result.map((row) => Staff.fromJson({
        'id': row[0],
        'staff_id': row[1],
        'school_id': row[2],
        'name': row[3],
        'email': row[4],
        'phone': row[5],
        'role': row[6],
        'assigned_classes': row[7],
        'rfid_tag': row[8],
        'is_active': row[9],
        'is_first_login': row[10],
        'password': row[11],
        'created_at': row[12].toString(),
        'updated_at': row[13].toString(),
      })).toList();
    } catch (e) {
      print('⚠️ getAllStaff error: $e');
      return [];
    }
  }
  
  static Future<Staff> createStaff(Staff staff) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "INSERT INTO staff (staff_id, school_id, name, email, phone, role, assigned_classes, rfid_tag, is_active, is_first_login, password) VALUES ('\${staff.staffId}', '\${staff.schoolId}', '\${staff.name}', '\${staff.email}', '\${staff.phone}', '\${staff.role}', '\${staff.assignedClasses}', '\${staff.rfidTag}', \${staff.isActive}, \${staff.isFirstLogin}, '\${staff.password}') RETURNING *"
      );
      await connection.close();
      
      final row = result.first;
      return Staff.fromJson({
        'id': row[0],
        'staff_id': row[1],
        'school_id': row[2],
        'name': row[3],
        'email': row[4],
        'phone': row[5],
        'role': row[6],
        'assigned_classes': row[7],
        'rfid_tag': row[8],
        'is_active': row[9],
        'is_first_login': row[10],
        'password': row[11],
        'created_at': row[12].toString(),
        'updated_at': row[13].toString(),
      });
    } catch (e) {
      print('⚠️ createStaff error: $e');
      return staff;
    }
  }
  
  static Future<Staff> updateStaff(Staff staff) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "UPDATE staff SET name = '\${staff.name}', email = '\${staff.email}', phone = '\${staff.phone}', role = '\${staff.role}', assigned_classes = '\${staff.assignedClasses}', rfid_tag = '\${staff.rfidTag}', is_active = \${staff.isActive}, is_first_login = \${staff.isFirstLogin}, password = '\${staff.password}', updated_at = NOW() WHERE id = '\${staff.id}' RETURNING *"
      );
      await connection.close();
      
      final row = result.first;
      return Staff.fromJson({
        'id': row[0],
        'staff_id': row[1],
        'school_id': row[2],
        'name': row[3],
        'email': row[4],
        'phone': row[5],
        'role': row[6],
        'assigned_classes': row[7],
        'rfid_tag': row[8],
        'is_active': row[9],
        'is_first_login': row[10],
        'password': row[11],
        'created_at': row[12].toString(),
        'updated_at': row[13].toString(),
      });
    } catch (e) {
      print('⚠️ updateStaff error: $e');
      return staff;
    }
  }
  
  static Future<void> deleteStaff(String staffId) async {
    try {
      final connection = await _getConnection();
      await connection.execute(
        "UPDATE staff SET is_active = false WHERE id = '$staffId'"
      );
      await connection.close();
    } catch (e) {
      print('⚠️ deleteStaff error: $e');
    }
  }
  
  static Future<String> generateNextStaffId(String schoolId) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "SELECT COUNT(*) FROM staff WHERE school_id = '$schoolId'"
      );
      final count = result.first[0] as int;
      
      final schoolResult = await connection.execute(
        "SELECT unique_id FROM schools WHERE id = '$schoolId'"
      );
      await connection.close();
      
      final schoolCode = schoolResult.first[0] as String;
      return '\${schoolCode}STF\${(count + 1).toString().padLeft(3, '0')}';
    } catch (e) {
      print('⚠️ generateNextStaffId error: $e');
      return 'STF001'; // Default fallback
    }
  }
  
  // Student Management
  static Future<List<Student>> getStudentsBySchool(String schoolId) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "SELECT * FROM students WHERE school_id = '$schoolId' AND is_active = true ORDER BY class_name, section, roll_number"
      );
      await connection.close();
      
      return result.map((row) => Student.fromJson({
        'id': row[0],
        'student_id': row[1],
        'school_id': row[2],
        'name': row[3],
        'class_name': row[4],
        'section': row[5],
        'roll_number': row[6],
        'rfid_tag': row[7],
        'parent_name': row[8],
        'parent_phone': row[9],
        'parent_email': row[10],
        'date_of_birth': row[11].toString(),
        'address': row[12],
        'is_active': row[13],
        'created_at': row[14].toString(),
        'updated_at': row[15].toString(),
      })).toList();
    } catch (e) {
      print('⚠️ getStudentsBySchool error: $e');
      return [];
    }
  }
  
  static Future<Student> createStudent(Student student) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "INSERT INTO students (student_id, school_id, name, class_name, section, roll_number, rfid_tag, parent_name, parent_phone, parent_email, date_of_birth, address, is_active) VALUES ('\${student.studentId}', '\${student.schoolId}', '\${student.name}', '\${student.className}', '\${student.section}', '\${student.rollNumber}', '\${student.rfidTag}', '\${student.parentName}', '\${student.parentPhone}', '\${student.parentEmail}', '\${student.dateOfBirth.toIso8601String()}', '\${student.address}', \${student.isActive}) RETURNING *"
      );
      await connection.close();
      
      final row = result.first;
      return Student.fromJson({
        'id': row[0],
        'student_id': row[1],
        'school_id': row[2],
        'name': row[3],
        'class_name': row[4],
        'section': row[5],
        'roll_number': row[6],
        'rfid_tag': row[7],
        'parent_name': row[8],
        'parent_phone': row[9],
        'parent_email': row[10],
        'date_of_birth': row[11].toString(),
        'address': row[12],
        'is_active': row[13],
        'created_at': row[14].toString(),
        'updated_at': row[15].toString(),
      });
    } catch (e) {
      print('⚠️ createStudent error: $e');
      return student;
    }
  }
  
  static Future<Student> updateStudent(Student student) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "UPDATE students SET name = '\${student.name}', class_name = '\${student.className}', section = '\${student.section}', roll_number = '\${student.rollNumber}', rfid_tag = '\${student.rfidTag}', parent_name = '\${student.parentName}', parent_phone = '\${student.parentPhone}', parent_email = '\${student.parentEmail}', date_of_birth = '\${student.dateOfBirth.toIso8601String()}', address = '\${student.address}', is_active = \${student.isActive}, updated_at = NOW() WHERE id = '\${student.id}' RETURNING *"
      );
      await connection.close();
      
      final row = result.first;
      return Student.fromJson({
        'id': row[0],
        'student_id': row[1],
        'school_id': row[2],
        'name': row[3],
        'class_name': row[4],
        'section': row[5],
        'roll_number': row[6],
        'rfid_tag': row[7],
        'parent_name': row[8],
        'parent_phone': row[9],
        'parent_email': row[10],
        'date_of_birth': row[11].toString(),
        'address': row[12],
        'is_active': row[13],
        'created_at': row[14].toString(),
        'updated_at': row[15].toString(),
      });
    } catch (e) {
      print('⚠️ updateStudent error: $e');
      return student;
    }
  }
  
  static Future<void> deleteStudent(String studentId) async {
    try {
      final connection = await _getConnection();
      await connection.execute(
        "UPDATE students SET is_active = false WHERE id = '$studentId'"
      );
      await connection.close();
    } catch (e) {
      print('⚠️ deleteStudent error: $e');
    }
  }
  
  // Utility Methods
  static Future<Map<String, dynamic>> getSchoolStats(String schoolId) async {
    try {
      final connection = await _getConnection();
      
      final studentResult = await connection.execute(
        "SELECT COUNT(*) FROM students WHERE school_id = '$schoolId' AND is_active = true"
      );
      
      final staffResult = await connection.execute(
        "SELECT COUNT(*) FROM staff WHERE school_id = '$schoolId' AND is_active = true"
      );
      
      await connection.close();
      
      return {
        'totalStudents': studentResult.first[0],
        'totalStaff': staffResult.first[0],
      };
    } catch (e) {
      print('⚠️ getSchoolStats error: $e');
      return {'totalStudents': 0, 'totalStaff': 0};
    }
  }
  
  // Authentication for Staff
  static Future<Staff?> authenticateStaff(String staffId, String password) async {
    try {
      final connection = await _getConnection();
      final result = await connection.execute(
        "SELECT * FROM staff WHERE staff_id = '$staffId' AND password = '$password' AND is_active = true"
      );
      await connection.close();
      
      if (result.isEmpty) return null;
      
      final row = result.first;
      return Staff.fromJson({
        'id': row[0],
        'staff_id': row[1],
        'school_id': row[2],
        'name': row[3],
        'email': row[4],
        'phone': row[5],
        'role': row[6],
        'assigned_classes': row[7],
        'rfid_tag': row[8],
        'is_active': row[9],
        'is_first_login': row[10],
        'password': row[11],
        'created_at': row[12].toString(),
        'updated_at': row[13].toString(),
      });
    } catch (e) {
      print('⚠️ authenticateStaff error: $e');
      return null;
    }
  }
}