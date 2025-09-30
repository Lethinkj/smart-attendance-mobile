import 'package:hive_flutter/hive_flutter.dart';
import '../models/school.dart';
import '../models/attendance.dart';
import '../models/class_model.dart';
import '../models/device.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../models/sync_log.dart';
import '../utils/logger.dart';

/// Local storage service using Hive for offline-first operation
class StorageService {
  // Box instances
  static Box<dynamic>? _authStorage;
  static Box<School>? _schoolStorage;
  static Box<dynamic>? _staffStorage; // Use dynamic for non-Hive models
  static Box<Student>? _studentStorage;
  static Box<Attendance>? _attendanceStorage;
  static Box<ClassModel>? _classStorage;
  static Box<Device>? _deviceStorage;
  static Box<User>? _userStorage;
  static Box<SyncLog>? _syncLogStorage;
  static Box<dynamic>? _settingsStorage;

  // Box names
  static const String _authBox = 'auth';
  static const String _schoolsBox = 'schools';
  static const String _staffBox = 'staff';
  static const String _studentsBox = 'students';
  static const String _attendanceBox = 'attendance';
  static const String _classesBox = 'classes';
  static const String _devicesBox = 'devices';
  static const String _usersBox = 'users';
  static const String _syncLogsBox = 'sync_logs';
  static const String _settingsBox = 'settings';

  /// Initialize the storage service
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      
      // Register adapters only for models that have them
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SchoolAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(StudentAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(AttendanceAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ClassModelAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(DeviceAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(SyncLogAdapter());
      }

      // Open boxes
      _authStorage = await Hive.openBox(_authBox);
      _schoolStorage = await Hive.openBox<School>(_schoolsBox);
      _staffStorage = await Hive.openBox(_staffBox); // Dynamic box for Staff
      _studentStorage = await Hive.openBox<Student>(_studentsBox);
      _attendanceStorage = await Hive.openBox<Attendance>(_attendanceBox);
      _classStorage = await Hive.openBox<ClassModel>(_classesBox);
      _deviceStorage = await Hive.openBox<Device>(_devicesBox);
      _userStorage = await Hive.openBox<User>(_usersBox);
      _syncLogStorage = await Hive.openBox<SyncLog>(_syncLogsBox);
      _settingsStorage = await Hive.openBox(_settingsBox);

      Logger.info('Storage service initialized successfully');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to initialize storage service', e, stack);
      rethrow;
    }
  }

  /// Dispose of all resources
  static Future<void> dispose() async {
    try {
      await Hive.close();
      Logger.info('Storage service disposed');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to dispose storage service', e, stack);
    }
  }

  // Auth Methods - Enhanced for offline-first operation
  static Future<void> saveAuthTokens(String accessToken, String refreshToken) async {
    try {
      await _authStorage?.put('access_token', accessToken);
      await _authStorage?.put('refresh_token', refreshToken);
      await _authStorage?.put('token_saved_at', DateTime.now().toIso8601String());
      await _authStorage?.put('is_logged_in', true);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save auth tokens', e, stack);
    }
  }

  static String? get accessToken {
    try {
      return _authStorage?.get('access_token') as String?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get access token', e, stack);
      return null;
    }
  }

  static String? get refreshToken {
    try {
      return _authStorage?.get('refresh_token') as String?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get refresh token', e, stack);
      return null;
    }
  }

  static Future<void> clearAuthTokens() async {
    try {
      await _authStorage?.delete('access_token');
      await _authStorage?.delete('refresh_token');
      await _authStorage?.delete('token_saved_at');
      await _authStorage?.delete('is_logged_in');
      await _authStorage?.delete('current_user');
      await _authStorage?.delete('user_credentials');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to clear auth tokens', e, stack);
    }
  }

  // Enhanced Auth Methods for Offline-First Operation
  static Future<void> saveUserCredentials(String email, String password) async {
    try {
      await _authStorage?.put('user_credentials', {
        'email': email,
        'password': password,
        'saved_at': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save user credentials', e, stack);
    }
  }

  static Map<String, dynamic>? getUserCredentials() {
    try {
      return _authStorage?.get('user_credentials') as Map<String, dynamic>?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get user credentials', e, stack);
      return null;
    }
  }

  static Future<void> saveCurrentUser(Map<String, dynamic> userData) async {
    try {
      await _authStorage?.put('current_user', userData);
      await _authStorage?.put('user_saved_at', DateTime.now().toIso8601String());
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save current user', e, stack);
    }
  }

  static Map<String, dynamic>? getCurrentUser() {
    try {
      return _authStorage?.get('current_user') as Map<String, dynamic>?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get current user', e, stack);
      return null;
    }
  }

  static bool get isLoggedIn {
    try {
      return _authStorage?.get('is_logged_in', defaultValue: false) as bool;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get login status', e, stack);
      return false;
    }
  }

  static Future<void> updateUserPassword(String newPassword) async {
    try {
      final credentials = getUserCredentials();
      if (credentials != null) {
        credentials['password'] = newPassword;
        credentials['updated_at'] = DateTime.now().toIso8601String();
        await _authStorage?.put('user_credentials', credentials);
      }
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to update user password', e, stack);
    }
  }

  static Future<void> savePendingPasswordChange(Map<String, dynamic> changeData) async {
    try {
      await _authStorage?.put('pending_password_change', changeData);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save pending password change', e, stack);
    }
  }

  static Map<String, dynamic>? getPendingPasswordChange() {
    try {
      return _authStorage?.get('pending_password_change') as Map<String, dynamic>?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get pending password change', e, stack);
      return null;
    }
  }

  static Future<void> clearPendingPasswordChange() async {
    try {
      await _authStorage?.delete('pending_password_change');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to clear pending password change', e, stack);
    }
  }

  // School Methods
  static Future<void> saveSchool(School school) async {
    try {
      await _schoolStorage?.put(school.id, school);
      Logger.info('Saved school: ${school.id}');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save school', e, stack);
    }
  }

  static List<School> getAllSchools() {
    try {
      return _schoolStorage?.values.toList() ?? [];
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get all schools', e, stack);
      return [];
    }
  }

  static School? getSchool(String schoolId) {
    try {
      return _schoolStorage?.get(schoolId);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get school: $schoolId', e, stack);
      return null;
    }
  }

  // Student Methods
  static Future<void> saveStudent(Student student) async {
    try {
      await _studentStorage?.put(student.id, student);
      Logger.info('Saved student: ${student.id}');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save student', e, stack);
    }
  }

  static List<Student> getAllStudents() {
    try {
      return _studentStorage?.values.toList() ?? [];
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get students', e, stack);
      return [];
    }
  }

  static Student? getStudent(String id) {
    try {
      return _studentStorage?.get(id);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get student', e, stack);
      return null;
    }
  }

  // Staff Methods (using dynamic since Staff doesn't have Hive adapter)
  static Future<void> saveStaff(Map<String, dynamic> staff) async {
    try {
      await _staffStorage?.put(staff['id'], staff);
      Logger.info('Saved staff: ${staff['id']}');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save staff', e, stack);
    }
  }

  static List<Map<String, dynamic>> getAllStaff() {
    try {
      return _staffStorage?.values.cast<Map<String, dynamic>>().toList() ?? [];
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get staff', e, stack);
      return [];
    }
  }

  // Settings Methods
  static Future<void> saveSetting<T>(String key, T value) async {
    try {
      await _settingsStorage?.put(key, value);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save setting: $key', e, stack);
    }
  }

  static Future<void> setSetting<T>(String key, T value) async {
    return saveSetting(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return _settingsStorage?.get(key, defaultValue: defaultValue) as T?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get setting: $key', e, stack);
      return defaultValue;
    }
  }

  static Future<void> deleteSetting(String key) async {
    try {
      await _settingsStorage?.delete(key);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to delete setting: $key', e, stack);
    }
  }

  // Auth token methods (aliases for auth storage)
  static String? getAccessToken() {
    try {
      return _authStorage?.get('access_token') as String?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get access token', e, stack);
      return null;
    }
  }

  // Enhanced Attendance methods for offline-first operation
  static Future<void> saveAttendance(Attendance attendance) async {
    try {
      final key = attendance.localId ?? attendance.serverId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
      await _attendanceStorage?.put(key, attendance);
      Logger.info('Saved attendance record: $key');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save attendance', e, stack);
    }
  }

  static List<Attendance> getAllAttendance() {
    try {
      return _attendanceStorage?.values.toList() ?? [];
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get all attendance', e, stack);
      return [];
    }
  }

  static List<Attendance> getAttendanceByDate(DateTime date) {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return _attendanceStorage?.values
        .where((a) => a.markedAt.isAfter(startOfDay) && a.markedAt.isBefore(endOfDay))
        .toList() ?? [];
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get attendance by date', e, stack);
      return [];
    }
  }

  static List<Map<String, dynamic>> getUnsyncedAttendance() {
    try {
      return _attendanceStorage?.values
        .where((a) => !a.isSynced || (a.serverId == null || a.serverId!.isEmpty))
        .map((a) => a.toJson())
        .toList() ?? [];
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get unsynced attendance', e, stack);
      return [];
    }
  }

  static Future<void> markAttendanceSynced(String localId, String serverId) async {
    try {
      final attendance = _attendanceStorage?.get(localId);
      if (attendance != null) {
        // Update with server ID
        final updated = attendance.copyWith(serverId: serverId);
        await _attendanceStorage?.put(localId, updated);
      }
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to mark attendance as synced', e, stack);
    }
  }

  // Sync log methods
  static Future<void> addSyncLog(SyncLog syncLog) async {
    try {
      await _syncLogStorage?.put(syncLog.id, syncLog);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to add sync log', e, stack);
    }
  }

  // Class methods
  static Future<void> saveClass(ClassModel classModel) async {
    try {
      await _classStorage?.put(classModel.id, classModel);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save class', e, stack);
    }
  }

  // Clear all data
  static Future<void> clearAllData() async {
    try {
      await _authStorage?.clear();
      await _schoolStorage?.clear();
      await _staffStorage?.clear();
      await _studentStorage?.clear();
      await _attendanceStorage?.clear();
      await _classStorage?.clear();
      await _deviceStorage?.clear();
      await _userStorage?.clear();
      await _syncLogStorage?.clear();
      await _settingsStorage?.clear();
      Logger.info('All local data cleared');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to clear all data', e, stack);
    }
  }
}