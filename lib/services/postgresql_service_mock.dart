import '../models/school.dart';
import '../models/staff.dart';
import '../models/student.dart';

/// Mock PostgreSQL service for development - replaces SupabaseService
/// This allows the app to compile and run without a real database connection
class PostgreSQLService {
  
  // Mock data for testing
  static List<School> _mockSchools = [];
  static List<Staff> _mockStaff = [];
  static List<Student> _mockStudents = [];
  
  // Initialize with sample data
  static void _initializeMockData() {
    if (_mockSchools.isEmpty) {
      // Create a sample school
      final sampleSchool = School(
        name: 'Sample High School',
        address: '123 Education Street, Learning City',
        phone: '+1-555-0123',
        email: 'info@samplehigh.edu',
        schoolType: 'High School',
        uniqueId: 'SHS001',
        isActive: true,
        totalStudents: 500,
        totalStaff: 50,
        classes: ['Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
      );
      _mockSchools.add(sampleSchool);
      
      // Create sample staff
      final sampleStaff = Staff(
        staffId: 'admin',
        schoolId: sampleSchool.id,
        name: 'Admin User',
        email: 'admin@samplehigh.edu',
        phone: '+1-555-0124',
        role: 'Administrator',
        assignedClasses: [],
        isActive: true,
        isFirstLogin: false,
        password: 'admin123',
      );
      _mockStaff.add(sampleStaff);
    }
  }
  
  // School Management
  static Future<List<School>> getSchools() async {
    _initializeMockData();
    await Future.delayed(Duration(milliseconds: 100)); // Simulate network delay
    return List.from(_mockSchools);
  }
  
  static Future<School> createSchool(School school) async {
    await Future.delayed(Duration(milliseconds: 100));
    _mockSchools.add(school);
    return school;
  }
  
  static Future<School> updateSchool(School school) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _mockSchools.indexWhere((s) => s.id == school.id);
    if (index != -1) {
      _mockSchools[index] = school;
    }
    return school;
  }
  
  static Future<void> deleteSchool(String schoolId) async {
    await Future.delayed(Duration(milliseconds: 100));
    _mockSchools.removeWhere((s) => s.id == schoolId);
  }
  
  static Future<bool> isSchoolIdUnique(String uniqueId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return !_mockSchools.any((s) => s.uniqueId == uniqueId);
  }
  
  // Staff Management
  static Future<List<Staff>> getStaffBySchool(String schoolId) async {
    _initializeMockData();
    await Future.delayed(Duration(milliseconds: 100));
    return _mockStaff.where((s) => s.schoolId == schoolId && s.isActive).toList();
  }
  
  static Future<List<Staff>> getAllStaff() async {
    _initializeMockData();
    await Future.delayed(Duration(milliseconds: 100));
    return List.from(_mockStaff.where((s) => s.isActive));
  }
  
  static Future<Staff> createStaff(Staff staff) async {
    await Future.delayed(Duration(milliseconds: 100));
    _mockStaff.add(staff);
    return staff;
  }
  
  static Future<Staff> updateStaff(Staff staff) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _mockStaff.indexWhere((s) => s.id == staff.id);
    if (index != -1) {
      _mockStaff[index] = staff;
    }
    return staff;
  }
  
  static Future<void> deleteStaff(String staffId) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _mockStaff.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      _mockStaff[index] = _mockStaff[index].copyWith(isActive: false);
    }
  }
  
  static Future<String> generateNextStaffId(String schoolId) async {
    await Future.delayed(Duration(milliseconds: 100));
    final count = _mockStaff.where((s) => s.schoolId == schoolId).length;
    final school = _mockSchools.firstWhere((s) => s.id == schoolId, orElse: () => _mockSchools.first);
    return '${school.uniqueId}STF${(count + 1).toString().padLeft(3, '0')}';
  }
  
  // Student Management
  static Future<List<Student>> getStudentsBySchool(String schoolId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return _mockStudents.where((s) => s.schoolId == schoolId && s.isActive).toList();
  }
  
  static Future<Student> createStudent(Student student) async {
    await Future.delayed(Duration(milliseconds: 100));
    _mockStudents.add(student);
    return student;
  }
  
  static Future<Student> updateStudent(Student student) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _mockStudents.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _mockStudents[index] = student;
    }
    return student;
  }
  
  static Future<void> deleteStudent(String studentId) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _mockStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      _mockStudents[index] = _mockStudents[index].copyWith(isActive: false);
    }
  }
  
  // Utility Methods
  static Future<Map<String, dynamic>> getSchoolStats(String schoolId) async {
    await Future.delayed(Duration(milliseconds: 100));
    final students = _mockStudents.where((s) => s.schoolId == schoolId && s.isActive).length;
    final staff = _mockStaff.where((s) => s.schoolId == schoolId && s.isActive).length;
    
    return {
      'totalStudents': students,
      'totalStaff': staff,
    };
  }
  
  // Authentication for Staff
  static Future<Staff?> authenticateStaff(String staffId, String password) async {
    _initializeMockData();
    await Future.delayed(Duration(milliseconds: 100));
    
    try {
      return _mockStaff.firstWhere((staff) => 
        staff.staffId.toLowerCase() == staffId.toLowerCase() && 
        staff.password == password && 
        staff.isActive
      );
    } catch (e) {
      return null;
    }
  }
}