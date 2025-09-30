import 'dart:math';
import '../models/attendance.dart';
import '../models/student.dart';  
import '../models/class_model.dart';
import '../models/school.dart';
import '../models/user.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'auth_service.dart';

/// Dashboard service for generating statistics and analytics
class DashboardService {
  
  /// Get comprehensive dashboard data based on user role
  static DashboardData getDashboardData({DateTime? date}) {
    final currentDate = date ?? DateTime.now();
    
    if (AuthService.isAdmin) {
      return _getAdminDashboard(currentDate);
    } else if (AuthService.isStaff) {
      return _getStaffDashboard(currentDate);
    } else {
      return DashboardData.empty();
    }
  }
  
  /// Get admin dashboard with school-wide statistics
  static DashboardData _getAdminDashboard(DateTime date) {
    try {
      final schools = StorageService.getAllSchools();
      final allStudents = StorageService.getAllStudents();
      final allClasses = StorageService.getAllClasses();
      final allUsers = StorageService.getAllUsers();
      final todayAttendance = _getTodayAttendance(date);
      
      // Overall statistics
      final totalSchools = schools.length;
      final totalStudents = allStudents.length;
      final totalClasses = allClasses.length;
      final totalStaff = allUsers.where((u) => u.role == UserRole.staff).length;
      
      // Today's attendance
      final todayPresent = todayAttendance.where((a) => 
          a.status == AttendanceStatus.present || 
          a.status == AttendanceStatus.late).length;
      final todayAbsent = todayAttendance.where((a) => 
          a.status == AttendanceStatus.absent).length;
      final attendanceRate = _calculateAttendanceRate(todayPresent, todayAbsent);
      
      // School performance
      final schoolStats = schools.map((school) => 
          _getSchoolStatistics(school, date)).toList();
      
      // Recent activities
      final recentActivities = _getRecentActivities(limit: 10);
      
      // Trends
      final weeklyTrend = _getWeeklyAttendanceTrend(date);
      final monthlyTrend = _getMonthlyAttendanceTrend(date);
      
      return DashboardData(
        userRole: UserRole.admin,
        totalSchools: totalSchools,
        totalStudents: totalStudents,
        totalClasses: totalClasses,
        totalStaff: totalStaff,
        todayPresent: todayPresent,
        todayAbsent: todayAbsent,
        attendanceRate: attendanceRate,
        schoolStats: schoolStats,
        classStats: [],
        recentActivities: recentActivities,
        weeklyTrend: weeklyTrend,
        monthlyTrend: monthlyTrend,
        alerts: _generateAlerts(),
      );
    } catch (e, stack) {
      Logger.error('Failed to generate admin dashboard', e, stack);
      return DashboardData.empty();
    }
  }
  
  /// Get staff dashboard with class-specific statistics
  static DashboardData _getStaffDashboard(DateTime date) {
    try {
      final currentUser = AuthService.currentUser!;
      final userClasses = StorageService.getAllClasses()
          .where((c) => c.teacherId == currentUser.id)
          .toList();
      
      if (userClasses.isEmpty) {
        return DashboardData.empty();
      }
      
      // Get students from user's classes
      final classStudentIds = userClasses
          .expand((c) => c.studentIds)
          .toSet();
      final classStudents = StorageService.getAllStudents()
          .where((s) => classStudentIds.contains(s.id))
          .toList();
      
      // Today's attendance for user's classes
      final todayAttendance = _getTodayAttendance(date)
          .where((a) => userClasses.any((c) => c.id == a.classId))
          .toList();
      
      final todayPresent = todayAttendance.where((a) => 
          a.status == AttendanceStatus.present || 
          a.status == AttendanceStatus.late).length;
      final todayAbsent = todayAttendance.where((a) => 
          a.status == AttendanceStatus.absent).length;
      
      // Class statistics
      final classStats = userClasses.map((classModel) => 
          _getClassStatistics(classModel, date)).toList();
      
      // Recent activities for user's classes
      final recentActivities = _getRecentActivities(
        classIds: userClasses.map((c) => c.id).toList(),
        limit: 10,
      );
      
      // Trends for user's classes
      final weeklyTrend = _getWeeklyAttendanceTrend(
        date, 
        classIds: userClasses.map((c) => c.id).toList(),
      );
      
      return DashboardData(
        userRole: UserRole.staff,
        totalSchools: 0,
        totalStudents: classStudents.length,
        totalClasses: userClasses.length,
        totalStaff: 0,
        todayPresent: todayPresent,
        todayAbsent: todayAbsent,
        attendanceRate: _calculateAttendanceRate(todayPresent, todayAbsent),
        schoolStats: [],
        classStats: classStats,
        recentActivities: recentActivities,
        weeklyTrend: weeklyTrend,
        monthlyTrend: [],
        alerts: _generateClassAlerts(userClasses),
      );
    } catch (e, stack) {
      Logger.error('Failed to generate staff dashboard', e, stack);
      return DashboardData.empty();
    }
  }
  
  /// Get school-specific statistics
  static SchoolStatistics _getSchoolStatistics(School school, DateTime date) {
    try {
      final schoolClasses = StorageService.getAllClasses()
          .where((c) => c.schoolId == school.id)
          .toList();
      
      final schoolStudentIds = schoolClasses
          .expand((c) => c.studentIds)
          .toSet();
      
      final todayAttendance = _getTodayAttendance(date)
          .where((a) => a.schoolId == school.id)
          .toList();
      
      final present = todayAttendance.where((a) => 
          a.status == AttendanceStatus.present || 
          a.status == AttendanceStatus.late).length;
      final absent = todayAttendance.where((a) => 
          a.status == AttendanceStatus.absent).length;
      
      return SchoolStatistics(
        schoolId: school.id,
        schoolName: school.name,
        totalStudents: schoolStudentIds.length,
        totalClasses: schoolClasses.length,
        todayPresent: present,
        todayAbsent: absent,
        attendanceRate: _calculateAttendanceRate(present, absent),
      );
    } catch (e, stack) {
      Logger.error('Failed to get school statistics', e, stack);
      return SchoolStatistics.empty(school.id, school.name);
    }
  }
  
  /// Get class-specific statistics
  static ClassStatistics _getClassStatistics(ClassModel classModel, DateTime date) {
    try {
      final todayAttendance = _getTodayAttendance(date)
          .where((a) => a.classId == classModel.id)
          .toList();
      
      final present = todayAttendance.where((a) => 
          a.status == AttendanceStatus.present || 
          a.status == AttendanceStatus.late).length;
      final absent = todayAttendance.where((a) => 
          a.status == AttendanceStatus.absent).length;
      
      // Get low attendance students (< 75% in last 7 days)
      final lowAttendanceStudents = _getLowAttendanceStudents(
        classModel.id, 
        date.subtract(const Duration(days: 7)),
        date,
      );
      
      return ClassStatistics(
        classId: classModel.id,
        className: classModel.name,
        totalStudents: classModel.studentIds.length,
        todayPresent: present,
        todayAbsent: absent,
        attendanceRate: _calculateAttendanceRate(present, absent),
        lowAttendanceStudents: lowAttendanceStudents.length,
        averageAttendanceRate: _getClassAverageAttendance(classModel.id, date),
      );
    } catch (e, stack) {
      Logger.error('Failed to get class statistics', e, stack);
      return ClassStatistics.empty(classModel.id, classModel.name);
    }
  }
  
  /// Get recent activities
  static List<RecentActivity> _getRecentActivities({
    List<String>? classIds,
    int limit = 20,
  }) {
    try {
      final allAttendance = StorageService.getAllAttendance();
      
      var filteredAttendance = allAttendance;
      if (classIds != null) {
        filteredAttendance = allAttendance
            .where((a) => classIds.contains(a.classId))
            .toList();
      }
      
      filteredAttendance.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return filteredAttendance
          .take(limit)
          .map((attendance) => RecentActivity(
                type: ActivityType.attendance,
                title: '${attendance.studentName} marked ${attendance.status.name}',
                subtitle: 'Class: ${attendance.className}',
                timestamp: attendance.timestamp,
                icon: _getAttendanceIcon(attendance.status),
              ))
          .toList();
    } catch (e, stack) {
      Logger.error('Failed to get recent activities', e, stack);
      return [];
    }
  }
  
  /// Get weekly attendance trend
  static List<TrendData> _getWeeklyAttendanceTrend(
    DateTime date, {
    List<String>? classIds,
  }) {
    try {
      final weekData = <TrendData>[];
      
      for (int i = 6; i >= 0; i--) {
        final day = date.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        var dayAttendance = StorageService.getAllAttendance()
            .where((a) => 
                a.timestamp.isAfter(dayStart) && 
                a.timestamp.isBefore(dayEnd))
            .toList();
        
        if (classIds != null) {
          dayAttendance = dayAttendance
              .where((a) => classIds.contains(a.classId))
              .toList();
        }
        
        final present = dayAttendance.where((a) => 
            a.status == AttendanceStatus.present || 
            a.status == AttendanceStatus.late).length;
        final total = dayAttendance.length;
        
        weekData.add(TrendData(
          date: day,
          value: total > 0 ? (present / total * 100) : 0,
          label: _getDayLabel(day),
        ));
      }
      
      return weekData;
    } catch (e, stack) {
      Logger.error('Failed to get weekly trend', e, stack);
      return [];
    }
  }
  
  /// Get monthly attendance trend
  static List<TrendData> _getMonthlyAttendanceTrend(DateTime date) {
    try {
      final monthData = <TrendData>[];
      
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(date.year, date.month - i, 1);
        final monthEnd = DateTime(month.year, month.month + 1, 0);
        
        final monthAttendance = StorageService.getAllAttendance()
            .where((a) => 
                a.timestamp.year == month.year &&
                a.timestamp.month == month.month)
            .toList();
        
        final present = monthAttendance.where((a) => 
            a.status == AttendanceStatus.present || 
            a.status == AttendanceStatus.late).length;
        final total = monthAttendance.length;
        
        monthData.add(TrendData(
          date: month,
          value: total > 0 ? (present / total * 100) : 0,
          label: _getMonthLabel(month),
        ));
      }
      
      return monthData;
    } catch (e, stack) {
      Logger.error('Failed to get monthly trend', e, stack);
      return [];
    }
  }
  
  /// Generate system alerts
  static List<DashboardAlert> _generateAlerts() {
    final alerts = <DashboardAlert>[];
    
    try {
      // Low attendance alert
      final schools = StorageService.getAllSchools();
      for (final school in schools) {
        final schoolStats = _getSchoolStatistics(school, DateTime.now());
        if (schoolStats.attendanceRate < 70) {
          alerts.add(DashboardAlert(
            type: AlertType.lowAttendance,
            title: 'Low Attendance Alert',
            message: '${school.name} has ${schoolStats.attendanceRate.toStringAsFixed(1)}% attendance',
            severity: AlertSeverity.high,
            timestamp: DateTime.now(),
          ));
        }
      }
      
      // Sync issues alert
      final pendingSyncCount = _getPendingSyncCount();
      if (pendingSyncCount > 50) {
        alerts.add(DashboardAlert(
          type: AlertType.syncIssue,
          title: 'Sync Issues',
          message: '$pendingSyncCount records pending sync',
          severity: AlertSeverity.medium,
          timestamp: DateTime.now(),
        ));
      }
      
      // RFID device alerts
      final inactiveDevices = _getInactiveDeviceCount();
      if (inactiveDevices > 0) {
        alerts.add(DashboardAlert(
          type: AlertType.deviceOffline,
          title: 'Device Issues',
          message: '$inactiveDevices RFID devices offline',
          severity: AlertSeverity.medium,
          timestamp: DateTime.now(),
        ));
      }
      
    } catch (e, stack) {
      Logger.error('Failed to generate alerts', e, stack);
    }
    
    return alerts;
  }
  
  /// Generate class-specific alerts for staff
  static List<DashboardAlert> _generateClassAlerts(List<ClassModel> classes) {
    final alerts = <DashboardAlert>[];
    
    try {
      for (final classModel in classes) {
        final stats = _getClassStatistics(classModel, DateTime.now());
        
        // Low class attendance
        if (stats.attendanceRate < 75) {
          alerts.add(DashboardAlert(
            type: AlertType.lowAttendance,
            title: 'Low Class Attendance',
            message: '${classModel.name} has ${stats.attendanceRate.toStringAsFixed(1)}% attendance',
            severity: AlertSeverity.medium,
            timestamp: DateTime.now(),
          ));
        }
        
        // Students with low attendance
        if (stats.lowAttendanceStudents > 0) {
          alerts.add(DashboardAlert(
            type: AlertType.studentAtRisk,
            title: 'Students at Risk',
            message: '${stats.lowAttendanceStudents} students in ${classModel.name} have low attendance',
            severity: AlertSeverity.medium,
            timestamp: DateTime.now(),
          ));
        }
      }
    } catch (e, stack) {
      Logger.error('Failed to generate class alerts', e, stack);
    }
    
    return alerts;
  }
  
  // Helper methods
  
  static List<Attendance> _getTodayAttendance(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return StorageService.getAllAttendance()
        .where((a) => 
            a.timestamp.isAfter(startOfDay) && 
            a.timestamp.isBefore(endOfDay))
        .toList();
  }
  
  static double _calculateAttendanceRate(int present, int absent) {
    final total = present + absent;
    return total > 0 ? (present / total * 100) : 0.0;
  }
  
  static List<Student> _getLowAttendanceStudents(
    String classId, 
    DateTime startDate, 
    DateTime endDate,
  ) {
    try {
      final classModel = StorageService.getClass(classId);
      if (classModel == null) return [];
      
      final lowAttendanceStudents = <Student>[];
      
      for (final studentId in classModel.studentIds) {
        final student = StorageService.getStudent(studentId);
        if (student == null) continue;
        
        final studentAttendance = StorageService.getAttendanceByStudent(studentId)
            .where((a) => 
                a.classId == classId &&
                a.timestamp.isAfter(startDate) &&
                a.timestamp.isBefore(endDate))
            .toList();
        
        if (studentAttendance.isNotEmpty) {
          final present = studentAttendance.where((a) => 
              a.status == AttendanceStatus.present || 
              a.status == AttendanceStatus.late).length;
          final total = studentAttendance.length;
          final rate = (present / total * 100);
          
          if (rate < 75) {
            lowAttendanceStudents.add(student);
          }
        }
      }
      
      return lowAttendanceStudents;
    } catch (e, stack) {
      Logger.error('Failed to get low attendance students', e, stack);
      return [];
    }
  }
  
  static double _getClassAverageAttendance(String classId, DateTime date) {
    try {
      final last30Days = date.subtract(const Duration(days: 30));
      final attendance = StorageService.getAllAttendance()
          .where((a) => 
              a.classId == classId &&
              a.timestamp.isAfter(last30Days))
          .toList();
      
      if (attendance.isEmpty) return 0.0;
      
      final present = attendance.where((a) => 
          a.status == AttendanceStatus.present || 
          a.status == AttendanceStatus.late).length;
      
      return (present / attendance.length * 100);
    } catch (e, stack) {
      Logger.error('Failed to calculate class average attendance', e, stack);
      return 0.0;
    }
  }
  
  static int _getPendingSyncCount() {
    try {
      return StorageService.getAllAttendance()
          .where((a) => a.syncStatus == SyncStatus.pending)
          .length;
    } catch (e, stack) {
      Logger.error('Failed to get pending sync count', e, stack);
      return 0;
    }
  }
  
  static int _getInactiveDeviceCount() {
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 1));
      
      return StorageService.getAllDevices()
          .where((d) => d.lastSeen.isBefore(cutoff))
          .length;
    } catch (e, stack) {
      Logger.error('Failed to get inactive device count', e, stack);
      return 0;
    }
  }
  
  static String _getAttendanceIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return '✓';
      case AttendanceStatus.absent:
        return '✗';
      case AttendanceStatus.late:
        return '⚠';
    }
  }
  
  static String _getDayLabel(DateTime date) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }
  
  static String _getMonthLabel(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }
}

/// Dashboard data container
class DashboardData {
  final UserRole userRole;
  final int totalSchools;
  final int totalStudents;
  final int totalClasses;
  final int totalStaff;
  final int todayPresent;
  final int todayAbsent;
  final double attendanceRate;
  final List<SchoolStatistics> schoolStats;
  final List<ClassStatistics> classStats;
  final List<RecentActivity> recentActivities;
  final List<TrendData> weeklyTrend;
  final List<TrendData> monthlyTrend;
  final List<DashboardAlert> alerts;
  
  const DashboardData({
    required this.userRole,
    required this.totalSchools,
    required this.totalStudents,
    required this.totalClasses,
    required this.totalStaff,
    required this.todayPresent,
    required this.todayAbsent,
    required this.attendanceRate,
    required this.schoolStats,
    required this.classStats,
    required this.recentActivities,
    required this.weeklyTrend,
    required this.monthlyTrend,
    required this.alerts,
  });
  
  factory DashboardData.empty() => const DashboardData(
    userRole: UserRole.staff,
    totalSchools: 0,
    totalStudents: 0,
    totalClasses: 0,
    totalStaff: 0,
    todayPresent: 0,
    todayAbsent: 0,
    attendanceRate: 0.0,
    schoolStats: [],
    classStats: [],
    recentActivities: [],
    weeklyTrend: [],
    monthlyTrend: [],
    alerts: [],
  );
  
  int get todayTotal => todayPresent + todayAbsent;
  bool get hasAlerts => alerts.isNotEmpty;
  int get criticalAlerts => alerts.where((a) => a.severity == AlertSeverity.high).length;
}

/// School statistics
class SchoolStatistics {
  final String schoolId;
  final String schoolName;
  final int totalStudents;
  final int totalClasses;
  final int todayPresent;
  final int todayAbsent;
  final double attendanceRate;
  
  const SchoolStatistics({
    required this.schoolId,
    required this.schoolName,
    required this.totalStudents,
    required this.totalClasses,
    required this.todayPresent,
    required this.todayAbsent,
    required this.attendanceRate,
  });
  
  factory SchoolStatistics.empty(String schoolId, String schoolName) => 
      SchoolStatistics(
        schoolId: schoolId,
        schoolName: schoolName,
        totalStudents: 0,
        totalClasses: 0,
        todayPresent: 0,
        todayAbsent: 0,
        attendanceRate: 0.0,
      );
}

/// Class statistics
class ClassStatistics {
  final String classId;
  final String className;
  final int totalStudents;
  final int todayPresent;
  final int todayAbsent;
  final double attendanceRate;
  final int lowAttendanceStudents;
  final double averageAttendanceRate;
  
  const ClassStatistics({
    required this.classId,
    required this.className,
    required this.totalStudents,
    required this.todayPresent,
    required this.todayAbsent,
    required this.attendanceRate,
    required this.lowAttendanceStudents,
    required this.averageAttendanceRate,
  });
  
  factory ClassStatistics.empty(String classId, String className) => 
      ClassStatistics(
        classId: classId,
        className: className,
        totalStudents: 0,
        todayPresent: 0,
        todayAbsent: 0,
        attendanceRate: 0.0,
        lowAttendanceStudents: 0,
        averageAttendanceRate: 0.0,
      );
}

/// Recent activity item
class RecentActivity {
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String icon;
  
  const RecentActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
  });
}

/// Trend data point
class TrendData {
  final DateTime date;
  final double value;
  final String label;
  
  const TrendData({
    required this.date,
    required this.value,
    required this.label,
  });
}

/// Dashboard alert
class DashboardAlert {
  final AlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  
  const DashboardAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}

/// Activity types
enum ActivityType {
  attendance,
  student,
  classData,
  sync,
  device,
}

/// Alert types
enum AlertType {
  lowAttendance,
  studentAtRisk,
  syncIssue,
  deviceOffline,
  systemError,
}

/// Alert severity
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}