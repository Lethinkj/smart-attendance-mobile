
/// Service to initialize Hive adapters for local storage
class HiveInitService {
  static bool _isInitialized = false;

  /// Initialize Hive type adapters for all models
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register Hive adapters for models
      // Since our models don't extend HiveObject, we'll use the generic Box<dynamic>
      // and handle JSON serialization manually in the RealtimeStorageService

      print('Hive adapters initialized successfully');
      _isInitialized = true;
    } catch (e) {
      print('Error initializing Hive adapters: $e');
    }
  }

  /// Check if Hive is initialized
  static bool get isInitialized => _isInitialized;
}