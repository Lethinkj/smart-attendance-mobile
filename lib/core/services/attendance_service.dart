import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/attendance.dart';
import '../models/student.dart';
import '../models/class_model.dart';
import '../models/device.dart';
import '../enums/attendance_enums.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'sync_service.dart';
import 'auth_service.dart';

/// Attendance service with duplicate prevention and RFID tag management
class AttendanceService {
  static const String _duplicateTimeWindow = 'duplicate_time_window'; // in minutes
  static const int _defaultDuplicateWindow = 5; // 5 minutes default
  
  static const Uuid _uuid = Uuid();
  
  /// Mark attendance using RFID tag
  static Future<AttendanceResult> markAttendance({
    required String rfidTag,
    required String classId,
    required String deviceId,
    AttendanceStatus status = AttendanceStatus.present,
  }) async {
    try {
      // Validate authentication
      if (!AuthService.isAuthenticated) {
        return AttendanceResult.failure('User not authenticated');
      }
      
      // Validate staff permission
      if (!AuthService.hasPermission(Permission.markAttendance)) {
        return AttendanceResult.failure('No permission to mark attendance');
      }
      
      // Find student by RFID tag
      final student = await _findStudentByRfidTag(rfidTag);
      if (student == null) {
        return AttendanceResult.failure('Student not found for RFID tag: $rfidTag');
      }
      
      // Validate class exists
      final classModel = StorageService.getClass(classId);
      if (classModel == null) {
        return AttendanceResult.failure('Class not found');
      }
      
      // Check if student belongs to this class
      if (!classModel.studentIds.contains(student.id)) {
        return AttendanceResult.failure('Student ${student.name} is not enrolled in this class');
      }
      
      // Check for duplicate attendance
      final duplicateCheck = await _checkDuplicateAttendance(
        studentId: student.id,
        classId: classId,
        date: DateTime.now(),
      );
      
      if (duplicateCheck.isDuplicate) {
        return AttendanceResult.duplicate(
          student,
          duplicateCheck.existingAttendance!,
          'Attendance already marked ${duplicateCheck.minutesAgo} minutes ago',
        );
      }
      
      // Create attendance record
      final attendance = Attendance(
        localId: _uuid.v4(),
        studentId: student.id,
        classId: classId,
        markedAt: DateTime.now(),
        markedBy: AuthService.currentUser?.id ?? 'unknown',
        source: 'rfid',
        deviceUuid: deviceId,
        rfidTag: rfidTag,
        status: status.name,
      );
      
      // Save attendance
      await StorageService.saveAttendance(attendance);
      
      // Update student's last attendance
      final updatedStudent = student.copyWith(
        lastAttendanceDate: attendance.timestamp,
        totalPresent: status == AttendanceStatus.present 
            ? student.totalPresent + 1 
            : student.totalPresent,
        totalAbsent: status == AttendanceStatus.absent 
            ? student.totalAbsent + 1 
            : student.totalAbsent,
      );
      await StorageService.saveStudent(updatedStudent);
      
      // Update class statistics
      await _updateClassStatistics(classId, status);
      
      // Trigger sync
      SyncService.triggerSync();
      
      Logger.info('Attendance marked for student: ${student.name} (${status.name})');
      return AttendanceResult.success(attendance, student);
      
    } catch (e, stack) {
      Logger.error('Failed to mark attendance', e, stack);
      return AttendanceResult.failure('Failed to mark attendance: ${e.toString()}');
    }
  }
  
  /// Mark bulk attendance for multiple students
  static Future<BulkAttendanceResult> markBulkAttendance({
    required List<String> studentIds,
    required String classId,
    required String deviceId,
    required AttendanceStatus status,
  }) async {
    final results = <String, AttendanceResult>{};
    final successful = <Attendance>[];
    final failed = <String>[];
    
    try {
      // Validate authentication and permissions
      if (!AuthService.isAuthenticated || !AuthService.hasPermission(Permission.markAttendance)) {
        return BulkAttendanceResult(
          successful: [],
          failed: {for (var id in studentIds) id: 'No permission'},
          totalProcessed: studentIds.length,
        );
      }
      
      // Validate class
      final classModel = StorageService.getClass(classId);
      if (classModel == null) {
        return BulkAttendanceResult(
          successful: [],
          failed: {for (var id in studentIds) id: 'Class not found'},
          totalProcessed: studentIds.length,
        );
      }
      
      // Process each student
      for (final studentId in studentIds) {
        final student = StorageService.getStudent(studentId);
        if (student == null) {
          results[studentId] = AttendanceResult.failure('Student not found');
          failed.add(studentId);
          continue;
        }
        
        // Check if student belongs to class
        if (!classModel.studentIds.contains(studentId)) {
          results[studentId] = AttendanceResult.failure('Student not in class');
          failed.add(studentId);
          continue;
        }
        
        // Check for duplicates
        final duplicateCheck = await _checkDuplicateAttendance(
          studentId: studentId,
          classId: classId,
          date: DateTime.now(),
        );
        
        if (duplicateCheck.isDuplicate) {
          results[studentId] = AttendanceResult.duplicate(
            student,
            duplicateCheck.existingAttendance!,
            'Already marked',
          );
          continue;
        }
        
        // Create attendance
        final attendance = Attendance(
          id: _uuid.v4(),
          studentId: studentId,
          studentName: student.name,
          classId: classId,
          className: classModel.name,
          schoolId: classModel.schoolId,
          rfidTag: student.rfidTag ?? '',
          status: status,
          timestamp: DateTime.now(),
          deviceId: deviceId,
          markedBy: AuthService.currentUser!.id,
          markedByName: AuthService.currentUser!.name,
          syncStatus: SyncStatus.pending,
        );
        
        await StorageService.saveAttendance(attendance);
        successful.add(attendance);
        results[studentId] = AttendanceResult.success(attendance, student);
        
        // Update student stats
        final updatedStudent = student.copyWith(
          lastAttendanceDate: attendance.timestamp,
          totalPresent: status == AttendanceStatus.present 
              ? student.totalPresent + 1 
              : student.totalPresent,
          totalAbsent: status == AttendanceStatus.absent 
              ? student.totalAbsent + 1 
              : student.totalAbsent,
        );
        await StorageService.saveStudent(updatedStudent);
      }
      
      // Update class statistics
      if (successful.isNotEmpty) {
        await _updateClassStatistics(classId, status, count: successful.length);
        SyncService.triggerSync();
      }
      
      Logger.info('Bulk attendance: ${successful.length} successful, ${failed.length} failed');
      
      return BulkAttendanceResult(
        successful: successful,
        failed: {for (var id in failed) id: results[id]?.message ?? 'Unknown error'},
        totalProcessed: studentIds.length,
      );
      
    } catch (e, stack) {
      Logger.error('Bulk attendance failed', e, stack);
      return BulkAttendanceResult(
        successful: successful,
        failed: {for (var id in studentIds) id: 'Processing error'},
        totalProcessed: studentIds.length,
      );
    }
  }
  
  /// Get attendance for a specific date range
  static List<Attendance> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? classId,
    String? studentId,
  }) {
    try {
      final allAttendance = StorageService.getAllAttendance();
      
      return allAttendance.where((attendance) {
        // Date range filter
        final attendanceDate = DateTime(
          attendance.timestamp.year,
          attendance.timestamp.month,
          attendance.timestamp.day,
        );
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        
        if (attendanceDate.isBefore(start) || attendanceDate.isAfter(end)) {
          return false;
        }
        
        // Class filter
        if (classId != null && attendance.classId != classId) {
          return false;
        }
        
        // Student filter
        if (studentId != null && attendance.studentId != studentId) {
          return false;
        }
        
        return true;
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e, stack) {
      Logger.error('Failed to get attendance by date range', e, stack);
      return [];
    }
  }
  
  /// Get today's attendance for a class
  static List<Attendance> getTodayAttendance(String classId) {
    final today = DateTime.now();
    return getAttendanceByDateRange(
      startDate: today,
      endDate: today,
      classId: classId,
    );
  }
  
  /// Get attendance statistics for a class
  static ClassAttendanceStats getClassAttendanceStats({
    required String classId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      final classModel = StorageService.getClass(classId);
      if (classModel == null) {
        return ClassAttendanceStats.empty();
      }
      
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      final attendance = getAttendanceByDateRange(
        startDate: start,
        endDate: end,
        classId: classId,
      );
      
      final totalStudents = classModel.studentIds.length;
      final totalPresent = attendance.where((a) => a.status == AttendanceStatus.present).length;
      final totalAbsent = attendance.where((a) => a.status == AttendanceStatus.absent).length;
      final totalLate = attendance.where((a) => a.status == AttendanceStatus.late).length;
      
      final attendanceRate = totalStudents > 0 
          ? (totalPresent + totalLate) / (totalPresent + totalAbsent + totalLate) * 100
          : 0.0;
      
      return ClassAttendanceStats(
        classId: classId,
        className: classModel.name,
        totalStudents: totalStudents,
        totalPresent: totalPresent,
        totalAbsent: totalAbsent,
        totalLate: totalLate,
        attendanceRate: attendanceRate,
        dateRange: DateRange(start, end),
      );
    } catch (e, stack) {
      Logger.error('Failed to get class attendance stats', e, stack);
      return ClassAttendanceStats.empty();
    }
  }
  
  /// Update or correct attendance record
  static Future<bool> updateAttendance({
    required String attendanceId,
    required AttendanceStatus newStatus,
    String? notes,
  }) async {
    try {
      if (!AuthService.hasPermission(Permission.markAttendance)) {
        return false;
      }
      
      final attendance = StorageService.getAttendance(attendanceId);
      if (attendance == null) return false;
      
      final updatedAttendance = attendance.copyWith(
        status: newStatus,
        notes: notes,
        syncStatus: SyncStatus.pending,
      );
      
      await StorageService.saveAttendance(updatedAttendance);
      
      // Update student statistics
      final student = StorageService.getStudent(attendance.studentId);
      if (student != null) {
        final updatedStudent = _recalculateStudentStats(student);
        await StorageService.saveStudent(updatedStudent);
      }
      
      SyncService.triggerSync();
      return true;
    } catch (e, stack) {
      Logger.error('Failed to update attendance', e, stack);
      return false;
    }
  }
  
  /// Set duplicate prevention time window (in minutes)
  static Future<void> setDuplicateTimeWindow(int minutes) async {
    await StorageService.setSetting(_duplicateTimeWindow, minutes);
  }
  
  /// Get duplicate prevention time window
  static int getDuplicateTimeWindow() {
    return StorageService.getSetting<int>(
      _duplicateTimeWindow,
      defaultValue: _defaultDuplicateWindow,
    ) ?? _defaultDuplicateWindow;
  }
  
  /// Find student by RFID tag
  static Future<Student?> _findStudentByRfidTag(String rfidTag) async {
    try {
      final allStudents = StorageService.getAllStudents();
      return allStudents.cast<Student?>().firstWhere(
        (student) => student?.rfidTag == rfidTag,
        orElse: () => null,
      );
    } catch (e, stack) {
      Logger.error('Failed to find student by RFID tag', e, stack);
      return null;
    }
  }
  
  /// Check for duplicate attendance
  static Future<DuplicateCheckResult> _checkDuplicateAttendance({
    required String studentId,
    required String classId,
    required DateTime date,
  }) async {
    try {
      final timeWindow = getDuplicateTimeWindow();
      final cutoffTime = date.subtract(Duration(minutes: timeWindow));
      
      final recentAttendance = StorageService.getAttendanceByStudent(studentId)
          .where((attendance) => 
              attendance.classId == classId &&
              attendance.timestamp.isAfter(cutoffTime) &&
              attendance.timestamp.isBefore(date.add(const Duration(minutes: 1))))
          .toList();
      
      if (recentAttendance.isNotEmpty) {
        final existing = recentAttendance.first;
        final minutesAgo = date.difference(existing.timestamp).inMinutes;
        
        return DuplicateCheckResult(
          isDuplicate: true,
          existingAttendance: existing,
          minutesAgo: minutesAgo,
        );
      }
      
      return const DuplicateCheckResult(isDuplicate: false);
    } catch (e, stack) {
      Logger.error('Duplicate check failed', e, stack);
      return const DuplicateCheckResult(isDuplicate: false);
    }
  }
  
  /// Update class statistics
  static Future<void> _updateClassStatistics(
    String classId, 
    AttendanceStatus status, {
    int count = 1,
  }) async {
    try {
      final classModel = StorageService.getClass(classId);
      if (classModel == null) return;
      
      int newPresent = classModel.totalPresent;
      int newAbsent = classModel.totalAbsent;
      
      switch (status) {
        case AttendanceStatus.present:
        case AttendanceStatus.late:
          newPresent += count;
          break;
        case AttendanceStatus.absent:
          newAbsent += count;
          break;
      }
      
      final updatedClass = classModel.copyWith(
        totalPresent: newPresent,
        totalAbsent: newAbsent,
      );
      
      await StorageService.saveClass(updatedClass);
    } catch (e, stack) {
      Logger.error('Failed to update class statistics', e, stack);
    }
  }
  
  /// Recalculate student statistics
  static Student _recalculateStudentStats(Student student) {
    try {
      final attendance = StorageService.getAttendanceByStudent(student.id);
      
      final totalPresent = attendance
          .where((a) => a.status == AttendanceStatus.present || a.status == AttendanceStatus.late)
          .length;
      
      final totalAbsent = attendance
          .where((a) => a.status == AttendanceStatus.absent)
          .length;
      
      final lastAttendance = attendance.isNotEmpty 
          ? attendance.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b)
          : null;
      
      return student.copyWith(
        totalPresent: totalPresent,
        totalAbsent: totalAbsent,
        lastAttendanceDate: lastAttendance?.timestamp,
      );
    } catch (e, stack) {
      Logger.error('Failed to recalculate student stats', e, stack);
      return student;
    }
  }
}

/// Result of attendance marking operation
class AttendanceResult {
  final bool success;
  final String? message;
  final Attendance? attendance;
  final Student? student;
  final bool isDuplicate;
  final Attendance? existingAttendance;
  
  const AttendanceResult._({
    required this.success,
    this.message,
    this.attendance,
    this.student,
    this.isDuplicate = false,
    this.existingAttendance,
  });
  
  factory AttendanceResult.success(Attendance attendance, Student student) => 
      AttendanceResult._(
        success: true,
        attendance: attendance,
        student: student,
      );
  
  factory AttendanceResult.failure(String message) => AttendanceResult._(
    success: false,
    message: message,
  );
  
  factory AttendanceResult.duplicate(
    Student student,
    Attendance existingAttendance,
    String message,
  ) => AttendanceResult._(
    success: false,
    message: message,
    student: student,
    isDuplicate: true,
    existingAttendance: existingAttendance,
  );
}

/// Result of bulk attendance operation
class BulkAttendanceResult {
  final List<Attendance> successful;
  final Map<String, String> failed;
  final int totalProcessed;
  
  const BulkAttendanceResult({
    required this.successful,
    required this.failed,
    required this.totalProcessed,
  });
  
  int get successCount => successful.length;
  int get failureCount => failed.length;
  double get successRate => totalProcessed > 0 ? successCount / totalProcessed : 0.0;
}

/// Duplicate check result
class DuplicateCheckResult {
  final bool isDuplicate;
  final Attendance? existingAttendance;
  final int minutesAgo;
  
  const DuplicateCheckResult({
    required this.isDuplicate,
    this.existingAttendance,
    this.minutesAgo = 0,
  });
}

/// Class attendance statistics
class ClassAttendanceStats {
  final String classId;
  final String className;
  final int totalStudents;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final double attendanceRate;
  final DateRange dateRange;
  
  const ClassAttendanceStats({
    required this.classId,
    required this.className,
    required this.totalStudents,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.attendanceRate,
    required this.dateRange,
  });
  
  factory ClassAttendanceStats.empty() => ClassAttendanceStats(
    classId: '',
    className: '',
    totalStudents: 0,
    totalPresent: 0,
    totalAbsent: 0,
    totalLate: 0,
    attendanceRate: 0.0,
    dateRange: DateRange(DateTime.now(), DateTime.now()),
  );
}

/// Date range helper
class DateRange {
  final DateTime start;
  final DateTime end;
  
  const DateRange(this.start, this.end);
  
  int get days => end.difference(start).inDays + 1;
}