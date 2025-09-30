import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/supabase_config.dart';
import 'services/realtime_storage_service.dart';
import 'core/services/persistent_auth_service.dart';
import 'core/services/whatsapp_style_auth_service.dart';

import 'ui/screens/splash/splash_screen.dart';

/// Main application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize Persistent Authentication Services
  await PersistentAuthService.initialize();
  
  // Initialize WhatsApp-style Authentication Service (handles auto-login)
  await WhatsAppStyleAuthService.initialize();
  
  // Initialize Real-time Storage Service
  await RealtimeStorageService().initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Run app
  runApp(
    const ProviderScope(
      child: SmartAttendanceApp(),
    ),
  );
}

class SmartAttendanceApp extends ConsumerWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Smart Attendance',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}