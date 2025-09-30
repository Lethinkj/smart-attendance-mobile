import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://qctrtvzuazdvuwhwyops.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjdHJ0dnp1YXpkdnV3aHd5b3BzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NzAzODksImV4cCI6MjA3NDM0NjM4OX0.1s53aIR3F8cqev5Jv7W6Zuc5kzmxdQvgA0RCLmiosjM';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
  }
}