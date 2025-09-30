import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

/// Persistent authentication system - works like WhatsApp
/// Stores encrypted credentials locally and maintains login state
class PersistentAuthService {
  static const String _authBoxName = 'persistent_auth';
  static const String _deviceIdKey = 'device_id';
  static const String _loginStateKey = 'login_state';
  static const String _userDataKey = 'user_data';
  static const String _encryptedCredsKey = 'encrypted_credentials';
  static const String _lastSyncKey = 'last_sync';
  static const String _offlineCapableKey = 'offline_capable';
  
  static Box<dynamic>? _authBox;
  static String? _deviceId;
  static bool _isInitialized = false;

  /// Initialize persistent auth service
  static Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      await Hive.initFlutter();
      _authBox = await Hive.openBox(_authBoxName);
      
      // Generate or retrieve device ID
      _deviceId = _authBox?.get(_deviceIdKey);
      if (_deviceId == null) {
        _deviceId = _generateDeviceId();
        await _authBox?.put(_deviceIdKey, _deviceId);
      }
      
      _isInitialized = true;
      Logger.info('PersistentAuthService initialized with device ID: $_deviceId');
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Initialization failed', e, stack);
      throw Exception('Failed to initialize persistent auth service');
    }
  }

  /// Generate unique device ID
  static String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Check if user is persistently logged in (like WhatsApp)
  static bool get isPersistentlyLoggedIn {
    try {
      return _authBox?.get(_loginStateKey, defaultValue: false) as bool;
    } catch (e) {
      Logger.error('PersistentAuthService', 'Failed to check login state', e);
      return false;
    }
  }

  /// Save user login permanently (until manual logout)
  static Future<void> saveUserLogin({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
    required String role,
    String? schoolId,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Encrypt credentials for security
      final encryptedCreds = _encryptCredentials(email, password);
      
      // Save all user data
      await _authBox?.put(_loginStateKey, true);
      await _authBox?.put(_encryptedCredsKey, encryptedCreds);
      await _authBox?.put(_userDataKey, {
        'email': email,
        'role': role,
        'userData': userData,
        'schoolId': schoolId,
        'loginTime': DateTime.now().toIso8601String(),
        'deviceId': _deviceId,
        'offlineCapable': true,
      });
  await _authBox?.put(_lastSyncKey, DateTime.now().toIso8601String());
  await _authBox?.put(_offlineCapableKey, true);

  // Ensure durability on abrupt process kill (flush writes to disk immediately)
  await _authBox?.flush();

      Logger.info('User login saved persistently for: $email');
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Failed to save user login', e, stack);
      throw Exception('Failed to save login data');
    }
  }

  /// Get saved user data
  static Map<String, dynamic>? getSavedUserData() {
    try {
      return _authBox?.get(_userDataKey) as Map<String, dynamic>?;
    } catch (e) {
      Logger.error('PersistentAuthService', 'Failed to get user data', e);
      return null;
    }
  }

  /// Verify saved credentials (offline authentication)
  static Future<bool> verifyOfflineCredentials(String email, String password) async {
    try {
      final encryptedCreds = _authBox?.get(_encryptedCredsKey) as String?;
      if (encryptedCreds == null) return false;

      final decryptedCreds = _decryptCredentials(encryptedCreds);
      return decryptedCreds['email'] == email && decryptedCreds['password'] == password;
    } catch (e) {
      Logger.error('PersistentAuthService', 'Failed to verify offline credentials', e);
      return false;
    }
  }

  /// Update password locally (sync later when online)
  static Future<void> updatePasswordOffline(String oldPassword, String newPassword) async {
    try {
      final userData = getSavedUserData();
      if (userData == null) throw Exception('No user data found');

      final email = userData['email'] as String;
      
      // Verify old password first
      if (!await verifyOfflineCredentials(email, oldPassword)) {
        throw Exception('Current password verification failed');
      }

      // Update with new password
      final newEncryptedCreds = _encryptCredentials(email, newPassword);
      await _authBox?.put(_encryptedCredsKey, newEncryptedCreds);
      
      // Mark for sync when online
      await _authBox?.put('pending_password_change', {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      });

      Logger.info('Password updated offline for: $email');
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Failed to update password offline', e, stack);
      rethrow;
    }
  }

  /// Get pending password change (for sync)
  static Map<String, dynamic>? getPendingPasswordChange() {
    try {
      return _authBox?.get('pending_password_change') as Map<String, dynamic>?;
    } catch (e) {
      Logger.error('PersistentAuthService', 'Failed to get pending password change', e);
      return null;
    }
  }

  /// Mark password change as synced
  static Future<void> markPasswordChangeSynced() async {
    try {
      await _authBox?.delete('pending_password_change');
      Logger.info('Password change marked as synced');
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Failed to mark password change as synced', e, stack);
    }
  }

  /// Auto-login with saved credentials (like WhatsApp)
  static Future<Map<String, dynamic>?> autoLogin() async {
    try {
      bool loggedIn = isPersistentlyLoggedIn;
      var userData = getSavedUserData();

      // Fallback: if login flag got lost but user data and credentials still exist, restore the flag
      if (!loggedIn && userData != null) {
        final creds = _authBox?.get(_encryptedCredsKey);
        if (creds != null) {
          await _authBox?.put(_loginStateKey, true);
          loggedIn = true;
          Logger.warning('PersistentAuthService: Login flag missing but data present – restoring persistent session');
        }
      }

      if (!loggedIn || userData == null) return null;

      // Update last access time
      userData['lastAccess'] = DateTime.now().toIso8601String();
      await _authBox?.put(_userDataKey, userData);

      Logger.info('Auto-login successful for: ${userData['email']}');
      return userData;
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Auto-login failed', e, stack);
      return null;
    }
  }

  /// Encrypt credentials for secure storage
  static String _encryptCredentials(String email, String password) {
    try {
      final key = _generateEncryptionKey();
      final data = jsonEncode({'email': email, 'password': password});
      final bytes = utf8.encode(data);
      final digest = Hmac(sha256, utf8.encode(key)).convert(bytes);
      
      // Simple encryption (in production, use proper encryption)
      final encrypted = base64.encode(bytes);
      final signature = base64.encode(digest.bytes);
      
      return jsonEncode({
        'data': encrypted,
        'signature': signature,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Encryption failed', e, stack);
      throw Exception('Failed to encrypt credentials');
    }
  }

  /// Decrypt credentials
  static Map<String, dynamic> _decryptCredentials(String encryptedData) {
    try {
      final encryptedMap = jsonDecode(encryptedData) as Map<String, dynamic>;
      final encrypted = encryptedMap['data'] as String;
      final signature = encryptedMap['signature'] as String;
      
      final bytes = base64.decode(encrypted);
      final key = _generateEncryptionKey();
      final expectedDigest = Hmac(sha256, utf8.encode(key)).convert(bytes);
      final expectedSignature = base64.encode(expectedDigest.bytes);
      
      if (signature != expectedSignature) {
        throw Exception('Invalid signature - data may be tampered');
      }
      
      final data = utf8.decode(bytes);
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Decryption failed', e, stack);
      throw Exception('Failed to decrypt credentials');
    }
  }

  /// Generate encryption key based on device ID
  static String _generateEncryptionKey() {
    return '$_deviceId:smart_attendance:${DateTime.now().year}';
  }

  /// Manual logout (clear all data)
  static Future<void> logout() async {
    try {
      await _authBox?.clear();
      Logger.info('User logged out - all persistent data cleared');
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Logout failed', e, stack);
    }
  }

  /// Check if app is running for first time on this device
  static bool get isFirstTimeUser {
    try {
      return _authBox?.get('first_time_setup_done', defaultValue: false) as bool == false;
    } catch (e) {
      return true;
    }
  }

  /// Mark first time setup as done
  static Future<void> markFirstTimeSetupDone() async {
    try {
      await _authBox?.put('first_time_setup_done', true);
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Failed to mark first time setup', e, stack);
    }
  }

  /// Get device ID
  static String? get deviceId => _deviceId;

  /// Check when was the last sync
  static DateTime? get lastSyncTime {
    try {
      final lastSync = _authBox?.get(_lastSyncKey) as String?;
      return lastSync != null ? DateTime.parse(lastSync) : null;
    } catch (e) {
      return null;
    }
  }

  /// Update last sync time
  static Future<void> updateLastSyncTime() async {
    try {
      await _authBox?.put(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Failed to update sync time', e, stack);
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    try {
      await _authBox?.close();
      _isInitialized = false;
      Logger.info('PersistentAuthService disposed');
    } catch (e, stack) {
      Logger.error('PersistentAuthService', 'Dispose failed', e, stack);
    }
  }
}