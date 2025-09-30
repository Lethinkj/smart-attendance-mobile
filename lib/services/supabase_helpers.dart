import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/school.dart';
import '../models/staff.dart';

/// Helper functions for handling UUID and school ID conversions
class SupabaseHelpers {
  
  static const String supabaseUrl = 'https://qctrtvzuazdvuwhwyops.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjdHJ0dnp1YXpkdnV3aHd5b3BzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NzAzODksImV4cCI6MjA3NDM0NjM4OX0.1s53aIR3F8cqev5Jv7W6Zuc5kzmxdQvgA0RCLmiosjM';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
  };

  /// Convert school unique_id (like "3321") to actual database UUID
  static Future<String?> getSchoolUUIDFromUniqueId(String uniqueId) async {
    try {
      print('🔍 Looking up school UUID for unique_id: $uniqueId');
      
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=id&unique_id=eq.$uniqueId&is_active=eq.true'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final uuid = data.first['id'] as String;
          print('✅ Found school UUID: $uuid for unique_id: $uniqueId');
          return uuid;
        } else {
          print('⚠️ No school found with unique_id: $uniqueId');
          return null;
        }
      } else {
        print('❌ Failed to lookup school: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ getSchoolUUIDFromUniqueId error: $e');
      return null;
    }
  }
  
  /// Create staff with proper school UUID lookup
  static Future<Staff> createStaffWithUniqueId(String schoolUniqueId, Staff staff) async {
    try {
      print('🔄 Creating staff for school unique_id: $schoolUniqueId');
      
      // First, get the actual school UUID
      final schoolUUID = await getSchoolUUIDFromUniqueId(schoolUniqueId);
      if (schoolUUID == null) {
        throw Exception('School not found with unique_id: $schoolUniqueId');
      }
      
      // Update staff with correct school UUID
      final updatedStaff = staff.copyWith(schoolId: schoolUUID);
      
      print('🔄 Creating staff: ${updatedStaff.name} for school UUID: $schoolUUID');
      
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/staff'),
        headers: _headers,
        body: json.encode(updatedStaff.toJson()),
      );
      
      if (response.statusCode == 201) {
        print('✅ Staff created successfully: ${updatedStaff.name}');
        return updatedStaff;
      } else {
        print('❌ Failed to create staff: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to create staff: ${response.body}');
      }
    } catch (e) {
      print('❌ createStaffWithUniqueId error: $e');
      rethrow;
    }
  }
  
  /// Generate staff accounts for a school using unique_id
  static Future<List<Staff>> generateStaffAccountsForSchool(String schoolUniqueId, String schoolType) async {
    try {
      print('🔄 Generating staff accounts for school: $schoolUniqueId, type: $schoolType');
      
      // Get the school UUID
      final schoolUUID = await getSchoolUUIDFromUniqueId(schoolUniqueId);
      if (schoolUUID == null) {
        throw Exception('School not found with unique_id: $schoolUniqueId');
      }
      
      // Get class list based on school type
      final classes = _getClassListForSchoolType(schoolType);
      print('📋 Creating staff for ${classes.length} classes: ${classes.join(', ')}');
      
      List<Staff> createdStaff = [];
      
      for (int i = 0; i < classes.length; i++) {
        final className = classes[i];
        
        // Generate staff ID
        final count = await _getStaffCountForSchool(schoolUUID);
        final staffId = '${schoolUniqueId}STF${(count + i + 1).toString().padLeft(3, '0')}';
        
        final staff = Staff(
          staffId: staffId,
          schoolId: schoolUUID, // Use the proper UUID
          name: 'Class $className Teacher',
          email: '${staffId.toLowerCase()}@${schoolUniqueId.toLowerCase()}.edu',
          phone: '+91-${9000000000 + i}',
          role: 'Teacher',
          assignedClasses: [className],
          password: 'staff123',
          isFirstLogin: true,
        );
        
        try {
          final response = await http.post(
            Uri.parse('$supabaseUrl/rest/v1/staff'),
            headers: _headers,
            body: json.encode(staff.toJson()),
          );
          
          if (response.statusCode == 201) {
            createdStaff.add(staff);
            print('✅ Created staff: ${staff.name} (${staff.staffId})');
          } else {
            print('❌ Failed to create staff ${staff.name}: ${response.statusCode}');
            print('Response: ${response.body}');
          }
        } catch (e) {
          print('❌ Error creating staff ${staff.name}: $e');
        }
      }
      
      print('📊 Created ${createdStaff.length} out of ${classes.length} staff accounts');
      return createdStaff;
      
    } catch (e) {
      print('❌ generateStaffAccountsForSchool error: $e');
      return [];
    }
  }
  
  static Future<int> _getStaffCountForSchool(String schoolUUID) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=id&school_id=eq.$schoolUUID'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.length;
      }
      return 0;
    } catch (e) {
      print('❌ _getStaffCountForSchool error: $e');
      return 0;
    }
  }
  
  static List<String> _getClassListForSchoolType(String schoolType) {
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
}