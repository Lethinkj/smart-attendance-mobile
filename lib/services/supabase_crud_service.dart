import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/school.dart';
import '../models/staff.dart';

/// Enhanced Supabase service with better error handling and CRUD operations
class SupabaseCRUDService {
  
  static const String supabaseUrl = 'https://qctrtvzuazdvuwhwyops.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjdHJ0dnp1YXpkdnV3aHd5b3BzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NzAzODksImV4cCI6MjA3NDM0NjM4OX0.1s53aIR3F8cqev5Jv7W6Zuc5kzmxdQvgA0RCLmiosjM';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
  };

  // School Management with better error handling
  static Future<School> createOrUpdateSchool(School school) async {
    try {
      print('🔄 Attempting to create/update school: ${school.name} (${school.uniqueId})');
      
      // First, check if school with this unique_id already exists
      final existingResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=*&unique_id=eq.${school.uniqueId}'),
        headers: _headers,
      );
      
      if (existingResponse.statusCode == 200) {
        final List<dynamic> existingData = json.decode(existingResponse.body);
        
        if (existingData.isNotEmpty) {
          // School exists, update it instead
          print('📝 School exists with unique_id: ${school.uniqueId}, updating instead');
          final existingSchool = School.fromJson(existingData.first);
          final updatedSchool = existingSchool.copyWith(
            name: school.name,
            address: school.address,
            phone: school.phone,
            email: school.email,
            schoolType: school.schoolType,
            classes: school.classes,
            totalStudents: school.totalStudents,
            totalStaff: school.totalStaff,
          );
          
          return await updateSchoolById(existingSchool.id, updatedSchool);
        }
      }
      
      // School doesn't exist, create new one
      return await createNewSchool(school);
      
    } catch (e) {
      print('❌ createOrUpdateSchool error: $e');
      rethrow;
    }
  }
  
  static Future<School> createNewSchool(School school) async {
    try {
      print('🔄 Creating new school: ${school.name}');
      
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=*'),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: json.encode(school.toJson()),
      );
      
      if (response.statusCode == 201) {
        print('✅ School created successfully: ${school.name}');
        
        // Parse the returned school data to get the UUID
        final responseData = json.decode(response.body);
        if (responseData is List && responseData.isNotEmpty) {
          final createdSchool = School.fromJson(responseData.first);
          print('📋 Created school with UUID: ${createdSchool.id}');
          return createdSchool;
        } else {
          // Fallback: fetch the created school by unique_id
          print('⏳ Fetching created school by unique_id...');
          await Future.delayed(Duration(milliseconds: 500)); // Small delay for consistency
          final fetchedSchool = await _getSchoolByUniqueId(school.uniqueId);
          if (fetchedSchool != null) {
            print('📋 Fetched created school with UUID: ${fetchedSchool.id}');
            return fetchedSchool;
          }
        }
        
        return school; // Last fallback
      } else {
        print('❌ Failed to create school: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to create school: ${response.body}');
      }
    } catch (e) {
      print('❌ createNewSchool error: $e');
      rethrow;
    }
  }
  
  static Future<School> updateSchoolById(String schoolId, School school) async {
    try {
      print('🔄 Updating school: ${school.name} (ID: $schoolId)');
      
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/schools?id=eq.$schoolId'),
        headers: _headers,
        body: json.encode(school.toJson()),
      );
      
      if (response.statusCode == 204) {
        print('✅ School updated successfully: ${school.name}');
        return school.copyWith(); // Return updated school with new timestamp
      } else {
        print('❌ Failed to update school: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to update school: ${response.body}');
      }
    } catch (e) {
      print('❌ updateSchoolById error: $e');
      rethrow;
    }
  }

  // Staff Management with UUID handling
  static Future<Staff> createStaffWithAutoConversion(Staff staff) async {
    try {
      print('🔄 Creating staff: ${staff.name} for school: ${staff.schoolId}');
      
      // Check if schoolId is a UUID or unique_id
      Staff finalStaff = staff;
      if (!_isValidUUID(staff.schoolId)) {
        print('🔍 Converting school unique_id to UUID: ${staff.schoolId}');
        final schoolUUID = await _getSchoolUUIDFromUniqueId(staff.schoolId);
        if (schoolUUID == null) {
          throw Exception('School not found with unique_id: ${staff.schoolId}');
        }
        finalStaff = staff.copyWith(schoolId: schoolUUID);
        print('✅ Converted to UUID: $schoolUUID');
      }
      
      // Check if staff with this staff_id already exists
      final existingResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*&staff_id=eq.${finalStaff.staffId}'),
        headers: _headers,
      );
      
      if (existingResponse.statusCode == 200) {
        final List<dynamic> existingData = json.decode(existingResponse.body);
        
        if (existingData.isNotEmpty) {
          print('📝 Staff exists with staff_id: ${finalStaff.staffId}, updating instead');
          final existingStaff = Staff.fromJson(existingData.first);
          return await updateStaffById(existingStaff.id, finalStaff);
        }
      }
      
      // Create new staff with select parameter to get the created record
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*'),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: json.encode(finalStaff.toJson()),
      );
      
      if (response.statusCode == 201) {
        print('✅ Staff created successfully: ${finalStaff.name}');
        
        // Parse the returned staff data to get the UUID
        final responseData = json.decode(response.body);
        if (responseData is List && responseData.isNotEmpty) {
          final createdStaff = Staff.fromJson(responseData.first);
          print('📋 Created staff with UUID: ${createdStaff.id}');
          return createdStaff;
        } else {
          // Fallback: return the staff with original data
          return finalStaff;
        }
      } else {
        print('❌ Failed to create staff: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to create staff: ${response.body}');
      }
      
    } catch (e) {
      print('❌ createStaffWithAutoConversion error: $e');
      rethrow;
    }
  }
  
  static Future<Staff> updateStaffById(String staffId, Staff staff) async {
    try {
      print('🔄 Updating staff: ${staff.name} (ID: $staffId)');
      
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/staff?id=eq.$staffId'),
        headers: _headers,
        body: json.encode(staff.toJson()),
      );
      
      if (response.statusCode == 204) {
        print('✅ Staff updated successfully: ${staff.name}');
        return staff.copyWith(); // Return updated staff
      } else {
        print('❌ Failed to update staff: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to update staff: ${response.body}');
      }
    } catch (e) {
      print('❌ updateStaffById error: $e');
      rethrow;
    }
  }

  // Bulk Staff Generation (using School object directly)
  static Future<List<Staff>> generateStaffAccountsForSchool(School school, String schoolType) async {
    try {
      print('🔄 Generating staff accounts for school: ${school.name} (UUID: ${school.id}, Unique ID: ${school.uniqueId})');
      
      // Use the school's UUID directly
      final schoolUUID = school.id;
      if (schoolUUID.isEmpty) {
        throw Exception('School UUID is empty for school: ${school.name}');
      }
      
      // Get classes for school type
      final classes = _getClassesForSchoolType(schoolType);
      print('📋 Creating staff for ${classes.length} classes: ${classes.join(', ')}');
      
      List<Staff> createdStaff = [];
      
      for (int i = 0; i < classes.length; i++) {
        final className = classes[i];
        final staffRole = _getStaffRoleForClass(className, i, classes.length);
        final staffId = '${school.uniqueId}STF${(i + 1).toString().padLeft(3, '0')}'; // Format: 444STF001, 444STF002, etc.
        
        final staff = Staff(
          staffId: staffId,
          schoolId: schoolUUID,
          name: 'Class $className Teacher',
          email: '${staffId.toLowerCase()}@${school.uniqueId.toLowerCase()}.edu',
          phone: '+91-${9000000000 + i}',
          role: staffRole, // Using simplified roles: Principal, Staff, Supporting Staff
          assignedClasses: [className],
          password: 'staff123',
          isFirstLogin: true,
        );
        
        try {
          final createdStaffMember = await createStaffWithAutoConversion(staff);
          createdStaff.add(createdStaffMember);
          print('✅ Created staff ${i + 1}/${classes.length}: ${staff.name} (${staff.role})');
        } catch (e) {
          print('❌ Failed to create staff ${staff.name}: $e');
          // Continue with next staff member
        }
      }
      
      print('📊 Successfully created ${createdStaff.length} out of ${classes.length} staff accounts');
      return createdStaff;
      
    } catch (e) {
      print('❌ generateStaffAccountsForSchool error: $e');
      return [];
    }
  }

  // Helper Methods
  static bool _isValidUUID(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }
  
  static Future<String?> _getSchoolUUIDFromUniqueId(String uniqueId) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=id&unique_id=eq.$uniqueId&is_active=eq.true'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data.first['id'] as String;
        }
      }
      return null;
    } catch (e) {
      print('❌ _getSchoolUUIDFromUniqueId error: $e');
      return null;
    }
  }
  
  static Future<School?> _getSchoolByUniqueId(String uniqueId) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=*&unique_id=eq.$uniqueId&is_active=eq.true'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return School.fromJson(data.first);
        }
      }
      return null;
    } catch (e) {
      print('❌ _getSchoolByUniqueId error: $e');
      return null;
    }
  }
  
  static List<String> _getClassesForSchoolType(String schoolType) {
    switch (schoolType) {
      case 'Elementary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8'];
      case 'Secondary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
      case 'Senior Secondary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
      default:
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8'];
    }
  }
  
  static String _getStaffRoleForClass(String className, int index, int totalClasses) {
    // First staff member is Principal
    if (index == 0) return 'Principal';
    
    // Last 2 staff members are Supporting Staff
    if (index >= totalClasses - 2) return 'Supporting Staff';
    
    // All others are regular Staff
    return 'Staff';
  }

  // Utility: Test database operations
  static Future<void> testAllOperations() async {
    print('🧪 Testing all database operations...');
    
    try {
      // Test school retrieval
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=count'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        print('✅ READ operations: Working');
      } else {
        print('❌ READ operations: Failed (${response.statusCode})');
      }
      
      print('📊 Database test completed');
    } catch (e) {
      print('❌ Database test failed: $e');
    }
  }
}