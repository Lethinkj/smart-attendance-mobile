import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_log.g.dart';

/// Sync log model for tracking synchronization events
@HiveType(typeId: 5)
@JsonSerializable()
class SyncLog extends HiveObject {
  /// Unique sync log identifier
  @HiveField(0)
  final String id;
  
  /// Type of sync operation (attendance, students, classes, etc.)
  @HiveField(1)
  final String syncType;
  
  /// Sync operation (upload, download, bidirectional)
  @HiveField(2)
  final String operation;
  
  /// Sync status (pending, in_progress, success, failed)
  @HiveField(3)
  final String status;
  
  /// Number of records attempted to sync
  @HiveField(4)
  final int recordsAttempted;
  
  /// Number of records successfully synced
  @HiveField(5)
  final int recordsSucceeded;
  
  /// Number of records that failed to sync
  @HiveField(6)
  final int recordsFailed;
  
  /// Sync start timestamp
  @HiveField(7)
  final DateTime startedAt;
  
  /// Sync completion timestamp
  @HiveField(8)
  final DateTime? completedAt;
  
  /// Error message (if sync failed)
  @HiveField(9)
  final String? errorMessage;
  
  /// Detailed error information
  @HiveField(10)
  final Map<String, dynamic>? errorDetails;
  
  /// Device UUID that performed the sync
  @HiveField(11)
  final String deviceUuid;
  
  /// User ID who initiated the sync
  @HiveField(12)
  final String? userId;
  
  /// Network type during sync (wifi, cellular, etc.)
  @HiveField(13)
  final String? networkType;
  
  /// Sync duration in milliseconds
  @HiveField(14)
  final int? durationMs;
  
  /// Additional sync metadata
  @HiveField(15)
  final Map<String, dynamic>? metadata;
  
  SyncLog({
    required this.id,
    required this.syncType,
    required this.operation,
    required this.status,
    required this.recordsAttempted,
    required this.recordsSucceeded,
    required this.recordsFailed,
    DateTime? startedAt,
    this.completedAt,
    this.errorMessage,
    this.errorDetails,
    required this.deviceUuid,
    this.userId,
    this.networkType,
    this.durationMs,
    this.metadata,
  }) : startedAt = startedAt ?? DateTime.now();
  
  /// Create sync log from JSON
  factory SyncLog.fromJson(Map<String, dynamic> json) => _$SyncLogFromJson(json);
  
  /// Convert sync log to JSON
  Map<String, dynamic> toJson() => _$SyncLogToJson(this);
  
  /// Create copy with updated fields
  SyncLog copyWith({
    String? id,
    String? syncType,
    String? operation,
    String? status,
    int? recordsAttempted,
    int? recordsSucceeded,
    int? recordsFailed,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? errorDetails,
    String? deviceUuid,
    String? userId,
    String? networkType,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) {
    return SyncLog(
      id: id ?? this.id,
      syncType: syncType ?? this.syncType,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      recordsAttempted: recordsAttempted ?? this.recordsAttempted,
      recordsSucceeded: recordsSucceeded ?? this.recordsSucceeded,
      recordsFailed: recordsFailed ?? this.recordsFailed,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetails: errorDetails ?? this.errorDetails,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      userId: userId ?? this.userId,
      networkType: networkType ?? this.networkType,
      durationMs: durationMs ?? this.durationMs,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// Check if sync is completed
  bool get isCompleted => completedAt != null;
  
  /// Check if sync was successful
  bool get isSuccessful => status == 'success';
  
  /// Check if sync failed
  bool get isFailed => status == 'failed';
  
  /// Check if sync is in progress
  bool get isInProgress => status == 'in_progress';
  
  /// Get sync success rate as percentage
  double get successRate {
    if (recordsAttempted == 0) return 0.0;
    return (recordsSucceeded / recordsAttempted) * 100;
  }
  
  /// Get formatted duration
  String get formattedDuration {
    if (durationMs == null) return 'Unknown';
    
    final seconds = durationMs! / 1000;
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)}s';
    } else {
      final minutes = seconds / 60;
      return '${minutes.toStringAsFixed(1)}m';
    }
  }
  
  /// Get sync type display name
  String get syncTypeDisplayName {
    switch (syncType) {
      case 'attendance':
        return 'Attendance Records';
      case 'students':
        return 'Student Data';
      case 'classes':
        return 'Class Information';
      case 'users':
        return 'User Accounts';
      case 'full':
        return 'Full Synchronization';
      default:
        return syncType.toUpperCase();
    }
  }
  
  /// Get operation display name
  String get operationDisplayName {
    switch (operation) {
      case 'upload':
        return 'Upload to Server';
      case 'download':
        return 'Download from Server';
      case 'bidirectional':
        return 'Two-way Sync';
      default:
        return operation.toUpperCase();
    }
  }
  
  /// Get status display name with emoji
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return '⏳ Pending';
      case 'in_progress':
        return '🔄 In Progress';
      case 'success':
        return '✅ Success';
      case 'failed':
        return '❌ Failed';
      default:
        return status.toUpperCase();
    }
  }
  
  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case 'pending':
        return '#FF9800'; // Orange
      case 'in_progress':
        return '#2196F3'; // Blue
      case 'success':
        return '#4CAF50'; // Green
      case 'failed':
        return '#F44336'; // Red
      default:
        return '#757575'; // Grey
    }
  }
  
  /// Create a successful sync log
  static SyncLog success({
    required String syncType,
    required String operation,
    required int recordsAttempted,
    required int recordsSucceeded,
    required String deviceUuid,
    String? userId,
    String? networkType,
    int? durationMs,
    DateTime? startedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SyncLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      syncType: syncType,
      operation: operation,
      status: 'success',
      recordsAttempted: recordsAttempted,
      recordsSucceeded: recordsSucceeded,
      recordsFailed: recordsAttempted - recordsSucceeded,
      startedAt: startedAt ?? DateTime.now(),
      completedAt: DateTime.now(),
      deviceUuid: deviceUuid,
      userId: userId,
      networkType: networkType,
      durationMs: durationMs,
      metadata: metadata,
    );
  }
  
  /// Create a failed sync log
  static SyncLog failure({
    required String syncType,
    required String operation,
    required int recordsAttempted,
    required String errorMessage,
    required String deviceUuid,
    String? userId,
    String? networkType,
    int? durationMs,
    DateTime? startedAt,
    Map<String, dynamic>? errorDetails,
    Map<String, dynamic>? metadata,
  }) {
    return SyncLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      syncType: syncType,
      operation: operation,
      status: 'failed',
      recordsAttempted: recordsAttempted,
      recordsSucceeded: 0,
      recordsFailed: recordsAttempted,
      startedAt: startedAt ?? DateTime.now(),
      completedAt: DateTime.now(),
      errorMessage: errorMessage,
      errorDetails: errorDetails,
      deviceUuid: deviceUuid,
      userId: userId,
      networkType: networkType,
      durationMs: durationMs,
      metadata: metadata,
    );
  }
  
  @override
  String toString() {
    return 'SyncLog(id: $id, syncType: $syncType, operation: $operation, status: $status, records: $recordsSucceeded/$recordsAttempted)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncLog && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}