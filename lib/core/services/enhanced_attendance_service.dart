import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../services/supabase_postgresql_service.dart';
import 'storage_service.dart';
import 'rfid_service.dart';
import '../utils/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Enhanced Attendance Service with RFID Integration
final attendanceServiceProvider = StateNotifierProvider<AttendanceService, AttendanceServiceState>((ref) {
  final rfidService = ref.watch(rfidServiceProvider.notifier);
  return AttendanceService(rfidService);
});

/// Attendance Service State
class AttendanceServiceState {
  final bool isRfidMode;
  final bool isScanning;
  final bool isOnline;
  final int pendingSyncCount;
  final List<Attendance> todayAttendance;
  final String? currentClassId;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const AttendanceServiceState({
    this.isRfidMode = true,
    this.isScanning = false,
    this.isOnline = false,
    this.pendingSyncCount = 0,
    this.todayAttendance = const [],
    this.currentClassId,
    this.lastSyncTime,
    this.errorMessage,
  });

  AttendanceServiceState copyWith({
    bool? isRfidMode,
    bool? isScanning,
    bool? isOnline,
    int? pendingSyncCount,
    List<Attendance>? todayAttendance,
    String? currentClassId,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return AttendanceServiceState(
      isRfidMode: isRfidMode ?? this.isRfidMode,
      isScanning: isScanning ?? this.isScanning,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      currentClassId: currentClassId ?? this.currentClassId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Enhanced Attendance Service
class AttendanceService extends StateNotifier<AttendanceServiceState> {
  static const String _logTag = 'AttendanceService';
  
  final RfidService _rfidService;
  late StreamSubscription _rfidSubscription;
  late StreamSubscription _connectivitySubscription;
  Timer? _syncTimer;

  AttendanceService(this._rfidService) : super(const AttendanceServiceState()) {
    _initialize();
  }

  /// Initialize the attendance service
  Future<void> _initialize() async {
    try {
      Logger.info(_logTag, 'Initializing Enhanced Attendance Service...');
      
      // Monitor connectivity
      _monitorConnectivity();
      
      // Setup RFID listeners
      _setupRfidListeners();
      
      // Load today's attendance
      await _loadTodayAttendance();
      
      // Setup periodic sync
      _setupPeriodicSync();
      
      Logger.info(_logTag, 'Enhanced Attendance Service initialized');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to initialize attendance service', e, stack);
    }
  }

  /// Setup RFID listeners for automatic attendance
  void _setupRfidListeners() {
    // Listen to RFID tag readings
    _rfidSubscription = _rfidService.state.listen((rfidState) {
      if (rfidState.recentReadings.isNotEmpty && state.isScanning) {
        final latestReading = rfidState.recentReadings.first;
        _handleRfidReading(latestReading.tagId);
      }
    });
  }

  /// Handle RFID card reading for attendance
  Future<void> _handleRfidReading(String rfidTag) async {
    try {
      Logger.info(_logTag, 'Processing RFID tag: $rfidTag');
      
      // Find student by RFID tag
      final student = await _findStudentByRfid(rfidTag);
      
      if (student == null) {
        Logger.warning(_logTag, 'No student found for RFID tag: $rfidTag');
        state = state.copyWith(errorMessage: 'Unknown RFID card: $rfidTag');
        return;
      }

      // Check if attendance already marked today
      final existingAttendance = await _getTodayAttendance(student.id);
      
      if (existingAttendance != null) {
        if (existingAttendance.checkOutTime == null) {
          // Mark check-out
          await _markCheckOut(existingAttendance, student);
        } else {
          Logger.info(_logTag, 'Attendance already complete for ${student.name}');
          state = state.copyWith(errorMessage: '${student.name} already marked complete today');
        }
      } else {
        // Mark check-in
        await _markCheckIn(student);
      }

    } catch (e, stack) {
      Logger.error(_logTag, 'Error processing RFID reading', e, stack);
      state = state.copyWith(errorMessage: 'Error processing RFID: $e');
    }
  }

  /// Find student by RFID tag
  Future<Student?> _findStudentByRfid(String rfidTag) async {
    try {
      // First check local storage
      final students = StorageService.getAllStudents();
      for (final studentData in students) {
        if (studentData['rfidTag'] == rfidTag) {
          return Student.fromJson(studentData);
        }
      }

      // If online, check database
      if (state.isOnline) {
        // Implementation depends on your database query capability
        Logger.info(_logTag, 'Searching database for RFID tag: $rfidTag');
        // Add database query here when available
      }

      return null;
    } catch (e, stack) {
      Logger.error(_logTag, 'Error finding student by RFID', e, stack);
      return null;
    }
  }

  /// Mark check-in attendance
  Future<void> _markCheckIn(Student student) async {
    try {
      final now = DateTime.now();
      final attendance = Attendance(
        studentId: student.id,
        schoolId: student.schoolId,
        className: student.className,
        section: student.section,
        date: DateTime(now.year, now.month, now.day),
        checkInTime: now,
        status: 'Present',
        method: 'RFID',
        remarks: 'Auto check-in via RFID',
      );

      // Save locally first
      await _saveAttendanceLocally(attendance);

      // Try to sync to server if online
      if (state.isOnline) {
        try {
          await SupabasePostgreSQLService.createAttendance(attendance);
          await _markAsSynced(attendance.id);
          Logger.info(_logTag, 'Check-in synced to server: ${student.name}');
        } catch (e) {
          Logger.warning(_logTag, 'Failed to sync check-in to server: $e');
        }
      }

      await _loadTodayAttendance();
      Logger.info(_logTag, 'Check-in marked for ${student.name}');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Error marking check-in', e, stack);
      rethrow;
    }
  }

  /// Mark check-out attendance
  Future<void> _markCheckOut(Attendance attendance, Student student) async {
    try {
      final updatedAttendance = attendance.copyWith(
        checkOutTime: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update locally first
      await _updateAttendanceLocally(updatedAttendance);

      // Try to sync to server if online
      if (state.isOnline) {
        try {
          await SupabasePostgreSQLService.updateAttendance(updatedAttendance);
          await _markAsSynced(updatedAttendance.id);
          Logger.info(_logTag, 'Check-out synced to server: ${student.name}');
        } catch (e) {
          Logger.warning(_logTag, 'Failed to sync check-out to server: $e');
        }
      }

      await _loadTodayAttendance();
      Logger.info(_logTag, 'Check-out marked for ${student.name}');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Error marking check-out', e, stack);
      rethrow;
    }
  }

  /// Manual attendance marking (fallback option)
  Future<void> markAttendanceManually({
    required String studentId,
    required String status,
    String? remarks,
  }) async {
    try {
      Logger.info(_logTag, 'Manual attendance marking for student: $studentId');

      // Get student info
      final studentData = StorageService.getStudent(studentId);
      if (studentData == null) {
        throw Exception('Student not found: $studentId');
      }

      final student = Student.fromJson(studentData);
      final now = DateTime.now();

      final attendance = Attendance(
        studentId: studentId,
        schoolId: student.schoolId,
        className: student.className,
        section: student.section,
        date: DateTime(now.year, now.month, now.day),
        checkInTime: status == 'Present' ? now : null,
        status: status,
        method: 'Manual',
        remarks: remarks ?? 'Manual entry',
      );

      await _saveAttendanceLocally(attendance);

      if (state.isOnline) {
        try {
          await SupabasePostgreSQLService.createAttendance(attendance);
          await _markAsSynced(attendance.id);
        } catch (e) {
          Logger.warning(_logTag, 'Failed to sync manual attendance: $e');
        }
      }

      await _loadTodayAttendance();
      Logger.info(_logTag, 'Manual attendance marked: ${student.name} - $status');

    } catch (e, stack) {
      Logger.error(_logTag, 'Error marking manual attendance', e, stack);
      rethrow;
    }
  }

  /// Start RFID scanning mode
  Future<void> startRfidScanning() async {
    try {
      if (!_rfidService.isConnected) {
        throw Exception('RFID reader not connected');
      }

      await _rfidService.startScanning();
      state = state.copyWith(
        isScanning: true,
        isRfidMode: true,
        errorMessage: null,
      );

      Logger.info(_logTag, 'RFID scanning started');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to start RFID scanning', e, stack);
      state = state.copyWith(errorMessage: 'Failed to start scanning: $e');
      rethrow;
    }
  }

  /// Stop RFID scanning mode
  Future<void> stopRfidScanning() async {
    try {
      await _rfidService.stopScanning();
      state = state.copyWith(
        isScanning: false,
        errorMessage: null,
      );

      Logger.info(_logTag, 'RFID scanning stopped');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to stop RFID scanning', e, stack);
    }
  }

  /// Toggle between RFID and Manual mode
  void toggleAttendanceMode() {
    final newMode = !state.isRfidMode;
    state = state.copyWith(isRfidMode: newMode);
    
    if (!newMode && state.isScanning) {
      stopRfidScanning();
    }
    
    Logger.info(_logTag, 'Attendance mode changed to: ${newMode ? 'RFID' : 'Manual'}');
  }

  /// Monitor network connectivity
  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      state = state.copyWith(isOnline: isOnline);
      
      if (isOnline) {
        Logger.info(_logTag, 'Network connected - starting sync');
        _syncPendingAttendance();
      } else {
        Logger.warning(_logTag, 'Network disconnected - offline mode');
      }
    });
  }

  /// Setup periodic sync timer
  void _setupPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (state.isOnline && state.pendingSyncCount > 0) {
        _syncPendingAttendance();
      }
    });
  }

  /// Load today's attendance from storage
  Future<void> _loadTodayAttendance() async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final allAttendance = StorageService.getAllAttendance();
      final todayAttendance = allAttendance
          .where((data) => data['date'].toString().startsWith(todayStr))
          .map((data) => Attendance.fromJson(data))
          .toList();

      final pendingCount = allAttendance
          .where((data) => data['isSynced'] != true)
          .length;

      state = state.copyWith(
        todayAttendance: todayAttendance,
        pendingSyncCount: pendingCount,
      );

    } catch (e, stack) {
      Logger.error(_logTag, 'Error loading today attendance', e, stack);
    }
  }

  /// Save attendance locally
  Future<void> _saveAttendanceLocally(Attendance attendance) async {
    final attendanceData = attendance.toJson();
    attendanceData['isSynced'] = false;
    StorageService.saveAttendance(attendanceData);
  }

  /// Update attendance locally
  Future<void> _updateAttendanceLocally(Attendance attendance) async {
    final attendanceData = attendance.toJson();
    attendanceData['isSynced'] = false;
    StorageService.updateAttendance(attendance.id, attendanceData);
  }

  /// Mark attendance as synced
  Future<void> _markAsSynced(String attendanceId) async {
    final existingData = StorageService.getAttendance(attendanceId);
    if (existingData != null) {
      existingData['isSynced'] = true;
      StorageService.updateAttendance(attendanceId, existingData);
    }
  }

  /// Get today's attendance for a student
  Future<Attendance?> _getTodayAttendance(String studentId) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final todayAttendance = state.todayAttendance
        .where((att) => att.studentId == studentId && att.date.toString().startsWith(todayStr))
        .toList();
    
    return todayAttendance.isNotEmpty ? todayAttendance.first : null;
  }

  /// Sync pending attendance to server
  Future<void> _syncPendingAttendance() async {
    try {
      if (!state.isOnline) return;

      Logger.info(_logTag, 'Syncing pending attendance records...');
      
      final allAttendance = StorageService.getAllAttendance();
      final pendingAttendance = allAttendance
          .where((data) => data['isSynced'] != true)
          .toList();

      for (final attendanceData in pendingAttendance) {
        try {
          final attendance = Attendance.fromJson(attendanceData);
          
          // Try to sync to server
          if (attendanceData['checkOutTime'] != null) {
            await SupabasePostgreSQLService.updateAttendance(attendance);
          } else {
            await SupabasePostgreSQLService.createAttendance(attendance);
          }
          
          // Mark as synced
          await _markAsSynced(attendance.id);
          
        } catch (e) {
          Logger.warning(_logTag, 'Failed to sync attendance record: $e');
          continue; // Continue with next record
        }
      }

      state = state.copyWith(
        lastSyncTime: DateTime.now(),
        pendingSyncCount: 0,
      );

      Logger.info(_logTag, 'Attendance sync completed');

    } catch (e, stack) {
      Logger.error(_logTag, 'Error syncing attendance', e, stack);
    }
  }

  /// Get attendance statistics
  Map<String, int> getAttendanceStats() {
    final today = state.todayAttendance;
    
    return {
      'total': today.length,
      'present': today.where((att) => att.status == 'Present').length,
      'absent': today.where((att) => att.status == 'Absent').length,
      'late': today.where((att) => att.status == 'Late').length,
      'pending_sync': state.pendingSyncCount,
    };
  }

  @override
  void dispose() {
    Logger.info(_logTag, 'Disposing Enhanced Attendance Service');
    
    _rfidSubscription.cancel();
    _connectivitySubscription.cancel();
    _syncTimer?.cancel();
    
    super.dispose();
  }
}