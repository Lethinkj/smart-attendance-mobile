import '../models/school.dart';
import '../models/staff.dart';
import '../models/student.dart';
import 'supabase_postgresql_service.dart';
import 'supabase_helpers.dart';
import 'supabase_crud_service.dart';

/// PostgreSQL service - now using real Supabase database connection
class PostgreSQLService {
  
  // Supabase PostgreSQL connection details
  static const String host = 'db.qctrtvzuazdvuwhwyops.supabase.co';
  static const int port = 5432;
  static const String database = 'postgres';
  static const String username = 'postgres';
  static const String password_ = 'smartattendence';
  
  // Use real database connection
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    print('🔄 Initializing Supabase PostgreSQL connection:');
    print('   postgresql://$username:$password_@$host:$port/$database');
    
    await SupabasePostgreSQLService.initializeDatabase();
  }
  
  // School Management
  static Future<List<School>> getSchools() async {
    await initialize();
    return await SupabasePostgreSQLService.getSchools();
  }
  
  static Future<School> createSchool(School school) async {
    await initialize();
    // Use enhanced CRUD service that handles duplicates
    return await SupabaseCRUDService.createOrUpdateSchool(school);
  }
  
  static Future<School> updateSchool(School school) async {
    await initialize();
    return await SupabasePostgreSQLService.updateSchool(school);
  }
  
  static Future<void> deleteSchool(String schoolId) async {
    await initialize();
    return await SupabasePostgreSQLService.deleteSchool(schoolId);
  }

  // Admin Authentication
  static Future<Map<String, dynamic>?> authenticateAdmin(String username, String password) async {
    await initialize();
    try {
      // Create admin table if it doesn't exist
      await SupabasePostgreSQLService.createAdminTableIfNotExists();
      
      // Try to authenticate admin from database
      final admin = await SupabasePostgreSQLService.getAdminByCredentials(username, password);
      if (admin != null) {
        return admin;
      }
      
      // If no admin found and this is the default admin, create it
      if (username == 'admin' && password == 'admin') {
        final defaultAdmin = {
          'id': 'admin-001',
          'username': 'admin',
          'password': 'admin',
          'name': 'System Administrator',
          'email': 'admin@smartattendance.com',
          'role': 'Admin',
          'school_id': 'default-school',
          'created_at': DateTime.now().toIso8601String(),
          'is_active': true,
        };
        
        // Insert default admin
        await SupabasePostgreSQLService.createAdmin(defaultAdmin);
        return defaultAdmin;
      }
      
      return null;
    } catch (e) {
      print('❌ Admin authentication error: $e');
      return null;
    }
  }

  // Staff Data Loading for First-Time App Setup
  static Future<void> downloadAndCacheStaffData() async {
    await initialize();
    try {
      print('📥 Downloading staff data for offline access...');
      final allStaff = await getAllStaff();
      
      // Cache staff data locally using your existing storage service
      // This will be used for offline authentication
      print('✅ Downloaded ${allStaff.length} staff records for offline access');
    } catch (e) {
      print('❌ Error downloading staff data: $e');
    }
  }
  
  static Future<bool> isSchoolIdUnique(String uniqueId) async {
    await initialize();
    return await SupabasePostgreSQLService.isSchoolIdUnique(uniqueId);
  }
  
  // Staff Management
  static Future<List<Staff>> getStaffBySchool(String schoolId) async {
    await initialize();
    return await SupabasePostgreSQLService.getStaffBySchool(schoolId);
  }
  
  static Future<List<Staff>> getAllStaff() async {
    await initialize();
    return await SupabasePostgreSQLService.getAllStaff();
  }
  
  static Future<Staff> createStaff(Staff staff) async {
    await initialize();
    // Use enhanced CRUD service that handles UUID conversion and duplicates
    return await SupabaseCRUDService.createStaffWithAutoConversion(staff);
  }
  
  /// Create staff with school unique ID to UUID conversion
  static Future<Staff> createStaffWithSchoolUniqueId(String schoolUniqueId, Staff staff) async {
    await initialize();
    return await SupabaseHelpers.createStaffWithUniqueId(schoolUniqueId, staff);
  }
  
  /// Generate staff accounts for a school using School object
  static Future<List<Staff>> generateStaffForSchool(School school, String schoolType) async {
    await initialize();
    return await SupabaseCRUDService.generateStaffAccountsForSchool(school, schoolType);
  }
  
  static Future<Staff> updateStaff(Staff staff) async {
    await initialize();
    return await SupabasePostgreSQLService.updateStaff(staff);
  }
  
  static Future<void> deleteStaff(String staffId) async {
    await initialize();
    return await SupabasePostgreSQLService.deleteStaff(staffId);
  }
  
  static Future<String> generateNextStaffId(String schoolId) async {
    await initialize();
    return await SupabasePostgreSQLService.generateNextStaffId(schoolId);
  }
  
  // Student Management
  static Future<List<Student>> getStudentsBySchool(String schoolId) async {
    await initialize();
    return await SupabasePostgreSQLService.getStudentsBySchool(schoolId);
  }
  
  static Future<Student> createStudent(Student student) async {
    await initialize();
    return await SupabasePostgreSQLService.createStudent(student);
  }

  static Future<List<Student>> getAllStudents() async {
    await initialize();
    return await SupabasePostgreSQLService.getAllStudents();
  }
  
  // Statistics
  static Future<Map<String, dynamic>> getSchoolStats(String schoolId) async {
    await initialize();
    return await SupabasePostgreSQLService.getSchoolStats(schoolId);
  }

  /// Authenticate staff by staff_id and password
  static Future<Map<String, dynamic>?> authenticateStaff(String staffId, String password) async {
    await initialize();
    return await SupabasePostgreSQLService.authenticateStaff(staffId, password);
  }

  /// Update staff password
  static Future<bool> updateStaffPassword(String staffId, String newPassword) async {
    await initialize();
    return await SupabasePostgreSQLService.updateStaffPassword(staffId, newPassword);
  }

  /// Get staff by staff_id and download their data
  static Future<Map<String, dynamic>?> downloadStaffData(String staffId) async {
    await initialize();
    return await SupabasePostgreSQLService.getStaffByStaffId(staffId);
  }
}