import 'dart:developer' as developer;

/// Simple logging utility for the Smart Attendance System
class Logger {
  static bool _isInitialized = false;
  static LogLevel _logLevel = LogLevel.info;
  
  /// Initialize the logger
  static void initialize({LogLevel logLevel = LogLevel.info}) {
    _logLevel = logLevel;
    _isInitialized = true;
    info('Logger initialized with level: ${logLevel.name}');
  }
  
  /// Log an info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;
    if (_logLevel.index > LogLevel.info.index) return;
    
    _log('INFO', message, error, stackTrace);
  }
  
  /// Log a warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;
    if (_logLevel.index > LogLevel.warning.index) return;
    
    _log('WARN', message, error, stackTrace);
  }
  
  /// Log an error message
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;
    if (_logLevel.index > LogLevel.error.index) return;
    
    _log('ERROR', message, error, stackTrace);
  }
  
  /// Log a debug message
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;
    if (_logLevel.index > LogLevel.debug.index) return;
    
    _log('DEBUG', message, error, stackTrace);
  }
  
  /// Internal logging method
  static void _log(String level, String message, Object? error, StackTrace? stackTrace) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] $message';
    
    // Use developer.log for better debugging in Flutter
    developer.log(
      logMessage,
      name: 'SmartAttendance',
      error: error,
      stackTrace: stackTrace,
      level: _getLevelValue(level),
    );
    
    // Also print to console for visibility
    print(logMessage);
    if (error != null) {
      print('Error: $error');
    }
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
  
  /// Get log level value for developer.log
  static int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 800;
    }
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}