import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test Supabase connection and find the correct anon key
class SupabaseConnectionTest {
  
  // Supabase project URL (from your connection string)
  static const String supabaseUrl = 'https://qctrtvzuazdvuwhwyops.supabase.co';
  
  // Common anon key patterns for testing (you'll need to provide the real one)
  static const List<String> testKeys = [
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjdHJ0dnp1YXpkdnV3aHd5b3BzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MDQ5NzcsImV4cCI6MjA1MzM4MDk3N30.KFVLNgBF_NdJKX3DqJL-r3Lg_XJBcnPwFzJ_5ufyBCM',
    // Add your actual anon key here
  ];
  
  static Future<void> testConnection() async {
    print('🔄 Testing Supabase connection...');
    print('📋 URL: $supabaseUrl');
    
    for (int i = 0; i < testKeys.length; i++) {
      final key = testKeys[i];
      print('\n🧪 Testing key ${i + 1}/${testKeys.length}...');
      
      try {
        final headers = {
          'Content-Type': 'application/json',
          'apikey': key,
          'Authorization': 'Bearer $key',
        };
        
        // Test basic connection
        final response = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/'),
          headers: headers,
        );
        
        print('   Status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          print('   ✅ Connection successful!');
          
          // Test tables access
          await _testTablesAccess(headers);
          return;
        } else {
          print('   ❌ Failed: ${response.body}');
        }
        
      } catch (e) {
        print('   💥 Error: $e');
      }
    }
    
    print('\n⚠️ All connection tests failed.');
    print('💡 Please provide your Supabase anon key from your project dashboard.');
  }
  
  static Future<void> _testTablesAccess(Map<String, String> headers) async {
    print('   🔍 Testing table access...');
    
    final tables = ['schools', 'staff', 'students'];
    
    for (final table in tables) {
      try {
        final response = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/$table?select=count'),
          headers: headers,
        );
        
        if (response.statusCode == 200) {
          print('   ✅ Table "$table": accessible');
        } else {
          print('   ⚠️ Table "$table": ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('   ❌ Table "$table": error - $e');
      }
    }
  }
  
  // Create tables if they don't exist
  static Future<void> createTablesIfNeeded() async {
    print('\n🔧 Checking if tables exist...');
    print('💡 Note: You may need to create tables in Supabase Dashboard SQL Editor:');
    
    final sql = '''
-- Create schools table
CREATE TABLE IF NOT EXISTS public.schools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    school_type VARCHAR(100),
    unique_id VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    total_students INTEGER DEFAULT 0,
    total_staff INTEGER DEFAULT 0,
    classes TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create staff table
CREATE TABLE IF NOT EXISTS public.staff (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    staff_id VARCHAR(50) UNIQUE NOT NULL,
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    role VARCHAR(100),
    assigned_classes TEXT[] DEFAULT '{}',
    rfid_tag VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    is_first_login BOOLEAN DEFAULT true,
    password VARCHAR(255) DEFAULT 'staff123',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create students table
CREATE TABLE IF NOT EXISTS public.students (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id VARCHAR(50) UNIQUE NOT NULL,
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    class_name VARCHAR(10),
    section VARCHAR(5),
    roll_number VARCHAR(20),
    parent_contact VARCHAR(20),
    rfid_tag VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

-- Create policies (allow all for now)
CREATE POLICY "Allow all operations on schools" ON public.schools FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations on staff" ON public.staff FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations on students" ON public.students FOR ALL USING (true) WITH CHECK (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_schools_unique_id ON public.schools(unique_id);
CREATE INDEX IF NOT EXISTS idx_staff_school_id ON public.staff(school_id);
CREATE INDEX IF NOT EXISTS idx_students_school_id ON public.students(school_id);
''';
    
    print('\n📋 SQL to run in Supabase Dashboard:');
    print('=' * 50);
    print(sql);
    print('=' * 50);
  }
}