import 'package:hive_flutter/hive_flutter.dart';import 'package:hive_flutter/hive_flutter.dart';import 'package:hive_flutter/hive_flutter.dart';import 'package:hive_flutter/hive_flutter.dart';import 'package:hive_flutter/hive_flutter.dart';



class StorageService {import 'package:connectivity_plus/connectivity_plus.dart';

  static const String _authBox = 'auth';

  static const String _settingsBox = 'settings';import '../models/attendance.dart';import '../models/attendance.dart';



  static Box<dynamic>? _authStorage;import '../models/student.dart';

  static Box<dynamic>? _settingsStorage;

import '../models/user.dart';import '../models/student.dart';import '../models/attendance.dart';import '../models/attendance.dart';

  static Future<void> initialize() async {

    try {import '../models/school.dart';

      await Hive.initFlutter();

      import '../models/class_model.dart';import '../models/class_model.dart';

      _authStorage = await Hive.openBox(_authBox);

      _settingsStorage = await Hive.openBox(_settingsBox);import '../models/device.dart';

      

      print('Storage boxes initialized successfully');import '../models/sync_log.dart';import '../models/user.dart';import '../models/student.dart';import '../models/student.dart';

    } catch (e) {

      print('Storage initialization failed: $e');import '../utils/logger.dart';

      throw Exception('Failed to initialize storage: $e');

    }import '../models/device.dart';

  }

class StorageService {

  // Auth methods

  static Future<void> saveAuthToken(String token) async {  static const String _authBox = 'auth';import '../models/school.dart';import '../models/class_model.dart';import '../models/class_model.dart';

    await _authStorage?.put('token', token);

  }  static const String _userBox = 'users';



  static String? getAuthToken() {  static const String _schoolBox = 'schools';import '../models/sync_log.dart';

    return _authStorage?.get('token');

  }  static const String _studentBox = 'students';



  static Future<void> clearAuthToken() async {  static const String _classBox = 'classes';import '../utils/logger.dart';import '../models/user.dart';import '../models/user.dart';

    await _authStorage?.delete('token');

  }  static const String _attendanceBox = 'attendance';



  static Future<void> saveCurrentUser(Map<String, dynamic> user) async {  static const String _deviceBox = 'devices';

    await _authStorage?.put('current_user', user);

  }  static const String _syncBox = 'sync_logs';



  static Map<String, dynamic>? getCurrentUser() {  static const String _settingsBox = 'settings';/// Local storage service using Hive for offline-first operationimport '../utils/logger.dart';import '../models/device.dart';

    final userData = _authStorage?.get('current_user');

    if (userData != null) {

      return Map<String, dynamic>.from(userData);

    }  static Box<dynamic>? _authStorage;class StorageService {

    return null;

  }  static Box<User>? _userStorage;



  static Future<void> clearCurrentUser() async {  static Box<School>? _schoolStorage;  // Box names - consistent across app lifecycleimport '../models/school.dart';

    await _authStorage?.delete('current_user');

  }  static Box<Student>? _studentStorage;



  // Settings methods  static Box<ClassModel>? _classStorage;  static const String _attendanceBox = 'attendance';

  static Future<void> saveSetting(String key, dynamic value) async {

    await _settingsStorage?.put(key, value);  static Box<Attendance>? _attendanceStorage;

  }

  static Box<Device>? _deviceStorage;  static const String _studentsBox = 'students';/// Simple storage service using Hive for offline-first operationimport '../models/sync_log.dart';

  static T? getSetting<T>(String key) {

    return _settingsStorage?.get(key) as T?;  static Box<SyncLog>? _syncStorage;

  }

  static Box<dynamic>? _settingsStorage;  static const String _classesBox = 'classes';

  // Utility methods

  static Future<void> clearAllData() async {

    await _authStorage?.clear();

    await _settingsStorage?.clear();  static Future<void> initialize() async {  static const String _usersBox = 'users';class StorageService {import '../utils/logger.dart';

  }

    try {

  static Future<void> close() async {

    await _authStorage?.close();      await Hive.initFlutter();  static const String _devicesBox = 'devices';

    await _settingsStorage?.close();

  }      

}
      // Register adapters  static const String _schoolsBox = 'schools';  // Box names 

      if (!Hive.isAdapterRegistered(0)) {

        Hive.registerAdapter(UserAdapter());  static const String _syncLogsBox = 'sync_logs';

      }

      if (!Hive.isAdapterRegistered(1)) {  static const String _settingsBox = 'settings';  static const String _attendanceBox = 'attendance';/// Local storage service using Hive for offline-first operation

        Hive.registerAdapter(SchoolAdapter());

      }  static const String _authBox = 'auth';

      if (!Hive.isAdapterRegistered(2)) {

        Hive.registerAdapter(StudentAdapter());    static const String _studentsBox = 'students';class StorageService {

      }

      if (!Hive.isAdapterRegistered(3)) {  // Box instances - initialized during startup

        Hive.registerAdapter(ClassModelAdapter());

      }  static late Box<Attendance> _attendanceBoxInstance;  static const String _usersBox = 'users';  // Box names - consistent across app lifecycle

      if (!Hive.isAdapterRegistered(4)) {

        Hive.registerAdapter(AttendanceAdapter());  static late Box<Student> _studentsBoxInstance;

      }

      if (!Hive.isAdapterRegistered(5)) {  static late Box<ClassModel> _classesBoxInstance;  static const String _settingsBox = 'settings';  static const String _attendanceBox = 'attendance';

        Hive.registerAdapter(DeviceAdapter());

      }  static late Box<User> _usersBoxInstance;

      if (!Hive.isAdapterRegistered(6)) {

        Hive.registerAdapter(SyncLogAdapter());  static late Box<Device> _devicesBoxInstance;  static const String _authBox = 'auth';  static const String _studentsBox = 'students';

      }

  static late Box<School> _schoolsBoxInstance;

      // Open boxes

      _authStorage = await Hive.openBox(_authBox);  static late Box<SyncLog> _syncLogsBoxInstance;    static const String _classesBox = 'classes';

      _userStorage = await Hive.openBox<User>(_userBox);

      _schoolStorage = await Hive.openBox<School>(_schoolBox);  static late Box<dynamic> _settingsBoxInstance;

      _studentStorage = await Hive.openBox<Student>(_studentBox);

      _classStorage = await Hive.openBox<ClassModel>(_classBox);  static late Box<dynamic> _authBoxInstance;  // Box instances  static const String _usersBox = 'users';

      _attendanceStorage = await Hive.openBox<Attendance>(_attendanceBox);

      _deviceStorage = await Hive.openBox<Device>(_deviceBox);

      _syncStorage = await Hive.openBox<SyncLog>(_syncBox);

      _settingsStorage = await Hive.openBox(_settingsBox);  /// Initialize all Hive boxes and register adapters  static Box<Attendance>? _attendanceBoxInstance;  static const String _devicesBox = 'devices';



      Logger.info('Storage boxes initialized successfully');  static Future<void> initialize() async {

    } catch (e) {

      Logger.error('Storage initialization failed: $e');    try {  static Box<Student>? _studentsBoxInstance;  static const String _schoolsBox = 'schools';

      throw Exception('Failed to initialize storage: $e');

    }      Logger.info('Initializing storage service...');

  }

        static Box<User>? _usersBoxInstance;  static const String _syncLogsBox = 'sync_logs';

  // Auth methods

  static Future<void> saveAuthToken(String token) async {      // Initialize Hive

    await _authStorage?.put('token', token);

  }      await Hive.initFlutter();  static Box<dynamic>? _settingsBoxInstance;  static const String _settingsBox = 'settings';



  static String? getAuthToken() {      

    return _authStorage?.get('token');

  }      // Register type adapters for custom objects  static Box<dynamic>? _authBoxInstance;  static const String _authBox = 'auth';



  static Future<void> clearAuthToken() async {      _registerAdapters();

    await _authStorage?.delete('token');

  }        



  static Future<void> saveCurrentUser(User user) async {      // Open all required boxes

    await _authStorage?.put('current_user', user.toJson());

  }      await _openBoxes();  /// Initialize storage  // Box instances



  static User? getCurrentUser() {      

    final userData = _authStorage?.get('current_user');

    if (userData != null) {      Logger.info('Storage service initialized successfully');  static Future<void> initialize() async {  static late Box<Attendance> _attendanceBoxInstance;

      return User.fromJson(Map<String, dynamic>.from(userData));

    }    } catch (e, stack) {

    return null;

  }      Logger.error('StorageService', 'Failed to initialize storage service', e, stack);    try {  static late Box<Student> _studentsBoxInstance;



  static Future<void> clearCurrentUser() async {      rethrow;

    await _authStorage?.delete('current_user');

  }    }      Logger.info('Initializing storage service...');  static late Box<ClassModel> _classesBoxInstance;



  // User methods  }

  static Future<void> saveUser(User user) async {

    await _userStorage?.put(user.id, user);        static late Box<User> _usersBoxInstance;

  }

  /// Register Hive type adapters for custom objects

  static User? getUser(String id) {

    return _userStorage?.get(id);  static void _registerAdapters() {      // Open basic boxes  static late Box<Device> _devicesBoxInstance;

  }

    // Register adapters only if not already registered

  static List<User> getAllUsers() {

    return _userStorage?.values.toList() ?? [];    try {      _attendanceBoxInstance = await Hive.openBox<Attendance>(_attendanceBox);  static late Box<School> _schoolsBoxInstance;

  }

      if (!Hive.isAdapterRegistered(0)) {

  // School methods

  static Future<void> saveSchool(School school) async {        Hive.registerAdapter(AttendanceAdapter());      _studentsBoxInstance = await Hive.openBox<Student>(_studentsBox);  static late Box<SyncLog> _syncLogsBoxInstance;

    await _schoolStorage?.put(school.id, school);

  }      }



  static School? getSchool(String id) {      if (!Hive.isAdapterRegistered(1)) {      _usersBoxInstance = await Hive.openBox<User>(_usersBox);  static late Box<dynamic> _settingsBoxInstance;

    return _schoolStorage?.get(id);

  }        Hive.registerAdapter(StudentAdapter());



  static List<School> getAllSchools() {      }      _settingsBoxInstance = await Hive.openBox<dynamic>(_settingsBox);  static late Box<dynamic> _authBoxInstance;

    return _schoolStorage?.values.toList() ?? [];

  }      if (!Hive.isAdapterRegistered(2)) {



  // Student methods        Hive.registerAdapter(ClassModelAdapter());      _authBoxInstance = await Hive.openBox<dynamic>(_authBox);  

  static Future<void> saveStudent(Student student) async {

    await _studentStorage?.put(student.id, student);      }

  }

      if (!Hive.isAdapterRegistered(3)) {        /// Initialize all Hive boxes and register adapters

  static Student? getStudent(String id) {

    return _studentStorage?.get(id);        Hive.registerAdapter(UserAdapter());

  }

      }      Logger.info('Storage service initialized successfully');  static Future<void> initialize() async {

  static Student? getStudentByRfid(String rfidTag) {

    return _studentStorage?.values.firstWhere(      if (!Hive.isAdapterRegistered(4)) {

      (student) => student.rfidTag == rfidTag,

      orElse: () => null as Student,        Hive.registerAdapter(DeviceAdapter());    } catch (e, stack) {    try {

    );

  }      }



  static List<Student> getStudentsByClass(String classId) {      if (!Hive.isAdapterRegistered(5)) {      Logger.error('StorageService', 'Failed to initialize storage service', e, stack);      await Hive.initFlutter();

    return _studentStorage?.values

        .where((student) => student.classId == classId)        Hive.registerAdapter(SchoolAdapter());

        .toList() ?? [];

  }      }      rethrow;      



  static List<Student> getAllStudents() {      if (!Hive.isAdapterRegistered(6)) {

    return _studentStorage?.values.toList() ?? [];

  }        Hive.registerAdapter(SyncLogAdapter());    }      // Register adapters



  // Class methods      }

  static Future<void> saveClass(ClassModel classModel) async {

    await _classStorage?.put(classModel.id, classModel);    } catch (e) {  }      _registerAdapters();

  }

      Logger.warning('Some adapters already registered, continuing...');

  static ClassModel? getClass(String id) {

    return _classStorage?.get(id);    }      

  }

  }

  static List<ClassModel> getClassesBySchool(String schoolId) {

    return _classStorage?.values  // ATTENDANCE METHODS      // Open boxes

        .where((classModel) => classModel.schoolId == schoolId)

        .toList() ?? [];  /// Open all Hive boxes

  }

  static Future<void> _openBoxes() async {  static Future<String> addAttendance(Attendance attendance) async {      _attendanceBoxInstance = await Hive.openBox<Attendance>(_attendanceBox);

  static List<ClassModel> getAllClasses() {

    return _classStorage?.values.toList() ?? [];    _attendanceBoxInstance = await Hive.openBox<Attendance>(_attendanceBox);

  }

    _studentsBoxInstance = await Hive.openBox<Student>(_studentsBox);    try {      _studentsBoxInstance = await Hive.openBox<Student>(_studentsBox);

  // Attendance methods

  static Future<void> saveAttendance(Attendance attendance) async {    _classesBoxInstance = await Hive.openBox<ClassModel>(_classesBox);

    await _attendanceStorage?.put(attendance.id, attendance);

  }    _usersBoxInstance = await Hive.openBox<User>(_usersBox);      final key = await _attendanceBoxInstance!.add(attendance);      _classesBoxInstance = await Hive.openBox<ClassModel>(_classesBox);



  static Attendance? getAttendance(String id) {    _devicesBoxInstance = await Hive.openBox<Device>(_devicesBox);

    return _attendanceStorage?.get(id);

  }    _schoolsBoxInstance = await Hive.openBox<School>(_schoolsBox);      return key.toString();      _usersBoxInstance = await Hive.openBox<User>(_usersBox);



  static List<Attendance> getAttendanceByDate(DateTime date) {    _syncLogsBoxInstance = await Hive.openBox<SyncLog>(_syncLogsBox);

    final startOfDay = DateTime(date.year, date.month, date.day);

    final endOfDay = startOfDay.add(const Duration(days: 1));    _settingsBoxInstance = await Hive.openBox<dynamic>(_settingsBox);    } catch (e, stack) {      _devicesBoxInstance = await Hive.openBox<Device>(_devicesBox);

    

    return _attendanceStorage?.values    _authBoxInstance = await Hive.openBox<dynamic>(_authBox);

        .where((attendance) => 

          attendance.timestamp.isAfter(startOfDay) &&  }      Logger.error('StorageService', 'Failed to add attendance record', e, stack);      _schoolsBoxInstance = await Hive.openBox<School>(_schoolsBox);

          attendance.timestamp.isBefore(endOfDay))

        .toList() ?? [];

  }

  // ATTENDANCE METHODS      rethrow;      _syncLogsBoxInstance = await Hive.openBox<SyncLog>(_syncLogsBox);

  static List<Attendance> getAttendanceByStudent(String studentId) {

    return _attendanceStorage?.values  /// Add a new attendance record

        .where((attendance) => attendance.studentId == studentId)

        .toList() ?? [];  static Future<String> addAttendance(Attendance attendance) async {    }      _settingsBoxInstance = await Hive.openBox<dynamic>(_settingsBox);

  }

    try {

  static List<Attendance> getAllAttendance() {

    return _attendanceStorage?.values.toList() ?? [];      final key = await _attendanceBoxInstance.add(attendance);  }      _authBoxInstance = await Hive.openBox<dynamic>(_authBox);

  }

      attendance.localId = key.toString();

  // Device methods

  static Future<void> saveDevice(Device device) async {      await _attendanceBoxInstance.put(key, attendance);      

    await _deviceStorage?.put(device.id, device);

  }      return key.toString();



  static Device? getDevice(String id) {    } catch (e, stack) {  static List<Attendance> getAllAttendance() {      Logger.info('Storage service initialized successfully');

    return _deviceStorage?.get(id);

  }      Logger.error('StorageService', 'Failed to add attendance record', e, stack);



  static List<Device> getAllDevices() {      rethrow;    try {    } catch (e, stack) {

    return _deviceStorage?.values.toList() ?? [];

  }    }



  // Sync methods  }      return _attendanceBoxInstance?.values.toList() ?? [];      Logger.error('StorageService', 'Failed to initialize storage service', e, stack);

  static Future<void> saveSyncLog(SyncLog syncLog) async {

    await _syncStorage?.put(syncLog.id, syncLog);

  }

  /// Get all attendance records    } catch (e, stack) {      rethrow;

  static List<SyncLog> getPendingSyncLogs() {

    return _syncStorage?.values  static List<Attendance> getAllAttendance() {

        .where((log) => !log.synced)

        .toList() ?? [];    try {      Logger.error('StorageService', 'Failed to get attendance records', e, stack);    }

  }

      return _attendanceBoxInstance.values.toList();

  static List<SyncLog> getAllSyncLogs() {

    return _syncStorage?.values.toList() ?? [];    } catch (e, stack) {      return [];  }

  }

      Logger.error('StorageService', 'Failed to get attendance records', e, stack);

  // Settings methods

  static Future<void> saveSetting(String key, dynamic value) async {      return [];    }  

    await _settingsStorage?.put(key, value);

  }    }



  static T? getSetting<T>(String key) {  }  }  /// Register Hive type adapters

    return _settingsStorage?.get(key) as T?;

  }



  // Utility methods  // STUDENT METHODS  static void _registerAdapters() {

  static Future<void> clearAllData() async {

    await _authStorage?.clear();  /// Save student

    await _userStorage?.clear();

    await _schoolStorage?.clear();  static Future<void> saveStudent(Student student) async {  // STUDENT METHODS    // Register adapters for all models

    await _studentStorage?.clear();

    await _classStorage?.clear();    try {

    await _attendanceStorage?.clear();

    await _deviceStorage?.clear();      await _studentsBoxInstance.put(student.id, student);  static Future<void> saveStudent(Student student) async {    if (!Hive.isAdapterRegistered(0)) {

    await _syncStorage?.clear();

    await _settingsStorage?.clear();    } catch (e, stack) {

  }

      Logger.error('StorageService', 'Failed to save student', e, stack);    try {      Hive.registerAdapter(UserAdapter());

  static Future<void> close() async {

    await _authStorage?.close();      rethrow;

    await _userStorage?.close();

    await _schoolStorage?.close();    }      await _studentsBoxInstance!.put(student.id, student);    }

    await _studentStorage?.close();

    await _classStorage?.close();  }

    await _attendanceStorage?.close();

    await _deviceStorage?.close();    } catch (e, stack) {    if (!Hive.isAdapterRegistered(1)) {

    await _syncStorage?.close();

    await _settingsStorage?.close();  /// Get all students

  }

}  static List<Student> getAllStudents() {      Logger.error('StorageService', 'Failed to save student', e, stack);      Hive.registerAdapter(SchoolAdapter());

    try {

      return _studentsBoxInstance.values.toList();      rethrow;    }

    } catch (e, stack) {

      Logger.error('StorageService', 'Failed to get students', e, stack);    }    if (!Hive.isAdapterRegistered(2)) {

      return [];

    }  }      Hive.registerAdapter(StudentAdapter());

  }

    }

  /// Get student by RFID tag

  static Student? getStudentByRfidTag(String rfidTag) {  static List<Student> getAllStudents() {    if (!Hive.isAdapterRegistered(3)) {

    try {

      return _studentsBoxInstance.values    try {      Hive.registerAdapter(ClassModelAdapter());

          .where((student) => student.rfidTag == rfidTag)

          .firstOrNull;      return _studentsBoxInstance?.values.toList() ?? [];    }

    } catch (e, stack) {

      Logger.error('StorageService', 'Failed to get student by RFID tag', e, stack);    } catch (e, stack) {    if (!Hive.isAdapterRegistered(4)) {

      return null;

    }      Logger.error('StorageService', 'Failed to get students', e, stack);      Hive.registerAdapter(AttendanceAdapter());

  }

      return [];    }

  // AUTH METHODS

  /// Save authentication tokens    }    if (!Hive.isAdapterRegistered(5)) {

  static Future<void> saveAuthTokens({

    required String accessToken,  }      Hive.registerAdapter(DeviceAdapter());

    required String refreshToken,

    required String userId,    }

  }) async {

    try {  // AUTH METHODS    if (!Hive.isAdapterRegistered(6)) {

      await _authBoxInstance.putAll({

        'access_token': accessToken,  static Future<void> saveAuthTokens({      Hive.registerAdapter(SyncLogAdapter());

        'refresh_token': refreshToken,

        'user_id': userId,    required String accessToken,    }

        'login_time': DateTime.now().toIso8601String(),

      });    required String refreshToken,    if (!Hive.isAdapterRegistered(7)) {

    } catch (e, stack) {

      Logger.error('StorageService', 'Failed to save auth tokens', e, stack);    required String userId,      Hive.registerAdapter(UserRoleAdapter());

      rethrow;

    }  }) async {    }

  }

    try {    if (!Hive.isAdapterRegistered(8)) {

  /// Get stored authentication tokens

  static Map<String, dynamic>? getAuthTokens() {      await _authBoxInstance!.putAll({      Hive.registerAdapter(AttendanceStatusAdapter());

    try {

      final accessToken = _authBoxInstance.get('access_token');        'access_token': accessToken,    }

      final refreshToken = _authBoxInstance.get('refresh_token');

      final userId = _authBoxInstance.get('user_id');        'refresh_token': refreshToken,    if (!Hive.isAdapterRegistered(9)) {



      if (accessToken != null && refreshToken != null && userId != null) {        'user_id': userId,      Hive.registerAdapter(SyncStatusAdapter());

        return {

          'access_token': accessToken,        'login_time': DateTime.now().toIso8601String(),    }

          'refresh_token': refreshToken,

          'user_id': userId,      });    if (!Hive.isAdapterRegistered(10)) {

        };

      }    } catch (e, stack) {      Hive.registerAdapter(DeviceTypeAdapter());

      return null;

    } catch (e, stack) {      Logger.error('StorageService', 'Failed to save auth tokens', e, stack);    }

      Logger.error('StorageService', 'Failed to get auth tokens', e, stack);

      return null;      rethrow;  }

    }

  }    }



  /// Clear authentication tokens (logout)  }  /// Initialize all Hive boxes and register adapters

  static Future<void> clearAuthTokens() async {

    try {  Future<void> initialize() async {

      await _authBoxInstance.clear();

    } catch (e, stack) {  Map<String, dynamic>? getAuthTokens() {    try {

      Logger.error('StorageService', 'Failed to clear auth tokens', e, stack);

      rethrow;    try {      // Register type adapters for custom objects

    }

  }      final accessToken = _authBoxInstance?.get('access_token');      _registerAdapters();



  // SETTINGS METHODS      final refreshToken = _authBoxInstance?.get('refresh_token');      

  /// Save setting

  Future<void> saveSetting(String key, dynamic value) async {      final userId = _authBoxInstance?.get('user_id');      // Open all boxes

    try {

      await _settingsBoxInstance.put(key, value);      await _openBoxes();

    } catch (e, stack) {

      Logger.error('StorageService', 'Failed to save setting: $key', e, stack);      if (accessToken != null && refreshToken != null && userId != null) {      

      rethrow;

    }        return {      // Run any necessary migrations

  }

          'access_token': accessToken,      await _runMigrations();

  /// Get setting

  Future<T> getSetting<T>(String key, T defaultValue) async {          'refresh_token': refreshToken,      

    try {

      return _settingsBoxInstance.get(key, defaultValue: defaultValue);          'user_id': userId,      Logger.info('Storage service initialized successfully');

    } catch (e, stack) {

      Logger.error('StorageService', 'Failed to get setting: $key', e, stack);        }    } catch (e, stack) {

      return defaultValue;

    }      }      Logger.error('StorageService', 'Failed to initialize storage service', e, stack);

  }

      return null;      rethrow;

  /// Close all boxes (cleanup on app termination)

  Future<void> dispose() async {    } catch (e, stack) {    }

    try {

      await Hive.close();      Logger.error('StorageService', 'Failed to get auth tokens', e, stack);  }

      Logger.info('Storage service disposed');

    } catch (e, stack) {      return;  

      Logger.error('StorageService', 'Failed to dispose storage service', e, stack);

    }    }  /// Register all Hive type adapters

  }

}  }  void _registerAdapters() {

    if (!Hive.isAdapterRegistered(0)) {

  Future<void> clearAuthTokens() async {      Hive.registerAdapter(AttendanceAdapter());

    try {    }

      await _authBoxInstance?.clear();    if (!Hive.isAdapterRegistered(1)) {

    } catch (e, stack) {      Hive.registerAdapter(StudentAdapter());

      Logger.error('StorageService', 'Failed to clear auth tokens', e, stack);    }

      rethrow;    if (!Hive.isAdapterRegistered(2)) {

    }      Hive.registerAdapter(ClassModelAdapter());

  }    }

    if (!Hive.isAdapterRegistered(3)) {

  // SETTINGS METHODS      Hive.registerAdapter(UserAdapter());

  Future<void> saveSetting(String key, dynamic value) async {    }

    try {    if (!Hive.isAdapterRegistered(4)) {

      await settingsBoxInstance!.put(key, value);      Hive.registerAdapter(DeviceAdapter());

    } catch (e, stack) {    }

      Logger.error('StorageService', 'Failed to save setting: $key', e, stack);    if (!Hive.isAdapterRegistered(5)) {

      rethrow;      Hive.registerAdapter(SyncLogAdapter());

    }    }

  }  }

  

  Future<T> getSetting<T>(String key, T defaultValue) async {  /// Open all required Hive boxes

    try {  Future<void> openBoxes() async {

      return _settingsBoxInstance?.get(key, defaultValue: defaultValue) ?? defaultValue;    _attendanceBoxInstance = await Hive.openBox<Attendance>(_attendanceBox);

    } catch (e, stack) {    _studentsBoxInstance = await Hive.openBox<Student>(_studentsBox);

      Logger.error('StorageService', 'Failed to get setting: $key', e, stack);    _classesBoxInstance = await Hive.openBox<ClassModel>(_classesBox);

      return defaultValue;    _usersBoxInstance = await Hive.openBox<User>(_usersBox);

    }    _devicesBoxInstance = await Hive.openBox<Device>(_devicesBox);

  }    _syncLogsBoxInstance = await Hive.openBox<SyncLog>(_syncLogsBox);

    _settingsBoxInstance = await Hive.openBox(_settingsBox);

  // UTILITY METHODS    _authBoxInstance = await Hive.openBox(_authBox);

  Future<void> dispose() async {  }

    try {  

      await Hive.close();  /// Run database migrations if needed

      Logger.info('Storage service disposed');  Future<void> runMigrations() async {

    } catch (e, stack) {    final currentVersion = _settingsBoxInstance.get('db_version', defaultValue: 0) as int;

      Logger.error('StorageService', 'Failed to dispose storage service', e, stack);    const targetVersion = 1;

    }    

  }    if (currentVersion < targetVersion) {

}      Logger.info('Running database migration from v$currentVersion to v$targetVersion');
      
      // Add migration logic here as needed
      // Example: if (currentVersion < 1) { ... }
      
      await _settingsBoxInstance.put('db_version', targetVersion);
      Logger.info('Database migration completed');
    }
  }
  
  // Attendance Operations
  
  /// Add attendance record locally
  Future<String> addAttendance(Attendance attendance) async {
    try {
      final key = attendance.localId ?? DateTime.now().millisecondsSinceEpoch.toString();
      attendance.localId = key;
      await _attendanceBoxInstance.put(key, attendance);
      Logger.info('Added attendance record locally: $key');
      return key;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to add attendance record', e, stack);
      rethrow;
    }
  }
  
  /// Get all attendance records
  List<Attendance> getAllAttendance() {
    try {
      return _attendanceBoxInstance.values.toList();
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get attendance records', e, stack);
      return [];
    }
  }
  
  /// Get unsynced attendance records
  List<Attendance> getUnsyncedAttendance() {
    try {
      return _attendanceBoxInstance.values
          .where((attendance) => !attendance.isSynced)
          .toList();
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get unsynced attendance records', e, stack);
      return [];
    }
  }
  
  /// Mark attendance as synced
  Future<void> markAttendanceSynced(String localId, String? serverId) async {
    try {
      final attendance = _attendanceBoxInstance.get(localId);
      if (attendance != null) {
        attendance.isSynced = true;
        attendance.serverId = serverId;
        attendance.syncedAt = DateTime.now();
        await _attendanceBoxInstance.put(localId, attendance);
        Logger.info('Marked attendance as synced: $localId -> $serverId');
      }
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to mark attendance as synced', e, stack);
    }
  }
  
  /// Delete attendance record
  Future<void> deleteAttendance(String localId) async {
    try {
      await _attendanceBoxInstance.delete(localId);
      Logger.info('Deleted attendance record: $localId');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to delete attendance record', e, stack);
    }
  }
  
  // Student Operations
  
  /// Add or update student
  Future<void> saveStudent(Student student) async {
    try {
      await _studentsBoxInstance.put(student.id, student);
      Logger.info('Saved student: ${student.id}');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save student', e, stack);
      rethrow;
    }
  }
  
  /// Get all students
  List<Student> getAllStudents() {
    try {
      return _studentsBoxInstance.values.toList();
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get students', e, stack);
      return [];
    }
  }
  
  /// Get student by ID
  Student? getStudent(String id) {
    try {
      return _studentsBoxInstance.get(id);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get student', e, stack);
      return null;
    }
  }
  
  /// Get student by RFID tag
  Student? getStudentByRfidTag(String rfidTag) {
    try {
      return _studentsBoxInstance.values
          .where((student) => student.rfidTag == rfidTag)
          .firstOrNull;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get student by RFID tag', e, stack);
      return null;
    }
  }
  
  /// Search students by name or roll number
  List<Student> searchStudents(String query) {
    try {
      final lowerQuery = query.toLowerCase();
      return _studentsBoxInstance.values
          .where((student) =>
              student.name.toLowerCase().contains(lowerQuery) ||
              student.rollNumber.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to search students', e, stack);
      return [];
    }
  }
  
  // Class Operations
  
  /// Save class
  Future<void> saveClass(ClassModel classModel) async {
    try {
      await _classesBoxInstance.put(classModel.id, classModel);
      Logger.info('Saved class: ${classModel.id}');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save class', e, stack);
      rethrow;
    }
  }
  
  /// Get all classes
  List<ClassModel> getAllClasses() {
    try {
      return _classesBoxInstance.values.toList();
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get classes', e, stack);
      return [];
    }
  }
  
  /// Get class by ID
  ClassModel? getClass(String id) {
    try {
      return _classesBoxInstance.get(id);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get class', e, stack);
      return null;
    }
  }
  
  // Sync Log Operations
  
  /// Add sync log entry
  Future<void> addSyncLog(SyncLog syncLog) async {
    try {
      final key = DateTime.now().millisecondsSinceEpoch.toString();
      await _syncLogsBoxInstance.put(key, syncLog);
      
      // Keep only last 1000 sync logs to prevent unbounded growth
      if (_syncLogsBoxInstance.length > 1000) {
        final oldestKeys = _syncLogsBoxInstance.keys.take(100).toList();
        for (final key in oldestKeys) {
          await _syncLogsBoxInstance.delete(key);
        }
      }
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to add sync log', e, stack);
    }
  }
  
  /// Get recent sync logs
  List<SyncLog> getRecentSyncLogs({int limit = 50}) {
    try {
      return _syncLogsBoxInstance.values
          .toList()
          .reversed
          .take(limit)
          .toList();
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get sync logs', e, stack);
      return [];
    }
  }
  
  // Settings Operations
  
  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBoxInstance.put(key, value);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save setting: $key', e, stack);
    }
  }
  
  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return _settingsBoxInstance.get(key, defaultValue: defaultValue) as T?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get setting: $key', e, stack);
      return defaultValue;
    }
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    try {
      await _settingsBoxInstance.delete(key);
      Logger.info('Deleted setting: $key');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to delete setting: $key', e, stack);
    }
  }
  
  // Auth Operations
  
  /// Save auth tokens
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _authBoxInstance.put('access_token', accessToken);
      await _authBoxInstance.put('refresh_token', refreshToken);
      await _authBoxInstance.put('token_saved_at', DateTime.now().toIso8601String());
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save auth tokens', e, stack);
    }
  }
  
  /// Get access token
  String? getAccessToken() {
    try {
      return _authBoxInstance.get('access_token') as String?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get access token', e, stack);
      return null;
    }
  }
  
  /// Get refresh token
  String? getRefreshToken() {
    try {
      return _authBoxInstance.get('refresh_token') as String?;
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get refresh token', e, stack);
      return null;
    }
  }
  
  /// Clear auth tokens
  Future<void> clearAuthTokens() async {
    try {
      await _authBoxInstance.delete('access_token');
      await _authBoxInstance.delete('refresh_token');
      await _authBoxInstance.delete('token_saved_at');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to clear auth tokens', e, stack);
    }
  }
  
  // Utility Operations
  
  /// Get storage statistics
  Map<String, int> getStorageStats() {
    try {
      return {
        'attendance': _attendanceBoxInstance.length,
        'students': _studentsBoxInstance.length,
        'classes': _classesBoxInstance.length,
        'users': _usersBoxInstance.length,
        'devices': _devicesBoxInstance.length,
        'sync_logs': _syncLogsBoxInstance.length,
        'unsynced_attendance': getUnsyncedAttendance().length,
      };
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get storage stats', e, stack);
      return {};
    }
  }
  
  /// Clear all data (useful for logout)
  Future<void> clearAllData() async {
    try {
      await _attendanceBoxInstance.clear();
      await _studentsBoxInstance.clear();
      await _classesBoxInstance.clear();
      await _usersBoxInstance.clear();
      await _devicesBoxInstance.clear();
      await _schoolsBoxInstance.clear();
      await _syncLogsBoxInstance.clear();
      await _settingsBoxInstance.clear();
      await _authBoxInstance.clear();
      
      Logger.info('All local data cleared');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to clear all data', e, stack);
    }
  }
  
  // --- School Operations ---
  
  /// Save school
  Future<void> saveSchool(School school) async {
    try {
      await _schoolsBoxInstance.put(school.id, school);
      Logger.info('Saved school: ${school.id}');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to save school', e, stack);
      rethrow;
    }
  }

  /// Delete school
  Future<void> deleteSchool(String schoolId) async {
    try {
      await _schoolsBoxInstance.delete(schoolId);
      Logger.info('Deleted school: $schoolId');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to delete school', e, stack);
      rethrow;
    }
  }

  /// Get school by ID
  School? getSchool(String schoolId) {
    try {
      return _schoolsBoxInstance.get(schoolId);
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get school: $schoolId', e, stack);
      return null;
    }
  }

  /// Get all schools
  List<School> getAllSchools() {
    try {
      return _schoolsBoxInstance.values.toList();
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to get all schools', e, stack);
      return [];
    }
  }

  /// Search schools by name
  List<School> searchSchools(String query) {
    try {
      if (query.isEmpty) return getAllSchools();
      
      return _schoolsBoxInstance.values
          .where((school) => school.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to search schools', e, stack);
      return [];
    }
  }

  /// Compact all boxes to reclaim space
  Future<void> compactStorage() async {
    try {
      await _attendanceBoxInstance.compact();
      await _studentsBoxInstance.compact();
      await _classesBoxInstance.compact();
      await _usersBoxInstance.compact();
      await _devicesBoxInstance.compact();
      await _schoolsBoxInstance.compact();
      await _syncLogsBoxInstance.compact();
      await _settingsBoxInstance.compact();
      await _authBoxInstance.compact();
      
      Logger.info('Storage compacted successfully');
    } catch (e, stack) {
      Logger.error('StorageService', 'Failed to compact storage', e, stack);
    }
  }
}