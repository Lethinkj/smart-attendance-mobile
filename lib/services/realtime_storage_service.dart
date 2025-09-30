import 'dart:async';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/school.dart';
import '../models/staff.dart';
import '../models/student.dart';
import '../models/attendance.dart';

/// Real-time storage service that manages local Hive storage with cloud Supabase synchronization
/// Provides WhatsApp-like automatic sync functionality
class RealtimeStorageService {
  static final RealtimeStorageService _instance = RealtimeStorageService._internal();
  factory RealtimeStorageService() => _instance;
  RealtimeStorageService._internal();

  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Local Hive boxes
  Box<dynamic>? _schoolBox;
  Box<dynamic>? _staffBox;
  Box<dynamic>? _studentBox;
  Box<dynamic>? _attendanceBox;
  Box<dynamic>? _syncBox; // For tracking sync status

  // Stream controllers for real-time updates
  final StreamController<List<School>> _schoolsController = StreamController<List<School>>.broadcast();
  final StreamController<List<Staff>> _staffController = StreamController<List<Staff>>.broadcast();
  final StreamController<List<Student>> _studentsController = StreamController<List<Student>>.broadcast();
  final StreamController<List<Attendance>> _attendanceController = StreamController<List<Attendance>>.broadcast();

  // Streams for real-time data
  Stream<List<School>> get schoolsStream => _schoolsController.stream;
  Stream<List<Staff>> get staffStream => _staffController.stream;
  Stream<List<Student>> get studentsStream => _studentsController.stream;
  Stream<List<Attendance>> get attendanceStream => _attendanceController.stream;

  // Sync status
  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _syncTimer;

  /// Initialize the real-time storage service
  Future<void> initialize() async {
    try {
      // Initialize Hive boxes
      _schoolBox = await Hive.openBox<dynamic>('schools');
      _staffBox = await Hive.openBox<dynamic>('staff');
      _studentBox = await Hive.openBox<dynamic>('students');
      _attendanceBox = await Hive.openBox<dynamic>('attendance');
      _syncBox = await Hive.openBox<dynamic>('sync_status');

      // Start real-time subscriptions
      _startRealtimeSubscriptions();
      
      // Start periodic sync (every 30 seconds)
      _startPeriodicSync();
      
      // Perform initial sync
      await _performFullSync();

      print('RealtimeStorageService initialized successfully');
    } catch (e) {
      print('Error initializing RealtimeStorageService: $e');
    }
  }

  /// Start real-time subscriptions to Supabase changes
  void _startRealtimeSubscriptions() {
    // Subscribe to schools table changes
    _supabase
        .channel('schools_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schools',
          callback: (payload) => _handleSchoolChanges(payload),
        )
        .subscribe();

    // Subscribe to staff table changes
    _supabase
        .channel('staff_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'staff',
          callback: (payload) => _handleStaffChanges(payload),
        )
        .subscribe();

    // Subscribe to students table changes
    _supabase
        .channel('students_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'students',
          callback: (payload) => _handleStudentChanges(payload),
        )
        .subscribe();

    // Subscribe to attendance table changes
    _supabase
        .channel('attendance_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          callback: (payload) => _handleAttendanceChanges(payload),
        )
        .subscribe();
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isSyncing) {
        _performIncrementalSync();
      }
    });
  }

  /// Handle school table changes from Supabase
  void _handleSchoolChanges(PostgresChangePayload payload) async {
    try {
      final schoolData = payload.newRecord;
      final school = School.fromJson(schoolData);
      await _schoolBox?.put(school.id, school.toJson());
      _emitSchoolsUpdate();
    } catch (e) {
      print('Error handling school changes: $e');
    }
  }

  /// Handle staff table changes from Supabase
  void _handleStaffChanges(PostgresChangePayload payload) async {
    try {
      final staffData = payload.newRecord;
      final staff = Staff.fromJson(staffData);
      await _staffBox?.put(staff.staffId, staff.toJson());
      _emitStaffUpdate();
    } catch (e) {
      print('Error handling staff changes: $e');
    }
  }

  /// Handle student table changes from Supabase
  void _handleStudentChanges(PostgresChangePayload payload) async {
    try {
      final studentData = payload.newRecord;
      final student = Student.fromJson(studentData);
      await _studentBox?.put(student.studentId, student.toJson());
      _emitStudentsUpdate();
    } catch (e) {
      print('Error handling student changes: $e');
    }
  }

  /// Handle attendance table changes from Supabase
  void _handleAttendanceChanges(PostgresChangePayload payload) async {
    try {
      final attendanceData = payload.newRecord;
      final attendance = Attendance.fromJson(attendanceData);
      await _attendanceBox?.put(attendance.id, attendance.toJson());
      _emitAttendanceUpdate();
    } catch (e) {
      print('Error handling attendance changes: $e');
    }
  }

  /// Perform full synchronization between local and cloud storage
  Future<void> _performFullSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Sync schools
      await _syncSchools();
      
      // Sync staff
      await _syncStaff();
      
      // Sync students
      await _syncStudents();
      
      // Sync attendance
      await _syncAttendance();

      print('Full sync completed successfully');
    } catch (e) {
      print('Error during full sync: $e');
      _isOnline = false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform incremental synchronization
  Future<void> _performIncrementalSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Upload local changes that haven't been synced
      await _uploadPendingChanges();
      
      // Download recent changes from server
      await _downloadRecentChanges();

      _isOnline = true;
      print('Incremental sync completed');
    } catch (e) {
      print('Error during incremental sync: $e');
      _isOnline = false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync schools between local and cloud
  Future<void> _syncSchools() async {
    try {
      // Download from cloud
      final response = await _supabase.from('schools').select();
      final cloudSchools = (response as List).map((json) => School.fromJson(json)).toList();
      
      // Update local storage
      for (final school in cloudSchools) {
        await _schoolBox?.put(school.id, school.toJson());
      }
      
      // Upload local changes not in cloud
      final localSchoolsJson = _schoolBox?.values.toList() ?? [];
      final localSchools = localSchoolsJson.map((json) => School.fromJson(json as Map<String, dynamic>)).toList();
      for (final school in localSchools) {
        final exists = cloudSchools.any((cs) => cs.id == school.id);
        if (!exists) {
          await _supabase.from('schools').upsert(school.toJson());
        }
      }
      
      _emitSchoolsUpdate();
    } catch (e) {
      print('Error syncing schools: $e');
    }
  }

  /// Sync staff between local and cloud
  Future<void> _syncStaff() async {
    try {
      // Download from cloud
      final response = await _supabase.from('staff').select();
      final cloudStaff = (response as List).map((json) => Staff.fromJson(json)).toList();
      
      // Update local storage
      for (final staff in cloudStaff) {
        await _staffBox?.put(staff.staffId, staff.toJson());
      }
      
      // Upload local changes not in cloud
      final localStaffJson = _staffBox?.values.toList() ?? [];
      final localStaff = localStaffJson.map((json) => Staff.fromJson(json as Map<String, dynamic>)).toList();
      for (final staff in localStaff) {
        final exists = cloudStaff.any((cs) => cs.staffId == staff.staffId);
        if (!exists) {
          await _supabase.from('staff').upsert(staff.toJson());
        }
      }
      
      _emitStaffUpdate();
    } catch (e) {
      print('Error syncing staff: $e');
    }
  }

  /// Sync students between local and cloud
  Future<void> _syncStudents() async {
    try {
      // Download from cloud
      final response = await _supabase.from('students').select();
      final cloudStudents = (response as List).map((json) => Student.fromJson(json)).toList();
      
      // Update local storage
      for (final student in cloudStudents) {
        await _studentBox?.put(student.studentId, student.toJson());
      }
      
      // Upload local changes not in cloud
      final localStudentsJson = _studentBox?.values.toList() ?? [];
      final localStudents = localStudentsJson.map((json) => Student.fromJson(json as Map<String, dynamic>)).toList();
      for (final student in localStudents) {
        final exists = cloudStudents.any((cs) => cs.studentId == student.studentId);
        if (!exists) {
          await _supabase.from('students').upsert(student.toJson());
        }
      }
      
      _emitStudentsUpdate();
    } catch (e) {
      print('Error syncing students: $e');
    }
  }

  /// Sync attendance between local and cloud
  Future<void> _syncAttendance() async {
    try {
      // Download from cloud
      final response = await _supabase.from('attendance').select();
      final cloudAttendance = (response as List).map((json) => Attendance.fromJson(json)).toList();
      
      // Update local storage
      for (final attendance in cloudAttendance) {
        await _attendanceBox?.put(attendance.id, attendance.toJson());
      }
      
      // Upload local changes not in cloud
      final localAttendanceJson = _attendanceBox?.values.toList() ?? [];
      final localAttendance = localAttendanceJson.map((json) => Attendance.fromJson(json as Map<String, dynamic>)).toList();
      for (final attendance in localAttendance) {
        final exists = cloudAttendance.any((ca) => ca.id == attendance.id);
        if (!exists) {
          await _supabase.from('attendance').upsert(attendance.toJson());
        }
      }
      
      _emitAttendanceUpdate();
    } catch (e) {
      print('Error syncing attendance: $e');
    }
  }

  /// Upload pending local changes to cloud
  Future<void> _uploadPendingChanges() async {
    try {
      // Check for unsynced data
      final pendingSchools = _getPendingSchools();
      final pendingStaff = _getPendingStaff();
      final pendingStudents = _getPendingStudents();
      final pendingAttendance = _getPendingAttendance();

      // Upload pending schools
      for (final school in pendingSchools) {
        await _supabase.from('schools').upsert(school.toJson());
        _markAsSynced('school', school.id);
      }

      // Upload pending staff
      for (final staff in pendingStaff) {
        await _supabase.from('staff').upsert(staff.toJson());
        _markAsSynced('staff', staff.staffId);
      }

      // Upload pending students
      for (final student in pendingStudents) {
        await _supabase.from('students').upsert(student.toJson());
        _markAsSynced('student', student.studentId);
      }

      // Upload pending attendance
      for (final attendance in pendingAttendance) {
        await _supabase.from('attendance').upsert(attendance.toJson());
        _markAsSynced('attendance', attendance.id);
      }
    } catch (e) {
      print('Error uploading pending changes: $e');
    }
  }

  /// Download recent changes from cloud
  Future<void> _downloadRecentChanges() async {
    try {
      final lastSync = _getLastSyncTime();

      // Download recent schools
      final schoolsResponse = await _supabase.from('schools').select().filter('updated_at', 'gte', lastSync);
      for (final json in schoolsResponse) {
        final school = School.fromJson(json);
        await _schoolBox?.put(school.id, school.toJson());
      }

      // Download recent staff
      final staffResponse = await _supabase.from('staff').select().filter('updated_at', 'gte', lastSync);
      for (final json in staffResponse) {
        final staff = Staff.fromJson(json);
        await _staffBox?.put(staff.staffId, staff.toJson());
      }

      // Download recent students
      final studentsResponse = await _supabase.from('students').select().filter('updated_at', 'gte', lastSync);
      for (final json in studentsResponse) {
        final student = Student.fromJson(json);
        await _studentBox?.put(student.studentId, student.toJson());
      }

      // Download recent attendance
      final attendanceResponse = await _supabase.from('attendance').select().filter('updated_at', 'gte', lastSync);
      for (final json in attendanceResponse) {
        final attendance = Attendance.fromJson(json);
        await _attendanceBox?.put(attendance.id, attendance.toJson());
      }

      // Update last sync time
      _updateLastSyncTime();
      
      // Emit updates
      _emitSchoolsUpdate();
      _emitStaffUpdate();
      _emitStudentsUpdate();
      _emitAttendanceUpdate();
    } catch (e) {
      print('Error downloading recent changes: $e');
    }
  }

  /// Get pending schools that need to be synced
  List<School> _getPendingSchools() {
    final schoolsJson = _schoolBox?.values.toList() ?? [];
    final schools = schoolsJson.map((json) => School.fromJson(json as Map<String, dynamic>)).toList();
    return schools.where((school) => !_isSynced('school', school.id)).toList();
  }

  /// Get pending staff that need to be synced
  List<Staff> _getPendingStaff() {
    final staffJson = _staffBox?.values.toList() ?? [];
    final staff = staffJson.map((json) => Staff.fromJson(json as Map<String, dynamic>)).toList();
    return staff.where((s) => !_isSynced('staff', s.staffId)).toList();
  }

  /// Get pending students that need to be synced
  List<Student> _getPendingStudents() {
    final studentsJson = _studentBox?.values.toList() ?? [];
    final students = studentsJson.map((json) => Student.fromJson(json as Map<String, dynamic>)).toList();
    return students.where((student) => !_isSynced('student', student.studentId)).toList();
  }

  /// Get pending attendance records that need to be synced
  List<Attendance> _getPendingAttendance() {
    final attendanceJson = _attendanceBox?.values.toList() ?? [];
    final attendance = attendanceJson.map((json) => Attendance.fromJson(json as Map<String, dynamic>)).toList();
    return attendance.where((a) => !_isSynced('attendance', a.id)).toList();
  }

  /// Check if an item is synced
  bool _isSynced(String type, String id) {
    return _syncBox?.get('${type}_$id') != null;
  }

  /// Mark an item as synced
  void _markAsSynced(String type, String id) {
    _syncBox?.put('${type}_$id', {'synced_at': DateTime.now().toIso8601String()});
  }

  /// Get last sync time
  String _getLastSyncTime() {
    final lastSync = _syncBox?.get('last_sync_time');
    return lastSync?['time'] ?? DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
  }

  /// Update last sync time
  void _updateLastSyncTime() {
    _syncBox?.put('last_sync_time', {'time': DateTime.now().toIso8601String()});
  }

  /// Emit schools update to stream
  void _emitSchoolsUpdate() {
    final schoolsJson = _schoolBox?.values.toList() ?? [];
    final schools = schoolsJson.map((json) => School.fromJson(json as Map<String, dynamic>)).toList();
    _schoolsController.add(schools);
  }

  /// Emit staff update to stream
  void _emitStaffUpdate() {
    final staffJson = _staffBox?.values.toList() ?? [];
    final staff = staffJson.map((json) => Staff.fromJson(json as Map<String, dynamic>)).toList();
    _staffController.add(staff);
  }

  /// Emit students update to stream
  void _emitStudentsUpdate() {
    final studentsJson = _studentBox?.values.toList() ?? [];
    final students = studentsJson.map((json) => Student.fromJson(json as Map<String, dynamic>)).toList();
    _studentsController.add(students);
  }

  /// Emit attendance update to stream
  void _emitAttendanceUpdate() {
    final attendanceJson = _attendanceBox?.values.toList() ?? [];
    final attendance = attendanceJson.map((json) => Attendance.fromJson(json as Map<String, dynamic>)).toList();
    _attendanceController.add(attendance);
  }

  /// Force sync now
  Future<void> forcSync() async {
    await _performFullSync();
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'lastSyncTime': _getLastSyncTime(),
      'pendingSchools': _getPendingSchools().length,
      'pendingStaff': _getPendingStaff().length,
      'pendingStudents': _getPendingStudents().length,
      'pendingAttendance': _getPendingAttendance().length,
    };
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _schoolsController.close();
    _staffController.close();
    _studentsController.close();
    _attendanceController.close();
    _supabase.removeAllChannels();
  }
}