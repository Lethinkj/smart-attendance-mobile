import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/app_config.dart';
import '../models/attendance.dart';
import '../models/student.dart';
import '../models/school.dart';
import '../models/class_model.dart';
import '../models/sync_log.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

/// Sync Service Provider
final syncServiceProvider = StateNotifierProvider<SyncService, SyncServiceState>((ref) {
  return SyncService();
});

/// Sync Service State
class SyncServiceState {
  final bool isSyncing;
  final int pendingAttendanceCount;
  final int pendingStudentsCount;
  final DateTime? lastSyncTime;
  final String? lastError;
  final double syncProgress;
  
  const SyncServiceState({
    this.isSyncing = false,
    this.pendingAttendanceCount = 0,
    this.pendingStudentsCount = 0,
    this.lastSyncTime,
    this.lastError,
    this.syncProgress = 0.0,
  });
  
  SyncServiceState copyWith({
    bool? isSyncing,
    int? pendingAttendanceCount,
    int? pendingStudentsCount,
    DateTime? lastSyncTime,
    String? lastError,
    double? syncProgress,
  }) {
    return SyncServiceState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingAttendanceCount: pendingAttendanceCount ?? this.pendingAttendanceCount,
      pendingStudentsCount: pendingStudentsCount ?? this.pendingStudentsCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      syncProgress: syncProgress ?? this.syncProgress,
    );
  }
}

/// WhatsApp-like Sync Service - Automatic background synchronization
class SyncService extends StateNotifier<SyncServiceState> {
  static const String _logTag = 'SyncService';
  
  // Networking
  final Dio _dio = Dio();
  
  // Connectivity monitoring
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  // Auto-sync timer
  Timer? _autoSyncTimer;
  
  // Retry mechanism
  int _retryCount = 0;
  Timer? _retryTimer;
  
  SyncService() : super(const SyncServiceState()) {
    _initialize();
  }
  
  /// Initialize sync service
  Future<void> _initialize() async {
    Logger.info(_logTag, 'Initializing sync service');
    
    // Configure Dio
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Setup request/response interceptors
    _setupInterceptors();
    
    // Monitor connectivity changes
    _setupConnectivityMonitoring();
    
    // Setup auto-sync
    _setupAutoSync();
    
    // Update pending counts
    await _updatePendingCounts();
    
    Logger.info(_logTag, 'Sync service initialized');
  }
  
  /// Setup Dio interceptors for authentication and logging
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication token
          final token = StorageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          Logger.info(_logTag, 'Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          Logger.info(_logTag, 'Response: ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          Logger.error(_logTag, 'Request error: ${error.message}', error);
          handler.next(error);
        },
      ),
    );
  }
  
  /// Setup connectivity monitoring for auto-sync
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        Logger.info(_logTag, 'Connectivity changed: $result');
        
        if (result != ConnectivityResult.none) {
          // Connected to internet - trigger sync
          _triggerAutoSync();
        }
      },
    );
  }
  
  /// Setup automatic sync timer
  void _setupAutoSync() {
    _autoSyncTimer = Timer.periodic(AppConfig.syncInterval, (timer) {
      if (!state.isSyncing) {
        _triggerAutoSync();
      }
    });
  }
  
  /// Trigger automatic sync if conditions are met
  Future<void> _triggerAutoSync() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        Logger.info(_logTag, 'No internet connection - skipping auto sync');
        return;
      }
      
      await _updatePendingCounts();
      
      // Only sync if there's pending data
      if (state.pendingAttendanceCount > 0 || state.pendingStudentsCount > 0) {
        Logger.info(_logTag, 'Auto-sync triggered: ${state.pendingAttendanceCount} attendance, ${state.pendingStudentsCount} students');
        await syncAll();
      }
    } catch (e) {
      Logger.error(_logTag, 'Auto-sync error', e);
    }
  }
  
  /// Sync all pending data
  Future<void> syncAll() async {
    if (state.isSyncing) {
      Logger.info(_logTag, 'Sync already in progress');
      return;
    }
    
    Logger.info(_logTag, 'Starting full sync');
    
    state = state.copyWith(
      isSyncing: true,
      lastError: null,
      syncProgress: 0.0,
    );
    
    try {
      // Sync attendance records
      await _syncAttendance();
      
      state = state.copyWith(syncProgress: 0.5);
      
      // Sync student data
      await _syncStudents();
      
      state = state.copyWith(syncProgress: 0.8);
      
      // Download updated data
      await _downloadUpdates();
      
      state = state.copyWith(
        syncProgress: 1.0,
        lastSyncTime: DateTime.now(),
        lastError: null,
      );
      
      _retryCount = 0; // Reset retry count on success
      
      Logger.info(_logTag, 'Full sync completed successfully');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Sync failed', e, stack);
      
      state = state.copyWith(
        lastError: e.toString(),
        syncProgress: 0.0,
      );
      
      // Schedule retry with exponential backoff
      _scheduleRetry();
      
    } finally {
      state = state.copyWith(isSyncing: false);
      await _updatePendingCounts();
    }
  }
  
  /// Sync attendance records to server
  Future<void> _syncAttendance() async {
    Logger.info(_logTag, 'Syncing attendance records');
    
    final unsyncedAttendanceData = StorageService.getUnsyncedAttendance();
    if (unsyncedAttendanceData.isEmpty) {
      Logger.info(_logTag, 'No attendance records to sync');
      return;
    }
    
    // Convert maps to Attendance objects
    final unsyncedAttendance = unsyncedAttendanceData
        .map((data) => Attendance.fromJson(data))
        .toList();
    
    // Batch sync attendance
    const batchSize = 50;
    for (int i = 0; i < unsyncedAttendance.length; i += batchSize) {
      final batch = unsyncedAttendance.skip(i).take(batchSize).toList();
      await _syncAttendanceBatch(batch);
    }
    
    Logger.info(_logTag, 'Attendance sync completed');
  }
  
  /// Sync a batch of attendance records
  Future<void> _syncAttendanceBatch(List<Attendance> batch) async {
    try {
      final payload = {
        'attendance': batch.map((a) => {
          'local_id': a.localId,
          'student_id': a.studentId,
          'class_id': a.classId,
          'marked_at': a.markedAt.toIso8601String(),
          'marked_by': a.markedBy,
          'source': a.source,
          'device_uuid': a.deviceUuid,
          'rfid_tag': a.rfidTag,
          'status': a.status,
          'notes': a.notes,
          'latitude': a.latitude,
          'longitude': a.longitude,
        }).toList(),
      };
      
      final response = await _dio.post('/attendance/batch', data: payload);
      
      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        
        // Update local records with server IDs
        for (final result in results) {
          final localId = result['local_id'] as String;
          final serverId = result['server_id'] as String?;
          final status = result['status'] as String;
          
          if (status == 'success' && serverId != null) {
            await StorageService.markAttendanceSynced(localId, serverId);
          } else {
            Logger.warning(_logTag, 'Failed to sync attendance $localId: ${result['error']}');
          }
        }
        
        // Log successful sync
        await StorageService.addSyncLog(
          SyncLog.success(
            syncType: 'attendance',
            operation: 'upload',
            recordsAttempted: batch.length,
            recordsSucceeded: results.where((r) => r['status'] == 'success').length,
            deviceUuid: await _getDeviceUuid(),
          ),
        );
      }
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to sync attendance batch', e, stack);
      
      // Log failed sync
      await StorageService.addSyncLog(
        SyncLog.failure(
          syncType: 'attendance',
          operation: 'upload',
          recordsAttempted: batch.length,
          errorMessage: e.toString(),
          deviceUuid: await _getDeviceUuid(),
        ),
      );
      
      rethrow;
    }
  }
  
  /// Sync student data
  Future<void> _syncStudents() async {
    Logger.info(_logTag, 'Syncing student data');
    
    // For now, we'll focus on downloading student data from server
    // In a full implementation, we might also sync local student additions
    
    try {
      final response = await _dio.get('/students');
      
      if (response.statusCode == 200) {
        final studentsData = response.data['students'] as List;
        
        for (final studentData in studentsData) {
          final student = Student.fromJson(studentData);
          await StorageService.saveStudent(student);
        }
        
        Logger.info(_logTag, 'Downloaded ${studentsData.length} students');
      }
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to sync students', e, stack);
      rethrow;
    }
  }
  
  /// Download updates from server
  Future<void> _downloadUpdates() async {
    Logger.info(_logTag, 'Downloading updates from server');
    
    try {
      // Download schools data (for admin users)
      await _downloadSchools();
      
      // Download classes data
      await _downloadClasses();
      
      Logger.info(_logTag, 'Updates download completed');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to download updates', e, stack);
      rethrow;
    }
  }
  
  /// Download schools data
  Future<void> _downloadSchools() async {
    try {
      final response = await _dio.get('/schools');
      
      if (response.statusCode == 200) {
        final schoolsData = response.data['schools'] as List;
        
        for (final schoolData in schoolsData) {
          final school = School.fromJson(schoolData);
          await StorageService.saveSchool(school);
        }
        
        Logger.info(_logTag, 'Downloaded ${schoolsData.length} schools');
      }
    } catch (e) {
      Logger.warning(_logTag, 'Failed to download schools: $e');
      // Don't rethrow - schools might not be accessible for staff users
    }
  }
  
  /// Download classes data
  Future<void> _downloadClasses() async {
    try {
      final response = await _dio.get('/classes');
      
      if (response.statusCode == 200) {
        final classesData = response.data['classes'] as List;
        
        for (final classData in classesData) {
          final classModel = ClassModel.fromJson(classData);
          await StorageService.saveClass(classModel);
        }
        
        Logger.info(_logTag, 'Downloaded ${classesData.length} classes');
      }
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to download classes', e, stack);
      rethrow;
    }
  }
  
  /// Schedule retry with exponential backoff
  void _scheduleRetry() {
    if (_retryCount >= AppConfig.maxRetryAttempts) {
      Logger.warning(_logTag, 'Max retry attempts reached');
      return;
    }
    
    final delaySeconds = AppConfig.retryDelay.inSeconds * (1 << _retryCount);
    _retryCount++;
    
    Logger.info(_logTag, 'Scheduling retry #$_retryCount in ${delaySeconds}s');
    
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      _triggerAutoSync();
    });
  }
  
  /// Update pending counts
  Future<void> _updatePendingCounts() async {
    try {
      final unsyncedAttendance = StorageService.getUnsyncedAttendance();
      final allStudents = StorageService.getAllStudents();
      final unsyncedStudents = allStudents.where((s) => s.needsSync).length;
      
      state = state.copyWith(
        pendingAttendanceCount: unsyncedAttendance.length,
        pendingStudentsCount: unsyncedStudents,
      );
    } catch (e) {
      Logger.error(_logTag, 'Failed to update pending counts', e);
    }
  }
  
  /// Get device UUID for logging
  Future<String> _getDeviceUuid() async {
    // This should be implemented to get actual device UUID
    return 'device-uuid-placeholder';
  }
  
  /// Force sync now (manual trigger)
  Future<void> forceSyncNow() async {
    Logger.info(_logTag, 'Force sync triggered');
    await syncAll();
  }
  
  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return connectivity != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  
  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'is_syncing': state.isSyncing,
      'pending_attendance': state.pendingAttendanceCount,
      'pending_students': state.pendingStudentsCount,
      'last_sync': state.lastSyncTime?.toIso8601String(),
      'last_error': state.lastError,
      'retry_count': _retryCount,
    };
  }

  /// Trigger a manual sync
  static Future<void> triggerSync() async {
    Logger.info('SyncService', 'Manual sync triggered');
    // This is a placeholder for now
    // In a full implementation, this would trigger the sync process
  }

  @override
  void dispose() {
    Logger.info(_logTag, 'Disposing sync service');
    
    _connectivitySubscription.cancel();
    _autoSyncTimer?.cancel();
    _retryTimer?.cancel();
    _dio.close();
    
    super.dispose();
  }
}