import '../config/postgresql_config.dart';

/// Test PostgreSQL connection and database setup
class DatabaseTest {
  
  static Future<void> testConnection() async {
    print('🔍 Testing PostgreSQL connection...');
    
    try {
      // Test connection using our config
      final connection = await PostgreSQLConfig.getConnection();
      
      print('✅ Successfully connected to PostgreSQL');
      
      // Test if tables exist
      final result = await connection.execute(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
      );
      
      print('📋 Available tables:');
      for (final row in result) {
        print('  - ${row[0]}');
      }
      
      await connection.close();
      print('✅ Database test completed successfully');
      
    } catch (e) {
      print('❌ Database connection failed: $e');
      print('');
      print('🛠️ To fix this issue:');
      print('1. Make sure PostgreSQL is installed and running');
      print('2. Create database "smart_attendance"');  
      print('3. Update connection settings in postgresql_config.dart');
      print('4. Run the schema initialization');
    }
  }
  
  static Future<void> initializeSchema() async {
    print('🔧 Initializing database schema...');
    
    try {
      final connection = await PostgreSQLConfig.getConnection();
      
      // Create schools table
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS schools (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name VARCHAR(255) NOT NULL,
          address TEXT NOT NULL,
          phone VARCHAR(20) NOT NULL,
          email VARCHAR(255) NOT NULL,
          school_type VARCHAR(50) NOT NULL,
          unique_id VARCHAR(10) UNIQUE NOT NULL,
          is_active BOOLEAN DEFAULT true,
          total_students INTEGER DEFAULT 0,
          total_staff INTEGER DEFAULT 0,
          classes INTEGER DEFAULT 0,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      ''');
      
      // Create staff table
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS staff (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          staff_id VARCHAR(50) UNIQUE NOT NULL,
          school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255),
          phone VARCHAR(20),
          role VARCHAR(50) NOT NULL,
          assigned_classes TEXT DEFAULT '[]',
          rfid_tag VARCHAR(50),
          is_active BOOLEAN DEFAULT true,
          is_first_login BOOLEAN DEFAULT true,
          password VARCHAR(255) NOT NULL,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      ''');
      
      // Create students table
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS students (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          student_id VARCHAR(50) UNIQUE NOT NULL,
          school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
          name VARCHAR(255) NOT NULL,
          class_name VARCHAR(10) NOT NULL,
          section VARCHAR(5) NOT NULL,
          roll_number VARCHAR(20) NOT NULL,
          rfid_tag VARCHAR(50),
          parent_name VARCHAR(255) NOT NULL,
          parent_phone VARCHAR(20) NOT NULL,
          parent_email VARCHAR(255),
          date_of_birth DATE NOT NULL,
          address TEXT NOT NULL,
          is_active BOOLEAN DEFAULT true,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      ''');
      
      // Create indexes
      await connection.execute('CREATE INDEX IF NOT EXISTS idx_staff_school_id ON staff(school_id)');
      await connection.execute('CREATE INDEX IF NOT EXISTS idx_students_school_id ON students(school_id)');
      await connection.execute('CREATE INDEX IF NOT EXISTS idx_students_class ON students(school_id, class_name, section)');
      
      await connection.close();
      print('✅ Database schema initialized successfully');
      
    } catch (e) {
      print('❌ Schema initialization failed: $e');
    }
  }
}