import 'package:flutter/foundation.dart';

/// Application configuration and environment settings
class AppConfig {
  // Environment detection
  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => kReleaseMode;
  static bool get isProfile => kProfileMode;
  
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  
  static const String websocketUrl = String.fromEnvironment(
    'WS_BASE_URL', 
    defaultValue: 'ws://localhost:3000',
  );
  
  // App Information
  static const String appName = 'Smart Attendance';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  
  // Database Configuration
  static const String databaseName = 'smart_attendance.db';
  static const int databaseVersion = 1;
  
  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration syncTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // RFID Reader Configuration
  static const Duration bluetoothScanTimeout = Duration(seconds: 10);
  static const Duration bluetoothConnectionTimeout = Duration(seconds: 15);
  static const Duration nfcSessionTimeout = Duration(seconds: 30);
  static const Duration usbConnectionTimeout = Duration(seconds: 10);
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration splashDuration = Duration(seconds: 2);
  
  // Security Configuration
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 8);
  
  // Logging Configuration
  static const bool enableFileLogging = true;
  static const int maxLogFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxLogFiles = 5;
  
  // Performance Configuration
  static const int imageMemoryCacheSize = 100 * 1024 * 1024; // 100MB
  static const int networkCacheSize = 50 * 1024 * 1024; // 50MB
  
  // Feature Flags
  static const bool enableBiometricAuth = true;
  static const bool enableOfflineMode = true;
  static const bool enableDebugConsole = kDebugMode;
  static const bool enablePerformanceOverlay = false;
  
  // Device Support
  static const int minAndroidApiLevel = 21; // Android 5.0
  static const String minIosVersion = '13.0';
  
  // Error Reporting
  static const bool enableCrashReporting = true;
  static const bool enableAnalytics = false; // Set to true in production
  
  // Development helpers
  static const bool mockApiResponses = false;
  static const bool skipAuthentication = false;
}