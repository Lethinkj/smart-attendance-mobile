import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../enums/attendance_enums.dart';
import '../utils/logger.dart';

/// Simple attendance service that works with basic data persistence
class AttendanceService {
  static const String _attendanceBox = 'attendance_records';
  static const String _studentsBox = 'students';
  static const String _classesBox = 'classes';
  static const String _settingsBox = 'settings';
  
  static const Uuid _uuid = Uuid();
  
  /// Initialize the service
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_attendanceBox);
      await Hive.openBox(_studentsBox);
      await Hive.openBox(_classesBox);
      await Hive.openBox(_settingsBox);
      print('AttendanceService initialized successfully');
    } catch (e) {
      print('Failed to initialize AttendanceService: $e');
    }
  }
  
  /// Mark attendance for a student
  static Future<AttendanceResult> markAttendance({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
    required AttendanceStatus status,
    String? rfidTag,
    String? deviceId,
  }) async {
    try {
      final box = Hive.box(_attendanceBox);
      
      // Check for duplicate attendance today
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final attendanceKey = '${studentId}_${classId}_$todayKey';
      
      final existingAttendance = box.get(attendanceKey);
      if (existingAttendance != null) {
        return AttendanceResult.duplicate(
          'Attendance already marked for today',
          existingAttendance,
        );
      }
      
      // Create attendance record
      final attendance = {
        'id': _uuid.v4(),
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'className': className,
        'status': status.name,
        'timestamp': DateTime.now().toIso8601String(),
        'rfidTag': rfidTag,
        'deviceId': deviceId ?? 'manual',
        'markedBy': 'current_user', // TODO: Get from auth service
      };
      
      // Save attendance
      await box.put(attendanceKey, attendance);
      
      // Update student statistics
      await _updateStudentStats(studentId, status);
      
      // Update class statistics
      await _updateClassStats(classId, status);
      
      print('Attendance marked for $studentName: ${status.displayName}');
      return AttendanceResult.success(attendance);
      
    } catch (e) {
      print('Failed to mark attendance: $e');
      return AttendanceResult.failure('Failed to mark attendance: $e');
    }
  }
  
  /// Get today's attendance for a class
  static Future<List<Map<String, dynamic>>> getTodayAttendance(String classId) async {
    try {
      final box = Hive.box(_attendanceBox);
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      final allAttendance = <Map<String, dynamic>>[];
      
      for (final key in box.keys) {
        if (key.toString().contains(classId) && key.toString().contains(todayKey)) {
          final attendance = box.get(key);
          if (attendance != null) {
            allAttendance.add(Map<String, dynamic>.from(attendance));
          }
        }
      }
      
      return allAttendance;
    } catch (e) {
      print('Failed to get today\'s attendance: $e');
      return [];
    }
  }
  
  /// Get attendance for date range
  static Future<List<Map<String, dynamic>>> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? classId,
    String? studentId,
  }) async {
    try {
      final box = Hive.box(_attendanceBox);
      final allAttendance = <Map<String, dynamic>>[];
      
      for (final key in box.keys) {
        final attendance = box.get(key);
        if (attendance != null) {
          final attendanceMap = Map<String, dynamic>.from(attendance);
          final timestamp = DateTime.parse(attendanceMap['timestamp']);
          
          // Check date range
          if (timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
              timestamp.isBefore(endDate.add(const Duration(days: 1)))) {
            
            // Apply filters
            if (classId != null && attendanceMap['classId'] != classId) continue;
            if (studentId != null && attendanceMap['studentId'] != studentId) continue;
            
            allAttendance.add(attendanceMap);
          }
        }
      }
      
      return allAttendance..sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
    } catch (e) {
      print('Failed to get attendance by date range: $e');
      return [];
    }
  }
  
  /// Update attendance record
  static Future<bool> updateAttendance({
    required String studentId,
    required String classId,
    required DateTime date,
    required AttendanceStatus newStatus,
    String? notes,
  }) async {
    try {
      final box = Hive.box(_attendanceBox);
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final attendanceKey = '${studentId}_${classId}_$dateKey';
      
      final existingAttendance = box.get(attendanceKey);
      if (existingAttendance == null) {
        return false;
      }
      
      final updatedAttendance = Map<String, dynamic>.from(existingAttendance);
      updatedAttendance['status'] = newStatus.name;
      updatedAttendance['notes'] = notes;
      updatedAttendance['updatedAt'] = DateTime.now().toIso8601String();
      
      await box.put(attendanceKey, updatedAttendance);
      return true;
    } catch (e) {
      print('Failed to update attendance: $e');
      return false;
    }
  }
  
  /// Get attendance statistics for a class
  static Future<ClassAttendanceStats> getClassStats(String classId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      final attendance = await getAttendanceByDateRange(
        startDate: start,
        endDate: end,
        classId: classId,
      );
      
      final totalPresent = attendance.where((a) => a['status'] == 'present').length;
      final totalAbsent = attendance.where((a) => a['status'] == 'absent').length;
      final totalLate = attendance.where((a) => a['status'] == 'late').length;
      
      final attendanceRate = attendance.isNotEmpty 
          ? (totalPresent + totalLate) / attendance.length * 100
          : 0.0;
      
      return ClassAttendanceStats(
        classId: classId,
        totalRecords: attendance.length,
        totalPresent: totalPresent,
        totalAbsent: totalAbsent,
        totalLate: totalLate,
        attendanceRate: attendanceRate,
        dateRange: '${start.day}/${start.month} - ${end.day}/${end.month}',
      );
    } catch (e) {
      print('Failed to get class stats: $e');
      return ClassAttendanceStats.empty();
    }
  }
  
  /// Add a new student
  static Future<bool> addStudent({
    required String id,
    required String name,
    required String rollNumber,
    required String classId,
    String? rfidTag,
    String? email,
    String? phone,
  }) async {
    try {
      final box = Hive.box(_studentsBox);
      
      final student = {
        'id': id,
        'name': name,
        'rollNumber': rollNumber,
        'classId': classId,
        'rfidTag': rfidTag,
        'email': email,
        'phone': phone,
        'totalPresent': 0,
        'totalAbsent': 0,
        'totalLate': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      await box.put(id, student);
      print('Student added: $name');
      return true;
    } catch (e) {
      print('Failed to add student: $e');
      return false;
    }
  }
  
  /// Get all students in a class
  static Future<List<Map<String, dynamic>>> getStudentsByClass(String classId) async {
    try {
      final box = Hive.box(_studentsBox);
      final students = <Map<String, dynamic>>[];
      
      for (final key in box.keys) {
        final student = box.get(key);
        if (student != null) {
          final studentMap = Map<String, dynamic>.from(student);
          if (studentMap['classId'] == classId) {
            students.add(studentMap);
          }
        }
      }
      
      return students..sort((a, b) => a['name'].compareTo(b['name']));
    } catch (e) {
      print('Failed to get students by class: $e');
      return [];
    }
  }
  
  /// Find student by RFID tag
  static Future<Map<String, dynamic>?> findStudentByRfid(String rfidTag) async {
    try {
      final box = Hive.box(_studentsBox);
      
      for (final key in box.keys) {
        final student = box.get(key);
        if (student != null) {
          final studentMap = Map<String, dynamic>.from(student);
          if (studentMap['rfidTag'] == rfidTag) {
            return studentMap;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Failed to find student by RFID: $e');
      return null;
    }
  }
  
  /// Add a new class
  static Future<bool> addClass({
    required String id,
    required String name,
    required String schoolId,
    String? description,
  }) async {
    try {
      final box = Hive.box(_classesBox);
      
      final classData = {
        'id': id,
        'name': name,
        'schoolId': schoolId,
        'description': description,
        'totalPresent': 0,
        'totalAbsent': 0,
        'totalLate': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      await box.put(id, classData);
      print('Class added: $name');
      return true;
    } catch (e) {
      print('Failed to add class: $e');
      return false;
    }
  }
  
  /// Get all classes
  static Future<List<Map<String, dynamic>>> getAllClasses() async {
    try {
      final box = Hive.box(_classesBox);
      final classes = <Map<String, dynamic>>[];
      
      for (final key in box.keys) {
        final classData = box.get(key);
        if (classData != null) {
          classes.add(Map<String, dynamic>.from(classData));
        }
      }
      
      return classes..sort((a, b) => a['name'].compareTo(b['name']));
    } catch (e) {
      print('Failed to get all classes: $e');
      return [];
    }
  }
  
  /// Update student statistics
  static Future<void> _updateStudentStats(String studentId, AttendanceStatus status) async {
    try {
      final box = Hive.box(_studentsBox);
      final student = box.get(studentId);
      
      if (student != null) {
        final studentMap = Map<String, dynamic>.from(student);
        
        switch (status) {
          case AttendanceStatus.present:
            studentMap['totalPresent'] = (studentMap['totalPresent'] ?? 0) + 1;
            break;
          case AttendanceStatus.absent:
            studentMap['totalAbsent'] = (studentMap['totalAbsent'] ?? 0) + 1;
            break;
          case AttendanceStatus.late:
            studentMap['totalLate'] = (studentMap['totalLate'] ?? 0) + 1;
            break;
          case AttendanceStatus.excused:
            // Don't count excused absences in statistics
            break;
        }
        
        studentMap['lastAttendance'] = DateTime.now().toIso8601String();
        await box.put(studentId, studentMap);
      }
    } catch (e) {
      print('Failed to update student stats: $e');
    }
  }
  
  /// Update class statistics
  static Future<void> _updateClassStats(String classId, AttendanceStatus status) async {
    try {
      final box = Hive.box(_classesBox);
      final classData = box.get(classId);
      
      if (classData != null) {
        final classMap = Map<String, dynamic>.from(classData);
        
        switch (status) {
          case AttendanceStatus.present:
            classMap['totalPresent'] = (classMap['totalPresent'] ?? 0) + 1;
            break;
          case AttendanceStatus.absent:
            classMap['totalAbsent'] = (classMap['totalAbsent'] ?? 0) + 1;
            break;
          case AttendanceStatus.late:
            classMap['totalLate'] = (classMap['totalLate'] ?? 0) + 1;
            break;
          case AttendanceStatus.excused:
            // Don't count excused absences in statistics
            break;
        }
        
        await box.put(classId, classMap);
      }
    } catch (e) {
      print('Failed to update class stats: $e');
    }
  }
  
  /// Clear all attendance data
  static Future<void> clearAllData() async {
    try {
      await Hive.box(_attendanceBox).clear();
      await Hive.box(_studentsBox).clear();
      await Hive.box(_classesBox).clear();
      print('All attendance data cleared');
    } catch (e) {
      print('Failed to clear data: $e');
    }
  }
}

/// Result of attendance operation
class AttendanceResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final bool isDuplicate;
  
  const AttendanceResult._({
    required this.success,
    required this.message,
    this.data,
    this.isDuplicate = false,
  });
  
  factory AttendanceResult.success(Map<String, dynamic> data) => AttendanceResult._(
    success: true,
    message: 'Attendance marked successfully',
    data: data,
  );
  
  factory AttendanceResult.failure(String message) => AttendanceResult._(
    success: false,
    message: message,
  );
  
  factory AttendanceResult.duplicate(String message, Map<String, dynamic> existing) => AttendanceResult._(
    success: false,
    message: message,
    data: existing,
    isDuplicate: true,
  );
}

/// Class attendance statistics
class ClassAttendanceStats {
  final String classId;
  final int totalRecords;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final double attendanceRate;
  final String dateRange;
  
  const ClassAttendanceStats({
    required this.classId,
    required this.totalRecords,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.attendanceRate,
    required this.dateRange,
  });
  
  factory ClassAttendanceStats.empty() => const ClassAttendanceStats(
    classId: '',
    totalRecords: 0,
    totalPresent: 0,
    totalAbsent: 0,
    totalLate: 0,
    attendanceRate: 0.0,
    dateRange: '',
  );
}