import 'package:postgres/postgres.dart';

/// Simple PostgreSQL configuration for local development
class PostgreSQLConfig {
  static const String host = 'localhost';
  static const int port = 5432;
  static const String database = 'smart_attendance';
  static const String username = 'postgres';
  static const String password = 'admin123';
  
  /// Get database connection using the current postgres package API
  static Future<Session> getConnection() async {
    try {
      // Using the updated postgres package API
      final connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
      );
      
      print('✅ PostgreSQL connection established');
      return connection;
    } catch (e) {
      print('❌ Failed to connect to PostgreSQL: $e');
      // For now, return a mock implementation to prevent compilation errors
      throw Exception('PostgreSQL connection failed: $e');
    }
  }
  
  /// Initialize database schema (run this once to set up tables)
  static Future<void> initializeSchema() async {
    try {
      final connection = await getConnection();
      
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
      
      // Create indexes for better performance
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