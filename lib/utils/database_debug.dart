import 'dart:convert';
import 'package:http/http.dart' as http;

/// Debug service to test database queries and see actual data
class DatabaseDebugService {
  static const String supabaseUrl = 'https://qctrtvzuazdvuwhwyops.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjdHJ0dnp1YXpkdnV3aHd5b3BzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NzAzODksImV4cCI6MjA3NDM0NjM4OX0.1s53aIR3F8cqev5Jv7W6Zuc5kzmxdQvgA0RCLmiosjM';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
  };

  /// Test what's actually in the database
  static Future<void> debugDatabase() async {
    print('🔍 DEBUGGING DATABASE CONTENT...');
    print('=' * 50);
    
    try {
      // Check schools table
      print('\n📋 SCHOOLS TABLE:');
      final schoolsResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/schools?select=*'),
        headers: _headers,
      );
      
      if (schoolsResponse.statusCode == 200) {
        final schoolsData = json.decode(schoolsResponse.body);
        print('✅ Schools found: ${schoolsData.length}');
        for (var school in schoolsData) {
          print('  - ID: ${school['id']}, Name: ${school['name']}, Unique ID: ${school['unique_id']}');
        }
      } else {
        print('❌ Schools query failed: ${schoolsResponse.statusCode}');
        print('Response: ${schoolsResponse.body}');
      }
      
      // Check staff table
      print('\n👨‍🏫 STAFF TABLE:');
      final staffResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*'),
        headers: _headers,
      );
      
      if (staffResponse.statusCode == 200) {
        final staffData = json.decode(staffResponse.body);
        print('✅ Staff found: ${staffData.length}');
        for (var staff in staffData) {
          print('  - ID: ${staff['id']}, Name: ${staff['name']}, Staff ID: ${staff['staff_id']}, School ID: ${staff['school_id']}, Role: ${staff['role']}');
        }
      } else {
        print('❌ Staff query failed: ${staffResponse.statusCode}');
        print('Response: ${staffResponse.body}');
      }
      
      // Check students table
      print('\n👨‍🎓 STUDENTS TABLE:');
      final studentsResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/students?select=*'),
        headers: _headers,
      );
      
      if (studentsResponse.statusCode == 200) {
        final studentsData = json.decode(studentsResponse.body);
        print('✅ Students found: ${studentsData.length}');
        for (var student in studentsData) {
          print('  - ID: ${student['id']}, Name: ${student['name']}, Student ID: ${student['student_id']}, School ID: ${student['school_id']}');
        }
      } else {
        print('❌ Students query failed: ${studentsResponse.statusCode}');
        print('Response: ${studentsResponse.body}');
      }
      
      print('\n' + '=' * 50);
      print('🏁 DATABASE DEBUG COMPLETE');
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }
  
  /// Test specific queries that might be failing
  static Future<void> testSpecificQueries() async {
    print('🧪 TESTING SPECIFIC QUERIES...');
    print('=' * 50);
    
    try {
      // Test with is_active filter
      print('\n🔍 Testing staff with is_active=true:');
      final activeStaffResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*&is_active=eq.true'),
        headers: _headers,
      );
      
      if (activeStaffResponse.statusCode == 200) {
        final data = json.decode(activeStaffResponse.body);
        print('✅ Active staff found: ${data.length}');
      } else {
        print('❌ Active staff query failed: ${activeStaffResponse.statusCode}');
        print('Response: ${activeStaffResponse.body}');
      }
      
      // Test without is_active filter
      print('\n🔍 Testing staff without is_active filter:');
      final allStaffResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/staff?select=*'),
        headers: _headers,
      );
      
      if (allStaffResponse.statusCode == 200) {
        final data = json.decode(allStaffResponse.body);
        print('✅ All staff found: ${data.length}');
        
        // Check if is_active field exists
        if (data.isNotEmpty) {
          final firstStaff = data.first;
          print('📋 First staff record keys: ${firstStaff.keys.join(', ')}');
          print('📋 is_active field exists: ${firstStaff.containsKey('is_active')}');
          if (firstStaff.containsKey('is_active')) {
            print('📋 is_active value: ${firstStaff['is_active']}');
          }
        }
      } else {
        print('❌ All staff query failed: ${allStaffResponse.statusCode}');
        print('Response: ${allStaffResponse.body}');
      }
      
    } catch (e) {
      print('❌ Test error: $e');
    }
  }
}