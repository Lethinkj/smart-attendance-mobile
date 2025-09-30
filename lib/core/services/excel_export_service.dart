import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../models/student.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import '../../services/supabase_postgresql_service.dart';

/// Excel Export Service for Attendance Data
class ExcelExportService {
  static const String _logTag = 'ExcelExportService';

  /// Export attendance data to Excel file
  static Future<String> exportAttendanceToExcel({
    String? schoolId,
    String? className,
    DateTime? startDate,
    DateTime? endDate,
    bool includeLocalData = true,
    bool includeCloudData = true,
  }) async {
    try {
      Logger.info(_logTag, 'Starting attendance export to Excel...');

      // Create Excel workbook
      final excel = Excel.createExcel();
      
      // Remove default sheet
      excel.delete('Sheet1');
      
      // Create attendance sheet
      final attendanceSheet = excel['Attendance Report'];
      
      // Set up headers
      final headers = [
        'Date',
        'Student ID',
        'Student Name',
        'Class',
        'Section',
        'Roll Number',
        'Check In Time',
        'Check Out Time',
        'Status',
        'Method',
        'Remarks',
        'Duration (Hours)',
      ];
      
      // Add headers to sheet
      for (int i = 0; i < headers.length; i++) {
        final cell = attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: '#4472C4',
          fontColorHex: '#FFFFFF',
        );
      }
      
      // Collect attendance data
      List<Map<String, dynamic>> attendanceData = [];
      
      if (includeLocalData) {
        attendanceData.addAll(await _getLocalAttendanceData(
          schoolId: schoolId,
          className: className,
          startDate: startDate,
          endDate: endDate,
        ));
      }
      
      if (includeCloudData) {
        try {
          final cloudData = await _getCloudAttendanceData(
            schoolId: schoolId,
            className: className,
            startDate: startDate,
            endDate: endDate,
          );
          attendanceData.addAll(cloudData);
        } catch (e) {
          Logger.warning(_logTag, 'Failed to fetch cloud data: $e');
        }
      }
      
      // Remove duplicates (prefer cloud data over local)
      attendanceData = _removeDuplicateAttendance(attendanceData);
      
      // Sort by date and student name
      attendanceData.sort((a, b) {
        final dateComparison = a['date'].compareTo(b['date']);
        if (dateComparison != 0) return dateComparison;
        return a['studentName'].compareTo(b['studentName']);
      });
      
      // Add data rows
      for (int i = 0; i < attendanceData.length; i++) {
        final data = attendanceData[i];
        final rowIndex = i + 1;
        
        // Date
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 
            _formatDate(data['date']);
        
        // Student ID
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 
            data['studentId'] ?? '';
        
        // Student Name
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = 
            data['studentName'] ?? '';
        
        // Class
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = 
            data['className'] ?? '';
        
        // Section
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = 
            data['section'] ?? '';
        
        // Roll Number
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = 
            data['rollNumber'] ?? '';
        
        // Check In Time
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = 
            _formatTime(data['checkInTime']);
        
        // Check Out Time
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = 
            _formatTime(data['checkOutTime']);
        
        // Status
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = 
            data['status'] ?? '';
        
        // Method
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex)).value = 
            data['method'] ?? '';
        
        // Remarks
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = 
            data['remarks'] ?? '';
        
        // Duration
        attendanceSheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex)).value = 
            _calculateDuration(data['checkInTime'], data['checkOutTime']);
      }
      
      // Create summary sheet
      await _createSummarySheet(excel, attendanceData);
      
      // Save file
      final fileName = _generateFileName(schoolId, className, startDate, endDate);
      final filePath = await _saveExcelFile(excel, fileName);
      
      Logger.info(_logTag, 'Excel export completed: $filePath');
      return filePath;
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Error exporting to Excel', e, stack);
      rethrow;
    }
  }

  /// Export student list to Excel
  static Future<String> exportStudentsToExcel({String? schoolId, String? className}) async {
    try {
      Logger.info(_logTag, 'Exporting students to Excel...');

      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      
      final sheet = excel['Student List'];
      
      // Headers
      final headers = [
        'Student ID',
        'Name',
        'Class',
        'Section', 
        'Roll Number',
        'RFID Tag',
        'Parent Name',
        'Parent Phone',
        'Address',
        'Date of Birth',
        'Status',
      ];
      
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(bold: true, backgroundColorHex: '#4472C4', fontColorHex: '#FFFFFF');
      }
      
      // Get student data
      final students = StorageService.getAllStudents();
      
      for (int i = 0; i < students.length; i++) {
        final student = students[i];
        final rowIndex = i + 1;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = student['studentId'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = student['name'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = student['className'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = student['section'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = student['rollNumber'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = student['rfidTag'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = student['parentName'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = student['parentPhone'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = student['address'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex)).value = student['dateOfBirth'];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = student['isActive'] ? 'Active' : 'Inactive';
      }
      
      final fileName = 'students_${schoolId ?? 'all'}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = await _saveExcelFile(excel, fileName);
      
      Logger.info(_logTag, 'Students export completed: $filePath');
      return filePath;
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Error exporting students to Excel', e, stack);
      rethrow;
    }
  }

  /// Share Excel file
  static Future<void> shareExcelFile(String filePath) async {
    try {
      Logger.info(_logTag, 'Sharing Excel file: $filePath');
      
      if (kIsWeb) {
        // For web, we'll need to download the file
        Logger.warning(_logTag, 'File sharing not supported on web platform');
        return;
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(filePath)], text: 'Attendance Report');
        Logger.info(_logTag, 'Excel file shared successfully');
      } else {
        throw Exception('File not found: $filePath');
      }
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Error sharing Excel file', e, stack);
      rethrow;
    }
  }

  // Private helper methods
  
  static Future<List<Map<String, dynamic>>> _getLocalAttendanceData({
    String? schoolId,
    String? className,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final attendanceData = <Map<String, dynamic>>[];
      final students = StorageService.getAllStudents();
      final studentMap = <String, Map<String, dynamic>>{};
      
      // Create student lookup map
      for (final student in students) {
        studentMap[student['studentId']] = student;
      }
      
      // Get attendance records (you'll need to implement this in StorageService)
      // For now, using a placeholder
      final allAttendance = <Map<String, dynamic>>[];  // Replace with actual storage method
      
      for (final attendance in allAttendance) {
        final student = studentMap[attendance['studentId']];
        if (student == null) continue;
        
        // Apply filters
        if (schoolId != null && student['schoolId'] != schoolId) continue;
        if (className != null && student['className'] != className) continue;
        
        final attendanceDate = DateTime.parse(attendance['date']);
        if (startDate != null && attendanceDate.isBefore(startDate)) continue;
        if (endDate != null && attendanceDate.isAfter(endDate)) continue;
        
        attendanceData.add({
          ...attendance,
          'studentName': student['name'],
          'rollNumber': student['rollNumber'],
          'source': 'local',
        });
      }
      
      return attendanceData;
    } catch (e, stack) {
      Logger.error(_logTag, 'Error getting local attendance data', e, stack);
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> _getCloudAttendanceData({
    String? schoolId,
    String? className,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This would fetch from your cloud database
      // Implementation depends on your backend API
      Logger.info(_logTag, 'Fetching cloud attendance data...');
      
      // Placeholder - implement actual cloud data fetching
      return [];
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Error getting cloud attendance data', e, stack);
      return [];
    }
  }
  
  static List<Map<String, dynamic>> _removeDuplicateAttendance(List<Map<String, dynamic>> data) {
    final uniqueData = <String, Map<String, dynamic>>{};
    
    for (final item in data) {
      final key = '${item['studentId']}_${item['date']}';
      
      // Prefer cloud data over local data
      if (!uniqueData.containsKey(key) || item['source'] == 'cloud') {
        uniqueData[key] = item;
      }
    }
    
    return uniqueData.values.toList();
  }
  
  static Future<void> _createSummarySheet(Excel excel, List<Map<String, dynamic>> data) async {
    final summarySheet = excel['Summary'];
    
    // Calculate statistics
    final totalRecords = data.length;
    final presentCount = data.where((d) => d['status'] == 'Present').length;
    final absentCount = data.where((d) => d['status'] == 'Absent').length;
    final lateCount = data.where((d) => d['status'] == 'Late').length;
    
    // Add summary data
    final summaryData = [
      ['Metric', 'Value'],
      ['Total Records', totalRecords],
      ['Present', presentCount],
      ['Absent', absentCount],
      ['Late', lateCount],
      ['Attendance Rate', '${((presentCount / totalRecords) * 100).toStringAsFixed(1)}%'],
    ];
    
    for (int row = 0; row < summaryData.length; row++) {
      for (int col = 0; col < summaryData[row].length; col++) {
        final cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = summaryData[row][col];
        
        if (row == 0) {
          cell.cellStyle = CellStyle(bold: true, backgroundColorHex: '#4472C4', fontColorHex: '#FFFFFF');
        }
      }
    }
  }
  
  static String _generateFileName(String? schoolId, String? className, DateTime? startDate, DateTime? endDate) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final parts = <String>[];
    
    parts.add('attendance_report');
    
    if (schoolId != null) parts.add('school_$schoolId');
    if (className != null) parts.add('class_$className');
    if (startDate != null) parts.add('from_${_formatDateForFilename(startDate)}');
    if (endDate != null) parts.add('to_${_formatDateForFilename(endDate)}');
    
    parts.add(timestamp.toString());
    
    return '${parts.join('_')}.xlsx';
  }
  
  static Future<String> _saveExcelFile(Excel excel, String fileName) async {
    if (kIsWeb) {
      // For web platform, save to downloads or show save dialog
      final bytes = excel.save();
      if (bytes != null) {
        // Web-specific file saving logic would go here
        return 'web_download/$fileName';
      }
      throw Exception('Failed to generate Excel file');
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      final bytes = excel.save();
      
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return filePath;
      }
      
      throw Exception('Failed to generate Excel file');
    }
  }
  
  static String _formatDate(dynamic date) {
    if (date == null) return '';
    
    try {
      final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }
  
  static String _formatTime(dynamic time) {
    if (time == null) return '';
    
    try {
      final dateTime = time is DateTime ? time : DateTime.parse(time.toString());
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time.toString();
    }
  }
  
  static String _formatDateForFilename(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
  
  static String _calculateDuration(dynamic checkIn, dynamic checkOut) {
    if (checkIn == null || checkOut == null) return '';
    
    try {
      final checkInTime = checkIn is DateTime ? checkIn : DateTime.parse(checkIn.toString());
      final checkOutTime = checkOut is DateTime ? checkOut : DateTime.parse(checkOut.toString());
      
      final duration = checkOutTime.difference(checkInTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      
      return '${hours}:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}