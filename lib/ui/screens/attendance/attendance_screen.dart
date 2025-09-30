import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/simple_attendance_service.dart';
import '../../../core/enums/attendance_enums.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _rfidController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  
  String _selectedClassId = '';
  String _selectedClassName = 'Select Class';
  AttendanceStatus _selectedStatus = AttendanceStatus.present;
  
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _todayAttendance = [];
  List<Map<String, dynamic>> _classStudents = [];
  
  bool _isLoading = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    await AttendanceService.initialize();
    await _loadClasses();
    await _addSampleDataIfNeeded();
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _loadClasses() async {
    final classes = await AttendanceService.getAllClasses();
    setState(() {
      _classes = classes;
      if (_classes.isNotEmpty && _selectedClassId.isEmpty) {
        _selectedClassId = _classes.first['id'];
        _selectedClassName = _classes.first['name'];
        _loadTodayAttendance();
        _loadClassStudents();
      }
    });
  }
  
  Future<void> _loadTodayAttendance() async {
    if (_selectedClassId.isEmpty) return;
    
    final attendance = await AttendanceService.getTodayAttendance(_selectedClassId);
    setState(() => _todayAttendance = attendance);
  }
  
  Future<void> _loadClassStudents() async {
    if (_selectedClassId.isEmpty) return;
    
    final students = await AttendanceService.getStudentsByClass(_selectedClassId);
    setState(() => _classStudents = students);
  }
  
  Future<void> _addSampleDataIfNeeded() async {
    // No sample data will be added - everything will be created by staff through the app
    await _loadClasses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Attendance System'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildClassSelector(),
                _buildTabBar(),
                Expanded(child: _buildTabContent()),
              ],
            ),
    );
  }
  
  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Class: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedClassId.isEmpty ? null : _selectedClassId,
              hint: Text(_selectedClassName),
              isExpanded: true,
              items: _classes.map((classData) {
                return DropdownMenuItem<String>(
                  value: classData['id'],
                  child: Text(classData['name']),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  final selectedClass = _classes.firstWhere((c) => c['id'] == newValue);
                  setState(() {
                    _selectedClassId = newValue;
                    _selectedClassName = selectedClass['name'];
                  });
                  _loadTodayAttendance();
                  _loadClassStudents();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      color: Colors.blue,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Mark Attendance', 0),
          ),
          Expanded(
            child: _buildTabButton('Today\'s Attendance', 1),
          ),
          Expanded(
            child: _buildTabButton('Students', 2),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: isSelected ? const BorderRadius.vertical(top: Radius.circular(8)) : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMarkAttendanceTab();
      case 1:
        return _buildTodayAttendanceTab();
      case 2:
        return _buildStudentsTab();
      default:
        return const SizedBox();
    }
  }
  
  Widget _buildMarkAttendanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mark Attendance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // RFID Input
                  TextField(
                    controller: _rfidController,
                    decoration: const InputDecoration(
                      labelText: 'RFID Tag / Student ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    onSubmitted: _markAttendanceByRfid,
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('OR', textAlign: TextAlign.center),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Manual Entry
                  TextField(
                    controller: _studentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _rollNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Roll Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status Selection
                  Row(
                    children: [
                      const Text('Status: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<AttendanceStatus>(
                          value: _selectedStatus,
                          isExpanded: true,
                          items: AttendanceStatus.values.map((status) {
                            return DropdownMenuItem<AttendanceStatus>(
                              value: status,
                              child: Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(status),
                                    color: _getStatusColor(status),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(status.displayName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (AttendanceStatus? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedStatus = newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: _markManualAttendance,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodayAttendanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Present',
                    _todayAttendance.where((a) => a['status'] == 'present').length.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildStatCard(
                    'Absent',
                    _todayAttendance.where((a) => a['status'] == 'absent').length.toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                  _buildStatCard(
                    'Late',
                    _todayAttendance.where((a) => a['status'] == 'late').length.toString(),
                    Colors.orange,
                    Icons.access_time,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: _todayAttendance.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No attendance marked for today',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _todayAttendance.length,
                    itemBuilder: (context, index) {
                      final attendance = _todayAttendance[index];
                      final status = AttendanceStatus.values.firstWhere(
                        (s) => s.name == attendance['status'],
                        orElse: () => AttendanceStatus.present,
                      );
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status),
                            child: Icon(
                              _getStatusIcon(status),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(attendance['studentName']),
                          subtitle: Text(
                            'Time: ${_formatTime(attendance['timestamp'])}\n'
                            'Status: ${status.displayName}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editAttendance(attendance);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Students in $_selectedClassName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddStudentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Student'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: _classStudents.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No students in this class',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _classStudents.length,
                    itemBuilder: (context, index) {
                      final student = _classStudents[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              student['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(student['name']),
                          subtitle: Text(
                            'Roll: ${student['rollNumber']}\n'
                            'RFID: ${student['rfidTag'] ?? 'Not assigned'}',
                          ),
                          trailing: Text(
                            'P: ${student['totalPresent'] ?? 0} | '
                            'A: ${student['totalAbsent'] ?? 0} | '
                            'L: ${student['totalLate'] ?? 0}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.excused:
        return Icons.info;
    }
  }
  
  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
    }
  }
  
  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:'
             '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  Future<void> _markAttendanceByRfid(String rfidTag) async {
    if (rfidTag.isEmpty || _selectedClassId.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Try to find student by RFID
      final student = await AttendanceService.findStudentByRfid(rfidTag);
      
      if (student != null) {
        final result = await AttendanceService.markAttendance(
          studentId: student['id'],
          studentName: student['name'],
          classId: _selectedClassId,
          className: _selectedClassName,
          status: _selectedStatus,
          rfidTag: rfidTag,
        );
        
        _showResultMessage(result);
        
        if (result.success) {
          _rfidController.clear();
          await _loadTodayAttendance();
        }
      } else {
        _showErrorMessage('Student not found for RFID: $rfidTag');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _markManualAttendance() async {
    final studentName = _studentNameController.text.trim();
    final rollNumber = _rollNumberController.text.trim();
    
    if (studentName.isEmpty || rollNumber.isEmpty || _selectedClassId.isEmpty) {
      _showErrorMessage('Please fill in all fields');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final studentId = 'student_${const Uuid().v4()}';
      
      // Add student if they don't exist
      await AttendanceService.addStudent(
        id: studentId,
        name: studentName,
        rollNumber: rollNumber,
        classId: _selectedClassId,
      );
      
      final result = await AttendanceService.markAttendance(
        studentId: studentId,
        studentName: studentName,
        classId: _selectedClassId,
        className: _selectedClassName,
        status: _selectedStatus,
      );
      
      _showResultMessage(result);
      
      if (result.success) {
        _studentNameController.clear();
        _rollNumberController.clear();
        await _loadTodayAttendance();
        await _loadClassStudents();
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showResultMessage(AttendanceResult result) {
    final color = result.success ? Colors.green : 
                  result.isDuplicate ? Colors.orange : Colors.red;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  Future<void> _refreshData() async {
    await _loadTodayAttendance();
    await _loadClassStudents();
    _showResultMessage(AttendanceResult.success({'message': 'Data refreshed'}));
  }
  
  Future<void> _editAttendance(Map<String, dynamic> attendance) async {
    final newStatus = await showDialog<AttendanceStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Attendance for ${attendance['studentName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AttendanceStatus.values.map((status) {
            return ListTile(
              leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
              title: Text(status.displayName),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );
    
    if (newStatus != null) {
      final timestamp = DateTime.parse(attendance['timestamp']);
      final success = await AttendanceService.updateAttendance(
        studentId: attendance['studentId'],
        classId: attendance['classId'],
        date: timestamp,
        newStatus: newStatus,
      );
      
      if (success) {
        _showResultMessage(AttendanceResult.success({'message': 'Attendance updated'}));
        await _loadTodayAttendance();
      } else {
        _showErrorMessage('Failed to update attendance');
      }
    }
  }
  
  Future<void> _showAddStudentDialog() async {
    final nameController = TextEditingController();
    final rollController = TextEditingController();
    final rfidController = TextEditingController();
    final emailController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rollController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rfidController,
                decoration: const InputDecoration(
                  labelText: 'RFID Tag (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final roll = rollController.text.trim();
              
              if (name.isNotEmpty && roll.isNotEmpty) {
                final studentId = 'student_${const Uuid().v4()}';
                
                final success = await AttendanceService.addStudent(
                  id: studentId,
                  name: name,
                  rollNumber: roll,
                  classId: _selectedClassId,
                  rfidTag: rfidController.text.trim().isEmpty ? null : rfidController.text.trim(),
                  email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                );
                
                Navigator.pop(context);
                
                if (success) {
                  _showResultMessage(AttendanceResult.success({'message': 'Student added successfully'}));
                  await _loadClassStudents();
                } else {
                  _showErrorMessage('Failed to add student');
                }
              } else {
                _showErrorMessage('Please fill in required fields');
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }
}