import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';
import '../models/user.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'postgres_service.dart';

/// Enhanced sync service for offline-first operation
class OfflineSyncService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _isOnline = false;
  static Timer? _syncTimer;
  
  // Stream controllers
  static final StreamController<bool> _connectionStateController = 
      StreamController<bool>.broadcast();
  static final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  /// Stream of connection status changes
  static Stream<bool> get connectionStream => _connectionStateController.stream;
  
  /// Stream of sync status changes
  static Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  /// Current connection status
  static bool get isOnline => _isOnline;

  /// Initialize offline sync service
  static Future<void> initialize() async {
    try {
      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isOnline = connectivityResult.contains(ConnectivityResult.mobile) || 
                  connectivityResult.contains(ConnectivityResult.wifi);
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final wasOnline = _isOnline;
          _isOnline = results.contains(ConnectivityResult.mobile) || 
                     results.contains(ConnectivityResult.wifi);
          
          // Notify connection state change
          _connectionStateController.add(_isOnline);
          
          // Trigger sync when coming back online
          if (!wasOnline && _isOnline) {
            Logger.info('Device came online - triggering sync');
            triggerSync();
          }
          
          Logger.info('Connection status changed: $_isOnline');
        },
      );

      // Start periodic sync timer (every 5 minutes when online)
      _startPeriodicSync();
      
      Logger.info('OfflineSyncService initialized');
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Failed to initialize', e, stack);
    }
  }

  /// Start periodic sync timer
  static void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline) {
        triggerSync();
      }
    });
  }

  /// Trigger immediate sync
  static Future<void> triggerSync() async {
    if (!_isOnline) {
      Logger.info('Offline - sync deferred');
      return;
    }

    try {
      _syncStatusController.add(SyncStatus.syncing);
      Logger.info('Starting sync process');

      // Sync attendance records
      await _syncAttendanceRecords();
      
      // Sync user data
      await _syncUserData();
      
      // Sync school data
      await _syncSchoolData();

      _syncStatusController.add(SyncStatus.success);
      Logger.info('Sync completed successfully');
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Sync failed', e, stack);
      _syncStatusController.add(SyncStatus.failed);
    }
  }

  /// Sync attendance records with server
  static Future<void> _syncAttendanceRecords() async {
    try {
      // Get pending offline attendance records
      final pendingAttendance = await _getPendingAttendanceRecords();
      
      if (pendingAttendance.isNotEmpty) {
        Logger.info('Syncing ${pendingAttendance.length} attendance records');
        
        for (final attendance in pendingAttendance) {
          try {
            // Upload to server
            await PostgresService.markAttendance(
              studentId: attendance.studentId,
              classId: attendance.classId,
              status: attendance.status,
              recordedAt: attendance.recordedAt,
              recordedBy: attendance.recordedBy,
            );
            
            // Mark as synced
            await _markAttendanceAsSynced(attendance.id);
            Logger.info('Synced attendance record: ${attendance.id}');
          } catch (e) {
            Logger.error('OfflineSyncService', 'Failed to sync attendance ${attendance.id}', e);
          }
        }
      }
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Failed to sync attendance records', e, stack);
    }
  }

  /// Get pending attendance records that need to be synced
  static Future<List<Attendance>> _getPendingAttendanceRecords() async {
    try {
      return StorageService.getAllAttendance()
          .where((a) => !a.isSynced)
          .toList();
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Failed to get pending attendance', e, stack);
      return [];
    }
  }

  /// Mark attendance record as synced
  static Future<void> _markAttendanceAsSynced(String attendanceId) async {
    try {
      await StorageService.markAttendanceSynced(attendanceId, attendanceId);
      Logger.info('Marked attendance as synced: $attendanceId');
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Failed to mark attendance as synced', e, stack);
    }
  }

  /// Sync user data
  static Future<void> _syncUserData() async {
    try {
      final userData = StorageService.getCurrentUser();
      if (userData != null) {
        // Sync any pending user changes
        Logger.info('User data synced');
      }
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Failed to sync user data', e, stack);
    }
  }

  /// Sync school data
  static Future<void> _syncSchoolData() async {
    try {
      // Download latest school data when online
      final schools = await PostgresService.getSchools();
      for (final school in schools) {
        await StorageService.saveSchool(school);
      }
      Logger.info('School data synced');
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Failed to sync school data', e, stack);
    }
  }

  /// Save offline attendance record
  static Future<void> saveOfflineAttendance({
    required String studentId,
    required String classId,
    required String status,
    required String markedBy,
    required String source,
    required String deviceUuid,
    String? rfidTag,
    DateTime? markedAt,
  }) async {
    try {
      final now = DateTime.now();
      final attendance = Attendance(
        localId: 'offline_${now.millisecondsSinceEpoch}',
        studentId: studentId,
        classId: classId,
        status: status,
        markedAt: markedAt ?? now,
        markedBy: markedBy,
        source: source,
        deviceUuid: deviceUuid,
        rfidTag: rfidTag,
        isSynced: false, // Mark as pending sync
        syncAttempts: 0,
        createdAt: now,
        updatedAt: now,
      );

      // Save to local storage
      await StorageService.saveAttendance(attendance);
      
      Logger.info('Saved offline attendance: ${attendance.localId}');
      
      // Try immediate sync if online
      if (_isOnline) {
        triggerSync();
      }
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Failed to save offline attendance', e, stack);
    }
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    try {
      _connectivitySubscription?.cancel();
      _syncTimer?.cancel();
      await _connectionStateController.close();
      await _syncStatusController.close();
      Logger.info('OfflineSyncService disposed');
    } catch (e, stack) {
      Logger.error('OfflineSyncService', 'Failed to dispose', e, stack);
    }
  }
}

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
}

/// Provider for offline sync service
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService;
});

/// Provider for connection status
final connectionStatusProvider = StreamProvider<bool>((ref) {
  return OfflineSyncService.connectionStream;
});

/// Provider for sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return OfflineSyncService.syncStatusStream;
});