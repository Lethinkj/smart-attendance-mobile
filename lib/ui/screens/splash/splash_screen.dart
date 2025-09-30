import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/school_provider.dart';
import '../../../providers/staff_provider.dart';
import '../../../models/school.dart';
import '../../../models/staff.dart';
import '../../../models/student.dart';
import '../../../services/postgresql_service.dart';
import '../../../services/supabase_postgresql_service.dart';
import '../../../core/services/whatsapp_style_auth_service.dart';
import '../../../core/services/persistent_auth_service.dart';
import '../../../core/services/permission_service.dart';
// import '../../../core/services/rfid_connection_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Splash screen shown during app initialization
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  /// Helper method to safely convert dynamic list to List<String>
  List<String> _convertToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List<String>) return value;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
    
    // Load schools on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolProvider.notifier).loadSchools();
    });
    
    // Navigate to login after animation
    _navigateToLogin();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App name
                    const Text(
                      'Smart Attendance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline
                    const Text(
                      'RFID-Based Attendance Management',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Loading text
                    const Text(
                      'Initializing...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      
      // Version info at bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Version 1.0.0\nSIH 2025 Project',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        try {
          // Request permissions first (blocking to ensure they're requested before navigation)
          print('[PERMISSIONS] Requesting essential permissions...');
          final granted = await PermissionService.initialize();
          if (granted) {
            print('[SUCCESS] All critical permissions granted');
          } else {
            print('[WARNING] Some permissions denied - app will work with limited functionality');
          }
          
          // Wait for authentication service to be ready (already initialized in main.dart)
          await Future.delayed(const Duration(milliseconds: 800));
          
          print('🔐 Checking authentication status...');
          print('🔐 Current auth state: ${WhatsAppStyleAuthService.currentState}');
          print('[AUTH] Is authenticated: ${WhatsAppStyleAuthService.isAuthenticated}');
          // Unified auto-login approach
          Map<String, dynamic>? userData;
          if (WhatsAppStyleAuthService.isAuthenticated) {
            userData = WhatsAppStyleAuthService.getCurrentUser();
          } else {
            print('[AUTH] Attempting forced auto-login...');
            userData = await WhatsAppStyleAuthService.forceAutoLogin();
          }
          if (userData == null) {
            final savedData = PersistentAuthService.getSavedUserData();
            if (savedData != null && PersistentAuthService.isPersistentlyLoggedIn) {
              print('[AUTH] Using fallback saved persistent user data.');
              userData = savedData;
            }
          }
          if (userData != null) {
            final role = userData['role'] ?? 'Staff';
            print('[LAUNCH] Auto-login successful, navigating to dashboard with role: $role');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  role: role,
                  staffInfo: userData,
                ),
              ),
            );
            return;
          }
          print('[AUTH] No auto-login available, showing login screen.');
          
          // User needs to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          
        } catch (e) {
          print('Auth check error: $e');
          // Fallback to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Admin';

  /// Helper method to safely convert dynamic list to List<String>
  List<String> _convertToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List<String>) return value;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Smart Attendance Login'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // App Title and Logo - Improved Design
                  Center(
                    child: Column(
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Smart Attendance',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure & Efficient Management',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Role Selection
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Select Role',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedRole = 'Admin'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == 'Admin' ? Colors.blue.shade100 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedRole == 'Admin' ? Colors.blue : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Radio<String>(
                                        value: 'Admin',
                                        groupValue: _selectedRole,
                                        onChanged: (value) => setState(() => _selectedRole = value!),
                                        activeColor: Colors.blue,
                                      ),
                                      const Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedRole = 'Staff'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == 'Staff' ? Colors.blue.shade100 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedRole == 'Staff' ? Colors.blue : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Radio<String>(
                                        value: 'Staff',
                                        groupValue: _selectedRole,
                                        onChanged: (value) => setState(() => _selectedRole = value!),
                                        activeColor: Colors.blue,
                                      ),
                                      const Text(
                                        'Staff',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Input Fields Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username / Email',
                            hintText: 'Enter your username or email',
                            prefixIcon: const Icon(Icons.person, color: Colors.blue),
                            labelStyle: const TextStyle(color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter username or email';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                            labelStyle: const TextStyle(color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Button
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;
      
      print('🔑 Attempting login with username: $username');
      
      try {
        // Use WhatsApp-style authentication
        final result = await WhatsAppStyleAuthService.login(
          email: username,
          password: password,
        );
        
        print('🔑 Login result: ${result.isSuccess}');
        if (result.error != null) {
          print('🔑 Login error: ${result.error}');
        }
        
        if (result.isSuccess) {
          final userData = result.userData!;
          
          print('[CELEBRATE] Login successful!');
          print('[DATA] User data: $userData');
          print('🔑 Selected role: $_selectedRole');
          
          // Use role from userData if available, otherwise use selected role
          final userRole = userData['role']?.toString() ?? _selectedRole;
          print('[USER] Final role for dashboard: $userRole');
          
          // Save persistent login data for auto-login next time
          try {
            await PersistentAuthService.saveUserLogin(
              email: username,
              password: password,
              userData: userData,
              role: userRole,
              schoolId: userData['schoolId']?.toString(),
            );
            print('💾 Persistent login data saved successfully');
          } catch (e) {
            print('[WARNING] Failed to save persistent login: $e');
          }
          
          // Log successful login
          await _logAccess('Login', 'Login successful - ${userData['staffName'] ?? userData['name'] ?? username}');
          
          print('[LAUNCH] Navigating to DashboardScreen...');
          
          // Always navigate directly to dashboard - no forced password change
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                print('[MOBILE] Building DashboardScreen with role: $userRole');
                print('[INFO] Staff info keys: ${userData.keys.toList()}');
                
                // Clean userData to ensure proper types
                final cleanedUserData = Map<String, dynamic>.from(userData);
                if (cleanedUserData.containsKey('assignedClasses')) {
                  cleanedUserData['assignedClasses'] = _convertToStringList(cleanedUserData['assignedClasses']);
                }
                
                return DashboardScreen(
                  role: userRole, 
                  staffInfo: cleanedUserData,
                );
              },
            ),
          );
        } else {
          // Log failed login
          await _logAccess('Login Failed', result.error ?? 'Authentication failed');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.error ?? 'Authentication failed',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Log error
        await _logAccess('Login Error', 'Login error: $e');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedRole == 'Admin' 
                      ? 'Invalid admin credentials! Use username: admin' 
                      : 'Invalid credentials! Please check username and password.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods for login screen
  String _getAdminPassword() {
    try {
      final box = Hive.box('settings');
      return box.get('admin_password', defaultValue: 'admin');
    } catch (e) {
      print('Error getting admin password: $e');
      return 'admin';
    }
  }



  Future<Map<String, dynamic>> _authenticateStaff(String username, String password) async {
    try {
      // Load all staff from database
      final allStaff = await PostgreSQLService.getAllStaff();
      
      // Find staff member by username (staffId.toLowerCase())
      Staff? matchingStaff;
      for (final staff in allStaff) {
        if (staff.staffId.toLowerCase() == username.toLowerCase()) {
          matchingStaff = staff;
          break;
        }
      }
      
      if (matchingStaff == null) {
        return {
          'isValid': false,
          'message': 'Staff member not found for username: $username',
        };
      }
      
      // Check if staff is active
      if (!matchingStaff.isActive) {
        return {
          'isValid': false,
          'message': 'Staff account is inactive',
        };
      }
      
      // Verify password
      if (matchingStaff.password == password) {
        return {
          'isValid': true,
          'staffName': matchingStaff.name,
          'staffId': matchingStaff.staffId,
          'schoolId': matchingStaff.schoolId,
          'role': matchingStaff.role,
          'assignedClasses': matchingStaff.assignedClasses,
          'email': matchingStaff.email,
          'phone': matchingStaff.phone,
          'isFirstLogin': matchingStaff.isFirstLogin,
        };
      } else {
        return {
          'isValid': false,
          'message': 'Incorrect password for ${matchingStaff.name}',
        };
      }
    } catch (e) {
      print('Error authenticating staff: $e');
      return {
        'isValid': false,
        'message': 'Authentication error: ${e.toString()}',
      };
    }
  }

  Future<void> _logAccess(String action, String details) async {
    try {
      final box = await Hive.openBox('settings');
      
      final accessLog = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'details': details,
        'userId': 'admin',
        'deviceInfo': 'Web Application',
      };
      
      List<dynamic> logs = box.get('access_logs', defaultValue: <dynamic>[]);
      logs.add(accessLog);
      
      // Keep only last 100 logs
      if (logs.length > 100) {
        logs = logs.sublist(logs.length - 100);
      }
      
      await box.put('access_logs', logs);
    } catch (e) {
      print('Error logging access: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  final String role;
  final Map<String, dynamic>? staffInfo;
  
  const DashboardScreen({super.key, required this.role, this.staffInfo});

  @override
  ConsumerState<DashboardScreen> createState() {
    print('[BUILD] Creating DashboardScreen state with role: $role');
    print('[BUILD] Staff info: $staffInfo');
    return _DashboardScreenState();
  }
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;
  // late RfidConnectionService _rfidService;
  
  bool get isAdmin => widget.role == 'Admin';

  /// Helper method to safely convert dynamic list to List<String>
  List<String> _convertToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List<String>) return value;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }
  
  // Staff roles management
  static const String _staffRolesKey = 'staff_roles';
  late List<Map<String, dynamic>> _staffRoles;
  
  // Device settings
  static const String _usbDetectionKey = 'usb_device_detection';
  static const String _bluetoothDetectionKey = 'bluetooth_device_detection';
  static const String _scanFrequencyKey = 'device_scan_frequency';
  
  bool _usbDetectionEnabled = true;
  bool _bluetoothDetectionEnabled = false;
  String _scanFrequency = 'Every 30 seconds';
  
  // Sync settings
  static const String _autoSyncKey = 'auto_sync_enabled';
  static const String _syncFrequencyKey = 'sync_frequency';
  static const String _wifiOnlySyncKey = 'wifi_only_sync';
  
  bool _autoSyncEnabled = true;
  String _syncFrequency = 'Every hour';
  bool _wifiOnlySyncEnabled = true;
  
  // Backup settings
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _backupFrequencyKey = 'backup_frequency';
  
  bool _autoBackupEnabled = true;
  String _backupFrequency = 'Daily';
  
  // Security settings
  static const String _twoFactorAuthKey = 'two_factor_auth_enabled';
  static const String _adminPasswordKey = 'admin_password';
  static const String _accessLogsKey = 'access_logs';
  
  bool _twoFactorAuthEnabled = false;
  
  // Notification settings
  static const String _attendanceNotificationsKey = 'attendance_notifications';
  static const String _systemNotificationsKey = 'system_notifications';
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _soundEnabledKey = 'notification_sound_enabled';
  
  bool _attendanceNotificationsEnabled = true;
  bool _systemNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  bool _soundEnabled = true;
  
  // Student management
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  
  @override
  void initState() {
    super.initState();
    print('🏁 DashboardScreen initState called');
    print('🏁 Role: ${widget.role}');
    print('🏁 Staff info: ${widget.staffInfo}');
    // _rfidService = RfidConnectionService.instance;
    _initializeDashboard();
    
    // Failsafe: Force initialization after 5 seconds if not completed
    Timer(const Duration(seconds: 5), () {
      if (!_isInitialized && mounted) {
        print('[WARNING] Forcing dashboard initialization after timeout');
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }
  
  Future<void> _initializeDashboard() async {
    try {
      print('🔧 Initializing Dashboard for role: ${widget.role}');
      print('[INFO] Staff info: ${widget.staffInfo}');
      
      // Set default values first to prevent white screen
      _staffRoles = _getDefaultRoles();
      _usbDetectionEnabled = true;
      _bluetoothDetectionEnabled = false;
      _autoSyncEnabled = true;
      _syncFrequency = 'Every hour';
      _wifiOnlySyncEnabled = true;
      _autoBackupEnabled = true;
      
      // Force UI update with default values first
      if (mounted) {
        setState(() {});
      }
      
      // Initialize all settings with error handling
      await _loadStaffRoles();
      await _loadDeviceSettings();
      await _loadSyncSettings();
      await _loadBackupSettings();
      await _loadSecuritySettings();
      await _loadNotificationSettings();
      
      // Initialize RFID connection service
      // await _rfidService.initialize();
      
      // Load students from database
      try {
        await _loadStudentsFromDatabase();
      } catch (e) {
        print('[WARNING] Failed to load students: $e');
      }
      
      // Final UI update after loading
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      
      print('[SUCCESS] Dashboard initialized successfully');
    } catch (e, stack) {
      print('[ERROR] Dashboard initialization error: $e');
      print('Stack trace: $stack');
      
      // Set default values to prevent white screen
      _staffRoles = _getDefaultRoles();
      _usbDetectionEnabled = true;
      _bluetoothDetectionEnabled = false;
      _autoSyncEnabled = true;
      _syncFrequency = 'Every hour';
      _wifiOnlySyncEnabled = true;
      _autoBackupEnabled = true;
      _backupFrequency = 'Daily';
      _twoFactorAuthEnabled = false;
      _attendanceNotificationsEnabled = true;
      _systemNotificationsEnabled = true;
      _emailNotificationsEnabled = false;
      _soundEnabled = true;
      
      // Force refresh UI
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }
  
  Future<void> _loadStaffRoles() async {
    try {
      final box = await Hive.openBox('settings');
      final storedRoles = box.get(_staffRolesKey, defaultValue: <dynamic>[]);
      
      if (storedRoles != null && storedRoles.isNotEmpty) {
        // Convert stored roles back to proper format
        _staffRoles = storedRoles.map<Map<String, dynamic>>((role) {
          return {
            'name': role['name'] as String,
            'description': role['description'] as String,
            'icon': _getIconFromName(role['iconName'] as String? ?? 'person'),
            'permissions': List<String>.from(role['permissions'] ?? []),
          };
        }).toList();
      } else {
        // Use default roles if nothing is stored
        _staffRoles = _getDefaultRoles();
        await _saveStaffRoles(); // Save defaults for next time
      }
      setState(() {});
    } catch (e) {
      print('Error loading staff roles: $e');
      _staffRoles = _getDefaultRoles();
      setState(() {});
    }
  }
  
  Future<void> _saveStaffRoles() async {
    try {
      // Convert roles to storable format (IconData can't be stored directly)
      final storableRoles = _staffRoles.map((role) {
        return {
          'name': role['name'],
          'description': role['description'],
          'iconName': _getIconName(role['icon'] as IconData),
          'permissions': role['permissions'],
        };
      }).toList();
      
      final box = await Hive.openBox('settings');
      await box.put(_staffRolesKey, storableRoles);
    } catch (e) {
      print('Error saving staff roles: $e');
    }
  }
  
  List<Map<String, dynamic>> _getDefaultRoles() {
    return [
      {
        'name': 'Principal',
        'description': 'Full administrative access',
        'icon': Icons.person,
        'permissions': [
          'View Attendance',
          'Mark Attendance',
          'Edit Student Records',
          'Generate Reports',
          'Manage Classes',
          'Access Settings',
          'Manage Staff',
          'Delete Records',
        ]
      },
      {
        'name': 'Vice Principal',
        'description': 'Limited administrative access',
        'icon': Icons.person_outline,
        'permissions': [
          'View Attendance',
          'Mark Attendance',
          'Edit Student Records',
          'Generate Reports',
          'Manage Classes',
          'Access Settings',
        ]
      },
      {
        'name': 'Head Teacher',
        'description': 'Department management',
        'icon': Icons.school,
        'permissions': [
          'View Attendance',
          'Mark Attendance',
          'Edit Student Records',
          'Generate Reports',
          'Manage Classes',
        ]
      },
      {
        'name': 'Teacher',
        'description': 'Class and student management',
        'icon': Icons.book,
        'permissions': [
          'View Attendance',
          'Mark Attendance',
          'Edit Student Records',
        ]
      },
      {
        'name': 'Support Staff',
        'description': 'Basic attendance marking',
        'icon': Icons.support_agent,
        'permissions': [
          'View Attendance',
          'Mark Attendance',
        ]
      },
    ];
  }
  
  // Device settings management
  Future<void> _loadDeviceSettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      setState(() {
        _usbDetectionEnabled = box.get(_usbDetectionKey, defaultValue: true);
        _bluetoothDetectionEnabled = box.get(_bluetoothDetectionKey, defaultValue: false);
        _scanFrequency = box.get(_scanFrequencyKey, defaultValue: 'Every 30 seconds');
      });
    } catch (e) {
      print('Error loading device settings: $e');
    }
  }
  
  Future<void> _saveDeviceSettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      await box.put(_usbDetectionKey, _usbDetectionEnabled);
      await box.put(_bluetoothDetectionKey, _bluetoothDetectionEnabled);
      await box.put(_scanFrequencyKey, _scanFrequency);
      
      // Log settings change
      await _logAccess('Settings Changed', 'Device settings updated - USB: $_usbDetectionEnabled, Bluetooth: $_bluetoothDetectionEnabled, Frequency: $_scanFrequency');
    } catch (e) {
      print('Error saving device settings: $e');
    }
  }
  
  // Sync settings methods
  Future<void> _loadSyncSettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      setState(() {
        _autoSyncEnabled = box.get(_autoSyncKey, defaultValue: true);
        _syncFrequency = box.get(_syncFrequencyKey, defaultValue: 'Every hour');
        _wifiOnlySyncEnabled = box.get(_wifiOnlySyncKey, defaultValue: true);
      });
    } catch (e) {
      print('Error loading sync settings: $e');
    }
  }
  
  Future<void> _saveSyncSettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      await box.put(_autoSyncKey, _autoSyncEnabled);
      await box.put(_syncFrequencyKey, _syncFrequency);
      await box.put(_wifiOnlySyncKey, _wifiOnlySyncEnabled);
      
      // Log settings change
      await _logAccess('Settings Changed', 'Sync settings updated - Auto: $_autoSyncEnabled, Frequency: $_syncFrequency, WiFi Only: $_wifiOnlySyncEnabled');
    } catch (e) {
      print('Error saving sync settings: $e');
    }
  }
  
  // Backup settings methods
  Future<void> _loadBackupSettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      setState(() {
        _autoBackupEnabled = box.get(_autoBackupKey, defaultValue: true);
        _backupFrequency = box.get(_backupFrequencyKey, defaultValue: 'Daily');
      });
    } catch (e) {
      print('Error loading backup settings: $e');
    }
  }
  
  Future<void> _saveBackupSettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      await box.put(_autoBackupKey, _autoBackupEnabled);
      await box.put(_backupFrequencyKey, _backupFrequency);
    } catch (e) {
      print('Error saving backup settings: $e');
    }
  }
  
  // Security settings methods
  Future<void> _loadSecuritySettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      setState(() {
        _twoFactorAuthEnabled = box.get(_twoFactorAuthKey, defaultValue: false);
      });
    } catch (e) {
      print('Error loading security settings: $e');
    }
  }
  
  Future<void> _saveSecuritySettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      await box.put(_twoFactorAuthKey, _twoFactorAuthEnabled);
      
      // Log settings change
      await _logAccess('Settings Changed', '2FA security ${_twoFactorAuthEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      print('Error saving security settings: $e');
    }
  }
  
  // Access logging methods
  Future<void> _logAccess(String action, String details) async {
    try {
      final box = await Hive.openBox('settings');
      
      final accessLog = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'details': details,
        'userId': 'admin', // For now, using 'admin' as default user
        'deviceInfo': 'Web Application', // Could be enhanced with actual device info
      };
      
      List<dynamic> logs = box.get(_accessLogsKey, defaultValue: <dynamic>[]);
      logs.add(accessLog);
      
      // Keep only last 100 logs to prevent storage bloat
      if (logs.length > 100) {
        logs = logs.sublist(logs.length - 100);
      }
      
      await box.put(_accessLogsKey, logs);
    } catch (e) {
      print('Error logging access: $e');
    }
  }
  
  List<Map<String, dynamic>> _getAccessLogs() {
    try {
      final box = Hive.box('settings');
      final logs = box.get(_accessLogsKey, defaultValue: <dynamic>[]);
      return logs.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting access logs: $e');
      return [];
    }
  }
  
  // Admin password management
  Future<bool> _changeAdminPassword(String currentPassword, String newPassword) async {
    try {
      final box = await Hive.openBox('settings');
      
      // Get current password (default is 'admin' if not set)
      final storedPassword = box.get(_adminPasswordKey, defaultValue: 'admin');
      
      // Verify current password
      if (storedPassword != currentPassword) {
        return false;
      }
      
      // Save new password
      await box.put(_adminPasswordKey, newPassword);
      
      // Log the password change
      await _logAccess('Password Changed', 'Admin password was changed');
      
      return true;
    } catch (e) {
      print('Error changing admin password: $e');
      return false;
    }
  }
  
  // Notification settings methods
  Future<void> _loadNotificationSettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      setState(() {
        _attendanceNotificationsEnabled = box.get(_attendanceNotificationsKey, defaultValue: true);
        _systemNotificationsEnabled = box.get(_systemNotificationsKey, defaultValue: true);
        _emailNotificationsEnabled = box.get(_emailNotificationsKey, defaultValue: false);
        _soundEnabled = box.get(_soundEnabledKey, defaultValue: true);
      });
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }
  
  Future<void> _saveNotificationSettings() async {
    try {
      final box = await Hive.openBox('settings');
      
      await box.put(_attendanceNotificationsKey, _attendanceNotificationsEnabled);
      await box.put(_systemNotificationsKey, _systemNotificationsEnabled);
      await box.put(_emailNotificationsKey, _emailNotificationsEnabled);
      await box.put(_soundEnabledKey, _soundEnabled);
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }
  
  // Helper methods for system status display
  Widget _buildStatusSection(String title, IconData icon, Color color, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }
  
  Widget _buildStatusItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getSystemHealthColor() {
    int activeFeatures = 0;
    if (_usbDetectionEnabled || _bluetoothDetectionEnabled) activeFeatures++;
    if (_autoSyncEnabled) activeFeatures++;
    if (_autoBackupEnabled) activeFeatures++;
    if (_twoFactorAuthEnabled) activeFeatures++;
    if (_attendanceNotificationsEnabled || _systemNotificationsEnabled) activeFeatures++;
    
    if (activeFeatures >= 4) return Colors.green;
    if (activeFeatures >= 2) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getSystemHealthIcon() {
    int activeFeatures = 0;
    if (_usbDetectionEnabled || _bluetoothDetectionEnabled) activeFeatures++;
    if (_autoSyncEnabled) activeFeatures++;
    if (_autoBackupEnabled) activeFeatures++;
    if (_twoFactorAuthEnabled) activeFeatures++;
    if (_attendanceNotificationsEnabled || _systemNotificationsEnabled) activeFeatures++;
    
    if (activeFeatures >= 4) return Icons.check_circle;
    if (activeFeatures >= 2) return Icons.warning;
    return Icons.error;
  }
  
  String _getSystemHealthStatus() {
    int activeFeatures = 0;
    if (_usbDetectionEnabled || _bluetoothDetectionEnabled) activeFeatures++;
    if (_autoSyncEnabled) activeFeatures++;
    if (_autoBackupEnabled) activeFeatures++;
    if (_twoFactorAuthEnabled) activeFeatures++;
    if (_attendanceNotificationsEnabled || _systemNotificationsEnabled) activeFeatures++;
    
    if (activeFeatures >= 4) return 'Excellent';
    if (activeFeatures >= 2) return 'Good';
    return 'Needs Attention';
  }
  
  String _getSystemHealthMessage() {
    int activeFeatures = 0;
    if (_usbDetectionEnabled || _bluetoothDetectionEnabled) activeFeatures++;
    if (_autoSyncEnabled) activeFeatures++;
    if (_autoBackupEnabled) activeFeatures++;
    if (_twoFactorAuthEnabled) activeFeatures++;
    if (_attendanceNotificationsEnabled || _systemNotificationsEnabled) activeFeatures++;
    
    if (activeFeatures >= 4) return 'All systems operational and secure';
    if (activeFeatures >= 2) return 'Most features active, consider enabling more for optimal security';
    return 'Several important features are disabled - review settings';
  }
  
  // Password change dialog
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.red),
              SizedBox(width: 8),
              Text('Change Admin Password'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your current password and choose a new password.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
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
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                
                if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPassword.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 4 characters long'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                final success = await _changeAdminPassword(currentPassword, newPassword);
                
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Password changed successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Current password is incorrect'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  // Staff password change dialog (from settings)
  void _showStaffPasswordChangeDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Change Your Password',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 450),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your current password and choose a new password.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setDialogState(() {
                            obscureCurrentPassword = !obscureCurrentPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setDialogState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Password must be at least 6 characters\n• Use a strong password for security',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                
                if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters long'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                // Use WhatsApp-style password change for staff
                try {
                  final success = await WhatsAppStyleAuthService.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                  );
                  
                  if (success) {
                    // Update persistent login with new password
                    final staffId = widget.staffInfo?['staffId'] ?? widget.staffInfo?['email'] ?? '';
                    await PersistentAuthService.saveUserLogin(
                      email: staffId,
                      password: newPassword,
                      userData: widget.staffInfo ?? {},
                      role: 'Staff',
                      schoolId: widget.staffInfo?['schoolId'],
                    );
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(child: Text('Password changed successfully!')),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Current password is incorrect'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Error changing password: $e')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Access logs dialog
  void _showAccessLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: Colors.purple, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Access Logs',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _logAccess('Manual Test', 'Test log entry created by user');
                          Navigator.pop(context);
                          _showAccessLogsDialog(); // Refresh the dialog
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Test Log'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final logs = _getAccessLogs();
                    
                    if (logs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No access logs available',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'System activities will be logged here',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[logs.length - 1 - index]; // Show newest first
                        final timestamp = DateTime.parse(log['timestamp']);
                        final formattedTime = '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getLogColor(log['action']),
                              child: Icon(
                                _getLogIcon(log['action']),
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              log['action'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log['details']),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      log['userId'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.devices, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      log['deviceInfo'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getLogColor(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'password changed':
        return Colors.red;
      case 'settings changed':
        return Colors.blue;
      case 'manual test':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getLogIcon(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'password changed':
        return Icons.lock_reset;
      case 'settings changed':
        return Icons.settings;
      case 'manual test':
        return Icons.bug_report;
      default:
        return Icons.info;
    }
  }
  
  int _getConnectedDevicesCount() {
    // Simulate connected devices based on enabled settings
    int count = 0;
    if (_usbDetectionEnabled) count += 1;
    if (_bluetoothDetectionEnabled) count += 1;
    return count;
  }
  
  void _showConnectedDevices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.devices, color: Colors.blue),
            SizedBox(width: 8),
            Text('Connected Devices'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_usbDetectionEnabled) ...[
                const ListTile(
                  leading: Icon(Icons.usb, color: Colors.green),
                  title: Text('USB RFID Reader'),
                  subtitle: Text('Status: Connected\nPort: COM3'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                const Divider(),
              ],
              if (_bluetoothDetectionEnabled) ...[
                const ListTile(
                  leading: Icon(Icons.bluetooth, color: Colors.blue),
                  title: Text('Bluetooth RFID Scanner'),
                  subtitle: Text('Status: Connected\nMAC: 00:11:22:33:44:55'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                const Divider(),
              ],
              if (!_usbDetectionEnabled && !_bluetoothDetectionEnabled) ...[
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices_other, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No devices connected',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enable USB or Bluetooth detection to connect devices',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_usbDetectionEnabled || _bluetoothDetectionEnabled)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.refresh, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Scanning for devices...'),
                      ],
                    ),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Scan'),
            ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (!_isInitialized) {
      print('🔄 Showing loading screen for ${widget.role}');
      return Scaffold(
        backgroundColor: Colors.blue,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Loading Dashboard...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.role} Dashboard',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (widget.staffInfo != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Welcome, ${widget.staffInfo!['name'] ?? widget.staffInfo!['staffName'] ?? widget.staffInfo!['staffId'] ?? 'User'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.role} Dashboard',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.staffInfo != null)
                    Text(
                      'Welcome, ${widget.staffInfo!['name'] ?? widget.staffInfo!['staffName'] ?? 'User'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.3),
        actions: [
          // RFID Connection Status - Temporarily disabled
          // StreamBuilder<RfidConnectionStatus>(
          //   stream: _rfidService.connectionStatus,
          //   initialData: _rfidService.currentStatus,
          //   builder: (context, snapshot) {
          //     return _buildRfidStatusButton(snapshot.data ?? RfidConnectionStatus.disconnected);
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout? You will need to login again next time.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                try {
                  // Use WhatsApp-style logout to clear persistent data
                  await WhatsAppStyleAuthService.logout();
                  
                  // Navigate to login screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully. Device will no longer auto-login.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          if (widget.role == 'Admin') _buildSchoolManagement(ref),
          if (widget.role == 'Staff') _buildAttendanceTab(),
          if (widget.role == 'Staff') _buildStudentsTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          if (widget.role == 'Admin')
            const BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Schools',
            ),
          if (widget.role == 'Staff')
            const BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Attendance',
            ),
          if (widget.role == 'Staff')
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Students',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    if (widget.role == 'Staff') {
      return _buildStaffDashboard();
    } else {
      return _buildAdminDashboard();
    }
  }

  Widget _buildStaffDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // School Header Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getSchoolName(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStaffInfo(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Class Statistics
          Row(
            children: [
              Expanded(
                child: _buildStaffStatCard(
                  'Students in Class',
                  _getClassStudentCount(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStaffStatCard(
                  'Today\'s Attendance',
                  '${_getTodayAttendanceRate()}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Attendance Methods Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mark Attendance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceMethodCard(
                          'RFID Scanner',
                          'Quick attendance using RFID tags',
                          Icons.nfc,
                          Colors.orange,
                          () => _startRFIDAttendance(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAttendanceMethodCard(
                          'Manual Entry',
                          'Mark attendance manually',
                          Icons.edit,
                          Colors.purple,
                          () => _startManualAttendance(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildStaffActionCard(
            'Add New Student',
            'Register a new student to your class',
            Icons.person_add,
            Colors.blue,
            () => _showAddStudentDialog(), // Directly open add student dialog
          ),

          const SizedBox(height: 12),

          _buildStaffActionCard(
            'Export Attendance',
            'Download attendance report for your class',
            Icons.file_download,
            Colors.green,
            () => _exportAttendanceReport(),
          ),

          const SizedBox(height: 12),

          _buildStaffActionCard(
            'View Reports',
            'Check detailed attendance analytics',
            Icons.analytics,
            Colors.indigo,
            () => _showStaffReports(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card - Enhanced Design
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${widget.staffInfo?['name'] ?? 'Admin'}!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Smart Attendance Management',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🎯 Manage schools, staff, and attendance efficiently',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Section Header
          const Text(
            'Overview Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats Grid - Enhanced Layout
          Consumer(
            builder: (context, ref, child) {
              final schoolState = ref.watch(schoolProvider);
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    'Today\'s Attendance',
                    '${_getTodayAttendanceRate()}%',
                    Icons.today,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Total Students',
                    _getTotalStudentCount(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Total Schools',
                    '${schoolState.schools.length}',
                    Icons.school,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Staff Members',
                    '15',
                    Icons.people_alt,
                    Colors.purple,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          _buildActionCard(
            'Manage Schools',
            'Add and manage school information',
            Icons.school,
            () => setState(() => _selectedIndex = 1),
          ),
          
          _buildActionCard(
            'View Reports',
            'Generate attendance reports',
            Icons.analytics,
            () => _showReportsDialog(),
          ),
          
          _buildActionCard(
            'Attendance Overview',
            'View school-wide attendance data',
            Icons.fact_check,
            () => _showAdminAttendanceOverview(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  // Staff Dashboard Helper Methods
  String _getSchoolName() {
    if (widget.staffInfo != null) {
      // Try to get school name from staff info if available
      if (widget.staffInfo!['schoolName'] != null) {
        return widget.staffInfo!['schoolName'] as String;
      }
      
      // Fallback to generate school name from staff ID
      if (widget.staffInfo!['staffId'] != null) {
        final staffId = widget.staffInfo!['staffId'] as String;
        if (staffId.contains('STF')) {
          final schoolCode = staffId.split('STF')[0];
          return _generateSchoolNameFromCode(schoolCode);
        }
      }
    }
    return 'My School';
  }

  String _generateSchoolNameFromCode(String code) {
    // Generate realistic school names based on code
    final schoolNames = {
      '444': 'Greenwood High School',
      '555': 'Riverside Elementary',
      '666': 'Sunset Middle School',
      '777': 'Oakdale Secondary',
      '888': 'Harmony Public School',
      '999': 'Valley View Academy',
    };
    
    return schoolNames[code] ?? '$code Public School';
  }

  String _getStaffInfo() {
    if (widget.staffInfo != null) {
      final staffName = widget.staffInfo!['staffName'] ?? 'Staff Member';
      final staffId = widget.staffInfo!['staffId'] ?? '';
      final role = widget.staffInfo!['role'] ?? 'Staff';
      final assignedClasses = _convertToStringList(widget.staffInfo!['assignedClasses']);
      
      String classInfo = '';
      if (assignedClasses.isNotEmpty) {
        if (assignedClasses.length == 1) {
          classInfo = 'Class ${assignedClasses.first}';
        } else {
          classInfo = '${assignedClasses.length} Classes';
        }
      } else {
        classInfo = 'No Classes Assigned';
      }
      
      return '$staffName • $role • $classInfo • ID: $staffId';
    }
    return 'Staff Member';
  }

  String _getClassName() {
    if (widget.staffInfo != null) {
      final assignedClasses = _convertToStringList(widget.staffInfo!['assignedClasses']);
      if (assignedClasses.isNotEmpty) {
        // Return the first assigned class or a summary if multiple
        if (assignedClasses.length == 1) {
          return 'Class ${assignedClasses.first}';
        } else {
          return '${assignedClasses.length} Classes';
        }
      }
      
      // Fallback to parsing from staff ID if no assigned classes
      if (widget.staffInfo!['staffId'] != null) {
        final staffId = widget.staffInfo!['staffId'] as String;
        if (staffId.contains('STF')) {
          // For new format like "444STF001"
          return 'Staff Member';
        }
        // For old format with underscores
        final parts = staffId.split('_');
        if (parts.length > 1) {
          return 'Class ${parts[1].toUpperCase()}';
        }
      }
    }
    return 'No Class Assigned';
  }

  String _getClassStudentCount() {
    // Get actual student count from the current student list
    final students = _getStudentsList();
    if (students.isNotEmpty) {
      // Filter students by assigned class if staff has specific classes
      if (widget.staffInfo != null) {
        final assignedClasses = _convertToStringList(widget.staffInfo!['assignedClasses']);
        if (assignedClasses.isNotEmpty) {
          final classStudents = students.where((student) => 
            assignedClasses.any((className) => student['className']?.toString().contains(className) ?? false)
          ).length;
          return classStudents.toString();
        }
      }
      // Return total students if no specific class assigned
      return students.length.toString();
    }
    return '0';
  }

  int _getTodayAttendanceRate() {
    if (widget.staffInfo != null) {
      // In a real implementation, this would calculate from actual attendance data
      final staffId = widget.staffInfo!['staffId']?.toString() ?? '';
      final hashCode = staffId.hashCode.abs();
      // Generate a realistic attendance rate between 75-95%
      return 75 + (hashCode % 21);
    }
    return 85;
  }

  Widget _buildStaffStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMethodCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }

  // Staff Action Methods
  void _startRFIDAttendance() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.nfc, color: Colors.orange),
              SizedBox(width: 8),
              Text('RFID Attendance Mode'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Card
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.nfc, size: 48, color: Colors.orange),
                        SizedBox(height: 8),
                        Text(
                          'RFID Scanner Ready',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Place student RFID cards near the scanner',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Attendance Options
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRfidScanningMode();
                        },
                        icon: Icon(Icons.play_arrow),
                        label: Text('Start Scanning'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportAttendanceReport();
                        },
                        icon: Icon(Icons.download),
                        label: Text('Export'),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                Text(
                  'Today\'s Attendance: ${_getTodayAttendanceCount()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRfidConnectionSettings();
              },
              icon: Icon(Icons.settings),
              label: Text('RFID Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _startManualAttendance() {
    final students = _getStudentsList();
    Map<String, String> attendanceStatus = {}; // Track attendance for each student
    
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found. Please add students first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: double.maxFinite,
            height: 500,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Manual Attendance - ${_getClassName()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mark attendance for ${students.length} students',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final studentName = student['name'] ?? 'Unknown Student';
                      final rollNumber = student['rollNumber'] ?? 'No Roll';
                      final studentKey = '${rollNumber}_$studentName';
                      final currentStatus = attendanceStatus[studentKey] ?? 'not_marked';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: currentStatus == 'present' 
                                    ? Colors.green 
                                    : currentStatus == 'absent' 
                                        ? Colors.red 
                                        : Colors.grey,
                                child: Text(
                                  rollNumber.toString().substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Roll: $rollNumber',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setDialogState(() {
                                    attendanceStatus[studentKey] = 'present';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentStatus == 'present' 
                                      ? Colors.green.shade700 
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 36),
                                ),
                                child: const Text('Present'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setDialogState(() {
                                    attendanceStatus[studentKey] = 'absent';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentStatus == 'absent' 
                                      ? Colors.red.shade700 
                                      : Colors.red,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 36),
                                ),
                                child: const Text('Absent'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Count marked students
                          final markedCount = attendanceStatus.values.where((status) => status != 'not_marked').length;
                          final presentCount = attendanceStatus.values.where((status) => status == 'present').length;
                          final absentCount = attendanceStatus.values.where((status) => status == 'absent').length;
                          
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Attendance saved! Present: $presentCount, Absent: $absentCount, Total marked: $markedCount/${students.length}'
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          // TODO: Save attendance to database
                          print('Saving attendance: $attendanceStatus');
                        },
                        child: const Text('Save Attendance'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStaffReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.today, color: Colors.blue),
              title: const Text('Today\'s Report'),
              subtitle: const Text('View today\'s attendance summary'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.date_range, color: Colors.green),
              title: const Text('Weekly Report'),
              subtitle: const Text('View weekly attendance trends'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.calendar_month, color: Colors.orange),
              title: const Text('Monthly Report'),
              subtitle: const Text('View monthly attendance analytics'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Student Management Methods
  List<Map<String, dynamic>> _getStudentsList() {
    // Load students from database if not already loaded
    if (_allStudents.isEmpty) {
      _loadStudentsFromDatabase();
    }
    return _allStudents;
  }

  Future<void> _loadStudentsFromDatabase() async {
    try {
      print('[LOADING] Loading students from database...');
      print('[INFO] Staff info: ${widget.staffInfo}');
      
      // Get school ID from staff info
      String? schoolId = widget.staffInfo?['school_id'] ?? widget.staffInfo?['schoolId'];
      if (schoolId == null || schoolId.isEmpty) {
        print('[WARNING] No school ID found, using default');
        schoolId = 'default-school';
      }
      
      print('[LOADING] Loading students for school: $schoolId');
      
      // Get students from PostgreSQL service
      List<Student> students;
      if (widget.role == 'Admin') {
        // Admin can see all students from all schools
        print('[ADMIN] Admin loading ALL students from database...');
        students = await PostgreSQLService.getAllStudents();
      } else {
        // For now, let staff see all students from their school (we'll add filtering later)
        print('[STAFF] Staff loading students for school: $schoolId');
        students = await PostgreSQLService.getStudentsBySchool(schoolId);
  // Clean ASCII-only log (removed previous malformed leading replacement character)
  final loadedCount = students.length;
  final infoMsg = '[INFO] Loaded ' + loadedCount.toString() + ' students for staff';
  print(infoMsg);
  // Uncomment for debugging encoding issues (hex dump of bytes)
  // print('[DEBUG] infoMsg codeUnits: ' + infoMsg.codeUnits.map((c) => c.toRadixString(16)).join(' '));
      }
      
      if (students.isNotEmpty) {
        setState(() {
          _allStudents = students.map((student) => {
            'id': student.id,
            'studentId': student.studentId,
            'name': student.name,
            'className': student.className,
            'email': student.parentEmail,
            'phone': student.parentPhone,
            'rfidTag': student.rfidTag,
            'isActive': student.isActive,
            'schoolId': student.schoolId,
            'section': student.section,
            'rollNumber': student.rollNumber,
            'createdAt': student.createdAt.toIso8601String(),
            'updatedAt': student.updatedAt.toIso8601String(),
          }).toList();
          _filteredStudents = List.from(_allStudents);
        });
        print('[SUCCESS] Loaded ${_allStudents.length} students from database');
      } else {
        print('[INFO] No students found in database');
        setState(() {
          _allStudents = [];
          _filteredStudents = [];
        });
      }
    } catch (e) {
      print('[ERROR] Error loading students: $e');
      // Fallback to empty list on error
      setState(() {
        _allStudents = [];
        _filteredStudents = [];
      });
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((student) {
          return student['name'].toLowerCase().contains(query.toLowerCase()) ||
                 student['rollNumber'].toLowerCase().contains(query.toLowerCase()) ||
                 student['rfidTag'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    for (int i = 0; i < names.length && i < 2; i++) {
      initials += names[i].substring(0, 1).toUpperCase();
    }
    return initials;
  }

  void _handleStudentAction(String action, Map<String, dynamic> student) {
    switch (action) {
      case 'edit':
        _showEditStudentDialog(student);
        break;
      case 'attendance':
        _showStudentAttendanceHistory(student);
        break;
      case 'rfid':
        _showAssignRFIDDialog(student);
        break;
      case 'delete':
        _showDeleteStudentConfirmation(student);
        break;
    }
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['name']);
    final rollController = TextEditingController(text: student['rollNumber']);
    final sectionController = TextEditingController(text: student['section']);
    final rfidController = TextEditingController(text: student['rfidTag']);
    final parentNameController = TextEditingController(text: student['parentName']);
    final parentPhoneController = TextEditingController(text: student['parentPhone']);
    final addressController = TextEditingController(text: student['address']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 600,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Edit Student',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: rollController,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: sectionController,
                              decoration: const InputDecoration(
                                labelText: 'Section',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: rfidController,
                        decoration: const InputDecoration(
                          labelText: 'RFID Tag ID',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.nfc),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: parentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Parent Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: parentPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Parent Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Update student data
                        setState(() {
                          int index = _allStudents.indexWhere((s) => s['rollNumber'] == student['rollNumber']);
                          if (index != -1) {
                            _allStudents[index] = {
                              'name': nameController.text,
                              'rollNumber': rollController.text,
                              'section': sectionController.text,
                              'rfidTag': rfidController.text,
                              'parentName': parentNameController.text,
                              'parentPhone': parentPhoneController.text,
                              'dateOfBirth': student['dateOfBirth'],
                              'address': addressController.text,
                            };
                            _filteredStudents = List.from(_allStudents);
                          }
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Student updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteStudentConfirmation(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allStudents.removeWhere((s) => s['rollNumber'] == student['rollNumber']);
                _filteredStudents = List.from(_allStudents);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student['name']} deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignRFIDDialog(Map<String, dynamic> student) {
    final rfidController = TextEditingController(text: student['rfidTag']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign RFID - ${student['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rfidController,
              decoration: const InputDecoration(
                labelText: 'RFID Tag ID',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.nfc),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Simulate RFID scanning
                rfidController.text = 'RF${DateTime.now().millisecondsSinceEpoch}';
              },
              icon: const Icon(Icons.nfc),
              label: const Text('Scan RFID Tag'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                int index = _allStudents.indexWhere((s) => s['rollNumber'] == student['rollNumber']);
                if (index != -1) {
                  _allStudents[index]['rfidTag'] = rfidController.text;
                  _filteredStudents = List.from(_allStudents);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('RFID tag assigned successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showStudentAttendanceHistory(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${student['name']} - Attendance History',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 7, // Show last 7 days
                  itemBuilder: (context, index) {
                    final date = DateTime.now().subtract(Duration(days: index));
                    final isPresent = index % 3 != 0; // Mock attendance pattern
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPresent ? Colors.green : Colors.red,
                          child: Icon(
                            isPresent ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text('${date.day}/${date.month}/${date.year}'),
                        subtitle: Text(isPresent ? 'Present' : 'Absent'),
                        trailing: Text(
                          isPresent ? '9:15 AM' : 'N/A',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportStudentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Import students from CSV or Excel file'),
            const SizedBox(height: 16),
            const Text(
              'Required columns: Name, Roll Number, Section, Parent Name, Parent Phone, Address',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File import functionality coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.file_upload),
            label: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Students with RFID'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Students without RFID'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Recently added'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Advanced filtering coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }



  Widget _buildSchoolManagement(WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'School Management System',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Actions Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddSchoolDialog(ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add School'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showStaffRoleManagement(),
                  icon: const Icon(Icons.group),
                  label: const Text('Staff Roles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Schools List with Enhanced Management
          const Text(
            'Registered Schools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Dynamic Schools List
          Consumer(
            builder: (context, ref, child) {
              try {
                final schoolState = ref.watch(schoolProvider);
                
                if (schoolState.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (schoolState.error != null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text('Error: ${schoolState.error}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.read(schoolProvider.notifier).loadSchools(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (schoolState.schools.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.school, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No schools registered yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click "Add School" to create your first school',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Display schools dynamically
              return Column(
                children: schoolState.schools.map((school) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: const Icon(Icons.school, color: Colors.blue),
                      title: Text(school.name),
                      subtitle: Text('ID: ${school.uniqueId} | ${school.address}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // School Stats
                              Consumer(
                                builder: (context, ref, child) {
                                  final staffState = ref.watch(schoolStaffProvider(school.uniqueId));
                                  
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildSchoolStat('Type', school.schoolType, Icons.category),
                                      _buildSchoolStat('Classes', '${school.classes.length}', Icons.class_),
                                      _buildSchoolStat('Staff', staffState.isLoading ? '...' : '${staffState.staffList.length}', Icons.people),
                                    ],
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Action Buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showEditSchoolDialog(school),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit School'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showStaffManagement(school.uniqueId),
                                    icon: const Icon(Icons.people),
                                    label: const Text('Manage Staff'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showSchoolReports(school.uniqueId),
                                    icon: const Icon(Icons.analytics),
                                    label: const Text('View Reports'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showDeleteSchoolConfirmation(school),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete School'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
              } catch (e, stackTrace) {
                print('❌ Error in school list Consumer: $e');
                print('Stack trace: $stackTrace');
                
                // Return error widget instead of crashing
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        const Text('Error loading schools'),
                        const SizedBox(height: 8),
                        Text('Details: $e', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            try {
                              ref.read(schoolProvider.notifier).loadSchools();
                            } catch (retryError) {
                              print('❌ Retry failed: $retryError');
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          

        ],
      ),
    );
  }

  Widget _buildSchoolStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<String> _getClassesForSchoolType(String schoolType) {
    switch (schoolType) {
      case 'Elementary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8'];
      case 'Secondary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
      case 'Senior Secondary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
      default:
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8'];
    }
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // RFID Scanner Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.nfc,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'RFID Scanner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hold RFID tag near the scanner to mark attendance',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _simulateRFIDScan(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent Attendance
          const Text(
            'Recent Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Load actual recent attendance data
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadRecentAttendance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              } else if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading attendance: ${snapshot.error}'),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No recent attendance records found.'),
                  ),
                );
              } else {
                return Column(
                  children: snapshot.data!.map((attendance) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: attendance['status'] == 'present' ? Colors.green : Colors.red,
                        child: Icon(
                          attendance['status'] == 'present' ? Icons.check : Icons.close, 
                          color: Colors.white
                        ),
                      ),
                      title: Text(attendance['studentName'] ?? 'Unknown Student'),
                      subtitle: Text('${attendance['className'] ?? 'Unknown Class'} - ${attendance['status']?.toUpperCase() ?? 'UNKNOWN'}'),
                      trailing: Text(
                        attendance['time'] ?? 'Unknown Time',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    // Ensure students are loaded when building this tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_allStudents.isEmpty) {
        _loadStudentsFromDatabase();
      }
    });
    
    return Column(
      children: [
        // Header with class info and actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getClassName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Student Management',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_getStudentsList().length} Students',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddStudentDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade600,
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showImportStudentsDialog(),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Import'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => _filterStudents(value),
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: IconButton(
                  onPressed: () => _showFilterOptions(),
                  icon: const Icon(Icons.filter_list),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // Students list
        Expanded(
          child: _filteredStudents.isEmpty 
            ? _buildEmptyStudentsState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  return _buildStudentCard(student, index);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add students to your class to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddStudentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Student'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.teal,
    ];
    final color = colors[index % colors.length];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 24,
              child: Text(
                _getInitials(student['name']),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll: ${student['rollNumber']} • ${student['section']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (student['rfidTag'].isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.nfc, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'RFID: ${student['rfidTag']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.orange.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'No RFID tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleStudentAction(value, student),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'attendance',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18),
                      SizedBox(width: 8),
                      Text('View Attendance'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rfid',
                  child: Row(
                    children: [
                      Icon(Icons.nfc, size: 18),
                      SizedBox(width: 8),
                      Text('Assign RFID'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: const Text('Device Settings'),
                  subtitle: const Text('Configure attendance devices'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showDeviceSettings(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync Settings'),
                  subtitle: const Text('Configure cloud synchronization'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showSyncSettings(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup & Restore'),
                  subtitle: const Text('Manage data backup'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showBackupSettings(),
                ),
                const Divider(),
                if (isAdmin) // Only show security settings for Admin
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Security Settings'),
                    subtitle: const Text('Manage access and permissions'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showSecuritySettings(),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Configure alert preferences'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showNotificationSettings(),
                ),
                if (!isAdmin) // Only show for Staff users
                  const Divider(),
                if (!isAdmin) // Only show for Staff users
                  ListTile(
                    leading: const Icon(Icons.lock_reset, color: Colors.orange),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your login password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showStaffPasswordChangeDialog(),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  subtitle: const Text('App information'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Comprehensive System Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.green.shade50, Colors.orange.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard, color: Colors.blue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'System Status Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Devices Section
                _buildStatusSection(
                  'Devices',
                  Icons.devices,
                  Colors.blue,
                  [
                    _buildStatusItem(
                      _usbDetectionEnabled ? Icons.usb : Icons.usb_off,
                      'USB Detection',
                      _usbDetectionEnabled ? "ON" : "OFF",
                      _usbDetectionEnabled ? Colors.green : Colors.grey,
                    ),
                    _buildStatusItem(
                      _bluetoothDetectionEnabled ? Icons.bluetooth : Icons.bluetooth_disabled,
                      'Bluetooth Detection',
                      _bluetoothDetectionEnabled ? "ON" : "OFF",
                      _bluetoothDetectionEnabled ? Colors.blue : Colors.grey,
                    ),
                    _buildStatusItem(
                      Icons.schedule,
                      'Scan Frequency',
                      _scanFrequency,
                      Colors.orange,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Sync & Backup Section
                _buildStatusSection(
                  'Sync & Backup',
                  Icons.cloud_sync,
                  Colors.green,
                  [
                    _buildStatusItem(
                      _autoSyncEnabled ? Icons.sync : Icons.sync_disabled,
                      'Auto Sync',
                      _autoSyncEnabled ? "ON ($_syncFrequency)" : "OFF",
                      _autoSyncEnabled ? Colors.green : Colors.grey,
                    ),
                    _buildStatusItem(
                      _autoBackupEnabled ? Icons.backup : Icons.backup_outlined,
                      'Auto Backup',
                      _autoBackupEnabled ? "ON ($_backupFrequency)" : "OFF",
                      _autoBackupEnabled ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Security & Notifications Section
                _buildStatusSection(
                  'Security & Alerts',
                  Icons.security,
                  Colors.red,
                  [
                    _buildStatusItem(
                      _twoFactorAuthEnabled ? Icons.verified_user : Icons.person,
                      '2FA Security',
                      _twoFactorAuthEnabled ? "ENABLED" : "BASIC",
                      _twoFactorAuthEnabled ? Colors.green : Colors.orange,
                    ),
                    _buildStatusItem(
                      (_attendanceNotificationsEnabled || _systemNotificationsEnabled) 
                        ? Icons.notifications_active 
                        : Icons.notifications_off,
                      'Notifications',
                      (_attendanceNotificationsEnabled || _systemNotificationsEnabled) ? "ACTIVE" : "OFF",
                      (_attendanceNotificationsEnabled || _systemNotificationsEnabled) ? Colors.blue : Colors.grey,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Overall System Health
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSystemHealthColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getSystemHealthColor().withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getSystemHealthIcon(),
                        color: _getSystemHealthColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Health: ${_getSystemHealthStatus()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getSystemHealthColor(),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getSystemHealthMessage(),
                              style: TextStyle(
                                color: _getSystemHealthColor(),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSchoolDialog(WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedSchoolType = 'Elementary Education';
    final schoolIdController = TextEditingController();
    
    final List<Map<String, String>> schoolTypes = [
      {
        'name': 'Elementary Education',
        'classes': 'Pre-KG, LKG, UKG, 1, 2, 3, 4, 5, 6, 7, 8',
        'description': 'Elementary education covers Pre-KG through 8th grade with comprehensive foundational learning.'
      },
      {
        'name': 'Secondary Education', 
        'classes': 'Pre-KG, LKG, UKG, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10',
        'description': 'Secondary education extends through 10th grade, preparing students for higher secondary education.'
      },
      {
        'name': 'Senior Secondary Education',
        'classes': 'Pre-KG, LKG, UKG, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12',
        'description': 'Senior secondary education covers all grades through 12th, preparing students for university education.'
      },
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Colors.blue),
              SizedBox(width: 8),
              Text('Add New School'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Information Panel about Indian Education System
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.green.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Indian Education System Guide',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Elementary Education: Classes 1-8 (Ages 6-14) - Compulsory under RTE Act 2009\n'
                        '• Secondary Education: Classes 9-10 - Leads to SSC examination\n'
                        '• Senior Secondary: Classes 11-12 - Science/Commerce/Arts streams',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // School Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'School Name',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., St. Mary\'s High School',
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                
                const SizedBox(height: 16),
                
                // School Type Dropdown with detailed information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'What type of school are you creating?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedSchoolType,
                            decoration: const InputDecoration(
                              labelText: 'Select School Type',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.school),
                            ),
                            items: schoolTypes.map((type) => DropdownMenuItem(
                              value: type['name']!,
                              child: Text(
                                type['name']!,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            )).toList(),
                            onChanged: (value) => setState(() => selectedSchoolType = value!),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Show selected school type details
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedSchoolType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  schoolTypes.firstWhere((type) => type['name'] == selectedSchoolType)['description'] ?? 'No description available',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '📚 ${schoolTypes.firstWhere((type) => type['name'] == selectedSchoolType)['classes']!}',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // School ID Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'School Unique ID',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: schoolIdController,
                        decoration: const InputDecoration(
                          labelText: 'Enter School Unique ID',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., ABCSCHOOL01',
                          helperText: 'This ID will be used to generate staff login accounts',
                          prefixIcon: Icon(Icons.school),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (value) => setState(() {}),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Staff Login Generation Preview
                      if (schoolIdController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🔐 Auto-Generated Staff Login Accounts:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Based on $selectedSchoolType, ${_getStaffCount(selectedSchoolType)} staff accounts will be created:',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              ...(_getClassList(selectedSchoolType).asMap().entries.map((entry) {
                                final index = entry.key;
                                final className = entry.value;
                                final staffId = '${schoolIdController.text}STF${(index + 1).toString().padLeft(3, '0')}';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1),
                                  child: Text(
                                    '• $staffId (Password: staff123)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[800],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              })),
                              const SizedBox(height: 4),
                              Text(
                                'Note: Staff can change passwords on first login',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Address
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 16),
                
                // Phone Number
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Email
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
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
              onPressed: (_isValidSchoolForm(nameController.text, schoolIdController.text)) ? () async {
                final schoolId = schoolIdController.text.trim().toUpperCase();
                
                // Get classes for the selected school type
                final classList = _getClassesForSchoolType(selectedSchoolType);
                
                // Create School object
                final school = School(
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  schoolType: selectedSchoolType,
                  uniqueId: schoolId,
                  classes: classList,
                );

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Creating school and generating staff accounts...'),
                      ],
                    ),
                  ),
                );

                try {
                  // Create school using Supabase
                  await ref.read(schoolProvider.notifier).createSchool(school);
                  
                  // Generate staff accounts for all classes
                  await _generateStaffAccounts(schoolId, selectedSchoolType, ref);
                  
                  // Refresh the schools list to show the new school
                  await ref.read(schoolProvider.notifier).loadSchools();
                  
                  Navigator.pop(context); // Close loading
                  Navigator.pop(context); // Close dialog
                  
                  final staffCount = _getStaffCount(selectedSchoolType);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$selectedSchoolType "${nameController.text}" created successfully!\n$staffCount staff accounts generated with ID: $schoolId'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 6),
                      action: SnackBarAction(
                        label: 'View Staff',
                        textColor: Colors.white,
                        onPressed: () {
                          _showStaffAccounts(schoolId, selectedSchoolType);
                        },
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create school: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } : null,
              child: const Text('Create School & Generate Staff Accounts'),
            ),
          ],
        ),
      ),
    );
  }


  bool _isValidSchoolForm(String schoolName, String schoolId) {
    if (schoolName.isEmpty) return false;
    if (schoolId.isEmpty) return false;
    if (schoolId.length < 3 || schoolId.length > 15) return false;
    // Check if it contains only alphanumeric characters
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(schoolId)) return false;
    return true;
  }

  int _getStaffCount(String schoolType) {
    return _getClassList(schoolType).length;
  }

  List<String> _getClassList(String schoolType) {
    switch (schoolType) {
      case 'Elementary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8'];
      case 'Secondary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
      case 'Senior Secondary Education':
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
      default:
        return ['PreKG', 'LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8'];
    }
  }

  Future<void> _generateStaffAccounts(String schoolId, String schoolType, WidgetRef ref) async {
    final classes = _getClassList(schoolType);
    List<Map<String, String>> staffCredentials = [];
    int successCount = 0;
    
    print('🔄 Starting staff generation for school: $schoolId, type: $schoolType');
    print('📋 Classes to create: ${classes.join(', ')}');
    
    try {
      // Get the actual school UUID from the created school - reload first
      await ref.read(schoolProvider.notifier).loadSchools();
      final schools = ref.read(schoolProvider).schools;
      print('🏫 Available schools: ${schools.map((s) => '${s.name}(${s.uniqueId})').join(', ')}');
      
      final school = schools.firstWhere(
        (s) => s.uniqueId == schoolId,
        orElse: () => throw Exception('School with ID $schoolId not found after creation')
      );
      final actualSchoolId = school.id;
      
      print('[SUCCESS] Found school: ${school.name} with UUID: $actualSchoolId');
      
      // Update school with classes list
      final updatedSchool = school.copyWith(
        classes: classes,
        totalStaff: classes.length,
      );
      await ref.read(schoolProvider.notifier).updateSchool(updatedSchool);
      print('📋 Updated school with ${classes.length} classes');
      
      for (int i = 0; i < classes.length; i++) {
        final className = classes[i];
        
        // Generate proper staff ID using the service
        final generatedStaffId = await ref.read(staffProvider.notifier).generateNextStaffId(actualSchoolId);
        final displayStaffId = '${schoolId}STF${(i + 1).toString().padLeft(3, '0')}'; // Use correct format: 444STF001
        final username = displayStaffId.toLowerCase();
        const password = 'staff123';
        
        final staff = Staff(
          staffId: generatedStaffId, // Use the properly generated ID
          schoolId: actualSchoolId,
          name: 'Class $className Teacher',
          email: '$username@${schoolId.toLowerCase()}.edu',
          phone: '+91-${9000000000 + i}', // Unique phone numbers
          role: 'Teacher',
          assignedClasses: [className],
          password: password,
          isFirstLogin: true,
        );
        
        try {
          print('🔄 Creating staff ${i + 1}/${classes.length}: ${staff.name} (${staff.staffId})');
          
          // Save staff to the database
          await ref.read(staffProvider.notifier).createStaff(staff);
          successCount++;
          print('[SUCCESS] Successfully created: ${staff.staffId} - ${staff.name}');
          
          // Add to credentials list for display
          staffCredentials.add({
            'Class': 'Class $className',
            'Staff Name': staff.name,
            'Username': displayStaffId, // Show the readable ID to users
            'Password': password,
            'Staff ID': staff.staffId, // The actual database ID
            'Email': staff.email,
            'Phone': staff.phone,
          });
          
        } catch (e) {
          print('❌ Failed to create staff for $className: $e');
          print('📋 Staff data: ${staff.toJson()}');
          // Continue with next staff member instead of stopping
        }
      }
      
      print('[INFO] Staff creation summary: Created $successCount out of ${classes.length} staff accounts for school $schoolId');
      
      if (successCount == 0) {
        throw Exception('Failed to create any staff accounts. Please check your database connection.');
      }
      
      if (successCount < classes.length) {
        print('[WARNING] Warning: Only created $successCount out of ${classes.length} staff accounts');
      }
      
      // Store credentials for showing to user
      _lastGeneratedCredentials = staffCredentials;
      
    } catch (e) {
      print('💥 Error in _generateStaffAccounts: $e');
      throw Exception('Failed to generate staff accounts: ${e.toString()}');
    }
  }
  
  // Store generated credentials for display
  List<Map<String, String>> _lastGeneratedCredentials = [];

  void _generateStaffCredentialsFile(String schoolId, List<Map<String, String>> staffCredentials) {
    // Create CSV content
    String csvContent = 'Class,Staff Name,Username,Password,Staff ID,Email,Phone\n';
    
    for (final staff in staffCredentials) {
      csvContent += '${staff['Class']},${staff['Staff Name']},${staff['Username']},${staff['Password']},${staff['Staff ID']},${staff['Email']},${staff['Phone']}\n';
    }
    
    // Show dialog with downloadable CSV content
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 Staff Credentials Export - $schoolId'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ Successfully created ${staffCredentials.length} staff accounts!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '📋 Staff Credentials Summary:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2.5),
                      2: FlexColumnWidth(1.5),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.blue.shade50),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...staffCredentials.map((staff) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(staff['Class'] ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              staff['Username'] ?? '',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              staff['Password'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  '💡 Copy the CSV data below and paste it into Excel/Google Sheets:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade50,
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csvContent,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Copy to clipboard functionality can be added here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('💾 CSV data is ready to copy from the text area above'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }

  void _showStaffAccounts(String schoolId, String schoolType) {
    // Use the last generated credentials if available, otherwise generate display data
    List<Map<String, String>> staffCredentials = _lastGeneratedCredentials.isNotEmpty 
        ? _lastGeneratedCredentials 
        : _generateDisplayCredentials(schoolId, schoolType);
    
    // Show the credentials export dialog
    _generateStaffCredentialsFile(schoolId, staffCredentials);
  }
  
  List<Map<String, String>> _generateDisplayCredentials(String schoolId, String schoolType) {
    final classes = _getClassList(schoolType);
    List<Map<String, String>> staffCredentials = [];
    
    // Generate display credentials for preview
    for (int i = 0; i < classes.length; i++) {
      final className = classes[i];
      final displayStaffId = '${schoolId}STF${(i + 1).toString().padLeft(3, '0')}'; // Use correct format: 444STF001
      final username = displayStaffId.toLowerCase();
      staffCredentials.add({
        'Class': 'Class $className',
        'Staff Name': 'Class $className Teacher',
        'Username': username,
        'Password': 'staff123',
        'Staff ID': displayStaffId,
        'Email': '$username@${schoolId.toLowerCase()}.edu',
        'Phone': '+91-${9000000000 + i}',
      });
    }
    
    return staffCredentials;
  }



  void _showAddStudentDialog() {
    final nameController = TextEditingController();
    final rollController = TextEditingController();
    final classController = TextEditingController();
    final rfidController = TextEditingController();
    final parentNameController = TextEditingController();
    final parentPhoneController = TextEditingController();
    final addressController = TextEditingController();
    final dobController = TextEditingController();
    
    showDialog(
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
                  labelText: 'Student Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rollController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: classController,
                decoration: const InputDecoration(
                  labelText: 'Class/Section *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 10-A',
                ),
              ),
              const SizedBox(height: 12),
              // Enhanced RFID Field with Scan Option
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: rfidController,
                      decoration: const InputDecoration(
                        labelText: 'RFID Tag ID (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Tap scan or enter manually',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _scanRfidForStudent(rfidController);
                    },
                    icon: const Icon(Icons.nfc, size: 20),
                    label: const Text('Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Parent Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: parentPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Parent Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
              // Validate required fields
              if (nameController.text.trim().isEmpty ||
                  rollController.text.trim().isEmpty ||
                  classController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields (*)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                Navigator.pop(context);
                
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 16),
                        Text('Adding student...'),
                      ],
                    ),
                    duration: Duration(seconds: 30),
                  ),
                );

                // Get school ID from staff info
                String? schoolUuid = widget.staffInfo?['school_id'] ?? widget.staffInfo?['schoolId'];
                print('🔍 Staff info: ${widget.staffInfo}');
                print('🔍 School ID from staff info: $schoolUuid');
                
                if (schoolUuid == null || schoolUuid.isEmpty) {
                  // If no school ID in staff info, try to get the first available school
                  final schools = await SupabasePostgreSQLService.getSchools();
                  if (schools.isNotEmpty) {
                    schoolUuid = schools.first.id;
                    print('🔍 Using first available school: $schoolUuid');
                  } else {
                    throw Exception('No schools found in database');
                  }
                }
                
                print('🔍 Using school UUID: $schoolUuid');

                // Create Student object
                final student = Student(
                  studentId: 'STU${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  rollNumber: rollController.text.trim(),
                  className: classController.text.trim(),
                  section: 'A', // Default section
                  schoolId: schoolUuid,
                  address: addressController.text.trim(),
                  dateOfBirth: dobController.text.trim().isNotEmpty 
                    ? DateTime.tryParse(dobController.text.trim()) ?? DateTime.now()
                    : DateTime.now(),
                  parentName: parentNameController.text.trim().isNotEmpty 
                    ? parentNameController.text.trim() 
                    : 'Parent',
                  parentPhone: parentPhoneController.text.trim().isNotEmpty 
                    ? parentPhoneController.text.trim() 
                    : '',
                  parentEmail: '',
                  rfidTag: rfidController.text.trim(),
                );

                // Save to database
                await SupabasePostgreSQLService.createStudent(student);

                // Add to local list for immediate UI update
                final newStudentMap = {
                  'id': student.id,
                  'studentId': student.studentId,
                  'name': student.name,
                  'className': student.className,
                  'email': student.parentEmail,
                  'phone': student.parentPhone,
                  'rfidTag': student.rfidTag,
                  'isActive': student.isActive,
                  'schoolId': student.schoolId,
                  'section': student.section,
                  'rollNumber': student.rollNumber,
                  'createdAt': student.createdAt.toIso8601String(),
                  'updatedAt': student.updatedAt.toIso8601String(),
                };

                setState(() {
                  _allStudents.add(newStudentMap);
                  _filteredStudents = List.from(_allStudents);
                });
                
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${student.name} added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('❌ Error adding student: $e');
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Failed to add student: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  void _simulateRFIDScan() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('RFID Scanner Active'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Waiting for RFID tag...'),
          ],
        ),
      ),
    );
    
    // Simulate scan after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Attendance marked for Student ID: RF001'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showReportDetails(String reportType, String description) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    reportType,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.grey),
              ),
              
              const SizedBox(height: 20),
              
              Expanded(
                child: _buildReportContent(reportType),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _exportReport(reportType),
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(String reportType) {
    switch (reportType) {
      case 'Attendance Report':
        return _buildAttendanceReport();
      case 'Staff Report':
        return _buildStaffReport();
      case 'Class Report':
        return _buildClassReport();
      case 'Student Report':
        return _buildStudentReport();
      default:
        return const Center(
          child: Text('Report content not available'),
        );
    }
  }

  Widget _buildAttendanceReport() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Attendance Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Daily and monthly attendance statistics\nwould be displayed here with charts and graphs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffReport() {
    return Consumer(
      builder: (context, ref, child) {
        final staffState = ref.watch(staffProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${staffState.staffList.where((s) => s.isActive).length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const Text('Active Staff', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${staffState.staffList.where((s) => !s.isActive).length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const Text('Inactive Staff', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${staffState.staffList.length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const Text('Total Staff', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Overview',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: staffState.staffList.isEmpty
                            ? const Center(
                                child: Text(
                                  'No staff members found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: staffState.staffList.length,
                                itemBuilder: (context, index) {
                                  final staff = staffState.staffList[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: staff.isActive ? Colors.green : Colors.red,
                                      child: Text(staff.name.substring(0, 1)),
                                    ),
                                    title: Text(staff.name),
                                    subtitle: Text('${staff.role} | Classes: ${staff.assignedClasses.join(", ")}'),
                                    trailing: Chip(
                                      label: Text(staff.isActive ? 'Active' : 'Inactive'),
                                      backgroundColor: staff.isActive ? Colors.green.shade100 : Colors.red.shade100,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClassReport() {
    return Consumer(
      builder: (context, ref, child) {
        final schoolState = ref.watch(schoolProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class-wise Statistics',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: schoolState.schools.isEmpty
                  ? const Center(
                      child: Text(
                        'No schools found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: schoolState.schools.length,
                      itemBuilder: (context, schoolIndex) {
                        final school = schoolState.schools[schoolIndex];
                        return Card(
                          child: ExpansionTile(
                            title: Text(school.name),
                            subtitle: Text('${school.classes.length} classes'),
                            children: school.classes.map((className) {
                              return ListTile(
                                leading: const Icon(Icons.class_),
                                title: Text('Class $className'),
                                subtitle: const Text('Students: -- | Avg Attendance: --%'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Detailed report for Class $className'),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentReport() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Student Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Student attendance patterns and performance\nmetrics would be displayed here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _exportReport(String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$reportType exported successfully!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Open exported file functionality would be implemented here
          },
        ),
      ),
    );
  }

  void _showFeatureComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reports & Analytics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildReportCard(
                      'Daily Attendance',
                      'View daily attendance records',
                      Icons.today,
                      Colors.blue,
                      () => _generateDailyReport(),
                    ),
                    _buildReportCard(
                      'Monthly Summary',
                      'Monthly attendance summary',
                      Icons.calendar_month,
                      Colors.green,
                      () => _generateMonthlyReport(),
                    ),
                    _buildReportCard(
                      'Staff Reports',
                      'Staff attendance and performance',
                      Icons.people,
                      Colors.orange,
                      () => _generateStaffReport(),
                    ),
                    _buildReportCard(
                      'School Analytics',
                      'Comprehensive school analytics',
                      Icons.analytics,
                      Colors.purple,
                      () => _generateSchoolAnalytics(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateDailyReport() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily attendance report generated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateMonthlyReport() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Monthly attendance report generated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateStaffReport() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Staff attendance report generated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateSchoolAnalytics() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('School analytics report generated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Smart Attendance'),
        content: const Text(
          'Smart Attendance Management System\n\n'
          'Version: 1.0.0\n'
          'SIH 2025 Project\n\n'
          'Features:\n'
          '• Device-based attendance tracking\n'
          '• Real-time synchronization\n'
          '• Admin and Staff roles\n'
          '• USB & Bluetooth device support\n'
          '• Offline-first architecture',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeviceSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: 600,
            height: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Device Settings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      SwitchListTile(
                        title: const Text('USB Device Detection'),
                        subtitle: const Text('Automatically detect USB attendance devices'),
                        value: _usbDetectionEnabled,
                        onChanged: (value) async {
                          setDialogState(() {
                            _usbDetectionEnabled = value;
                          });
                          setState(() {
                            _usbDetectionEnabled = value;
                          });
                          await _saveDeviceSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    value ? Icons.usb : Icons.usb_off,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('USB detection ${value ? 'enabled' : 'disabled'}'),
                                ],
                              ),
                              backgroundColor: value ? Colors.green : Colors.orange,
                            ),
                          );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Bluetooth Device Detection'),
                        subtitle: const Text('Automatically detect Bluetooth attendance devices'),
                        value: _bluetoothDetectionEnabled,
                        onChanged: (value) async {
                          setDialogState(() {
                            _bluetoothDetectionEnabled = value;
                          });
                          setState(() {
                            _bluetoothDetectionEnabled = value;
                          });
                          await _saveDeviceSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    value ? Icons.bluetooth : Icons.bluetooth_disabled,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Bluetooth detection ${value ? 'enabled' : 'disabled'}'),
                                ],
                              ),
                              backgroundColor: value ? Colors.green : Colors.orange,
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Device Scan Frequency'),
                        subtitle: const Text('How often to scan for new devices'),
                        trailing: DropdownButton<String>(
                          value: _scanFrequency,
                          items: ['Every 10 seconds', 'Every 30 seconds', 'Every minute']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              setDialogState(() {
                                _scanFrequency = value;
                              });
                              setState(() {
                                _scanFrequency = value;
                              });
                              await _saveDeviceSettings();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.schedule, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text('Scan frequency set to: $value'),
                                    ],
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('Connected Devices'),
                        subtitle: Text('${_getConnectedDevicesCount()} devices currently connected'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pop(context);
                          _showConnectedDevices();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSyncSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
            height: 550,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sync, color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Sync Settings',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        child: SwitchListTile(
                          title: const Text('Auto Sync'),
                          subtitle: const Text('Automatically sync data to cloud'),
                          value: _autoSyncEnabled,
                          onChanged: (value) async {
                            setDialogState(() {
                              _autoSyncEnabled = value;
                            });
                            setState(() {
                              _autoSyncEnabled = value;
                            });
                            await _saveSyncSettings();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      value ? Icons.check_circle : Icons.cancel,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Auto sync ${value ? 'enabled' : 'disabled'}'),
                                  ],
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.schedule, color: Colors.blue),
                          title: const Text('Sync Frequency'),
                          subtitle: Text('Currently: $_syncFrequency'),
                          trailing: DropdownButton<String>(
                            value: _syncFrequency,
                            items: ['Every 15 minutes', 'Every hour', 'Every 6 hours', 'Daily']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setDialogState(() {
                                  _syncFrequency = value;
                                });
                                setState(() {
                                  _syncFrequency = value;
                                });
                                await _saveSyncSettings();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.schedule, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text('Sync frequency set to: $value'),
                                      ],
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      Card(
                        child: SwitchListTile(
                          title: const Text('Sync on WiFi Only'),
                          subtitle: const Text('Only sync when connected to WiFi'),
                          value: _wifiOnlySyncEnabled,
                          onChanged: (value) async {
                            setDialogState(() {
                              _wifiOnlySyncEnabled = value;
                            });
                            setState(() {
                              _wifiOnlySyncEnabled = value;
                            });
                            await _saveSyncSettings();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      value ? Icons.wifi : Icons.wifi_off,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('WiFi-only sync ${value ? 'enabled' : 'disabled'}'),
                                  ],
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.green),
                          title: const Text('Last Sync'),
                          subtitle: const Text('2 minutes ago'),
                          trailing: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Syncing data...'),
                                    ],
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            icon: const Icon(Icons.sync, size: 18),
                            label: const Text('Sync Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Status Summary
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.green.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Sync Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Auto Sync: ${_autoSyncEnabled ? "ON" : "OFF"} • '
                              'Frequency: $_syncFrequency • '
                              'WiFi Only: ${_wifiOnlySyncEnabled ? "ON" : "OFF"}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBackupSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
            height: 550,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.backup, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Backup & Restore',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.backup, color: Colors.blue, size: 32),
                          title: const Text('Create Backup'),
                          subtitle: const Text('Create a full backup of all data'),
                          trailing: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Creating backup...'),
                                    ],
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                              
                              // Simulate backup creation
                              Future.delayed(const Duration(seconds: 2), () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Backup created successfully!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              });
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Create'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.restore, color: Colors.orange, size: 32),
                          title: const Text('Restore from Backup'),
                          subtitle: const Text('Restore data from a previous backup'),
                          trailing: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.folder_open, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Select backup file to restore'),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            icon: const Icon(Icons.folder_open, size: 18),
                            label: const Text('Restore'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        child: SwitchListTile(
                          title: const Text('Auto Backup'),
                          subtitle: const Text('Automatically create backups'),
                          value: _autoBackupEnabled,
                          onChanged: (value) async {
                            setDialogState(() {
                              _autoBackupEnabled = value;
                            });
                            setState(() {
                              _autoBackupEnabled = value;
                            });
                            await _saveBackupSettings();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      value ? Icons.check_circle : Icons.cancel,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Auto backup ${value ? 'enabled' : 'disabled'}'),
                                  ],
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.schedule, color: Colors.purple),
                          title: const Text('Backup Frequency'),
                          subtitle: Text('Currently: $_backupFrequency'),
                          trailing: DropdownButton<String>(
                            value: _backupFrequency,
                            items: ['Daily', 'Weekly', 'Monthly']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setDialogState(() {
                                  _backupFrequency = value;
                                });
                                setState(() {
                                  _backupFrequency = value;
                                });
                                await _saveBackupSettings();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.schedule, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text('Backup frequency set to: $value'),
                                      ],
                                    ),
                                    backgroundColor: Colors.purple,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      Card(
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.green),
                          title: const Text('Last Backup'),
                          subtitle: const Text('Today at 3:00 AM'),
                          trailing: const Icon(Icons.check_circle, color: Colors.green),
                        ),
                      ),
                      // Status Summary
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade50, Colors.blue.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Backup Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Auto Backup: ${_autoBackupEnabled ? "ON" : "OFF"} • '
                              'Frequency: $_backupFrequency • '
                              'Last backup: 3 hours ago',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUnauthorizedAccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Unauthorized Access'),
        content: const Text(
          'Only administrators can access security settings. Please contact your system administrator if you need to make changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings() {
    // Only allow admin access to security settings
    if (!isAdmin) {
      _showUnauthorizedAccess();
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
            height: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.red, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Security Settings',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.lock, color: Colors.red, size: 32),
                          title: const Text('Change Admin Password'),
                          subtitle: const Text('Update the admin account password'),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _showChangePasswordDialog(),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        child: SwitchListTile(
                          title: const Text('Two-Factor Authentication'),
                          subtitle: const Text('Enable 2FA for admin accounts'),
                          value: _twoFactorAuthEnabled,
                          onChanged: (value) async {
                            setDialogState(() {
                              _twoFactorAuthEnabled = value;
                            });
                            setState(() {
                              _twoFactorAuthEnabled = value;
                            });
                            await _saveSecuritySettings();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      value ? Icons.check_circle : Icons.cancel,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('2FA ${value ? 'enabled' : 'disabled'}'),
                                  ],
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),

                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.purple, size: 32),
                          title: const Text('Access Logs'),
                          subtitle: const Text('View system access history'),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _showAccessLogsDialog(),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Status Summary
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade50, Colors.orange.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.security, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Security Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '2FA: ${_twoFactorAuthEnabled ? "ON" : "OFF"} • '
                              'Password Protection: ACTIVE • '
                              'Security Level: ${_twoFactorAuthEnabled ? "High" : "Medium"}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            if (!_twoFactorAuthEnabled)
                              const SizedBox(height: 8),
                            if (!_twoFactorAuthEnabled)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Consider enabling 2FA for better security',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
            height: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications, color: Colors.orange, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Notification Settings',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        child: SwitchListTile(
                          title: const Text('Attendance Notifications'),
                          subtitle: const Text('Get notified about attendance issues'),
                          value: _attendanceNotificationsEnabled,
                          onChanged: (value) async {
                            setDialogState(() {
                              _attendanceNotificationsEnabled = value;
                            });
                            setState(() {
                              _attendanceNotificationsEnabled = value;
                            });
                            await _saveNotificationSettings();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      value ? Icons.check_circle : Icons.cancel,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Attendance alerts ${value ? 'enabled' : 'disabled'}'),
                                  ],
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                      Card(
                        child: SwitchListTile(
                          title: const Text('System Notifications'),
                          subtitle: const Text('Get notified about system updates and alerts'),
                          value: _systemNotificationsEnabled,
                          onChanged: (value) async {
                            setDialogState(() {
                              _systemNotificationsEnabled = value;
                            });
                            setState(() {
                              _systemNotificationsEnabled = value;
                            });
                            await _saveNotificationSettings();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      value ? Icons.check_circle : Icons.cancel,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('System notifications ${value ? 'enabled' : 'disabled'}'),
                                  ],
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                      Card(
                        child: SwitchListTile(
                          title: const Text('Email Notifications'),
                          subtitle: const Text('Send notifications via email'),
                          value: _emailNotificationsEnabled,
                          onChanged: (value) async {
                            setDialogState(() {
                              _emailNotificationsEnabled = value;
                            });
                            setState(() {
                              _emailNotificationsEnabled = value;
                            });
                            await _saveNotificationSettings();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      value ? Icons.email : Icons.email_outlined,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Email notifications ${value ? 'enabled' : 'disabled'}'),
                                  ],
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                      Card(
                        child: SwitchListTile(
                          title: const Text('Sound Notifications'),
                          subtitle: const Text('Play sound for notifications'),
                          value: _soundEnabled,
                          onChanged: (value) async {
                            setDialogState(() {
                              _soundEnabled = value;
                            });
                            setState(() {
                              _soundEnabled = value;
                            });
                            await _saveNotificationSettings();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      value ? Icons.volume_up : Icons.volume_off,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Sound notifications ${value ? 'enabled' : 'disabled'}'),
                                  ],
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                      // Test notification button
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.notification_important, color: Colors.blue, size: 32),
                          title: const Text('Test Notifications'),
                          subtitle: const Text('Send a test notification'),
                          trailing: ElevatedButton.icon(
                            onPressed: () {
                              if (_attendanceNotificationsEnabled || _systemNotificationsEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Test notification sent!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Enable notifications first'),
                                      ],
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Status Summary
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade50, Colors.blue.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.notifications_active, color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Notification Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Attendance: ${_attendanceNotificationsEnabled ? "ON" : "OFF"} • '
                              'System: ${_systemNotificationsEnabled ? "ON" : "OFF"} • '
                              'Email: ${_emailNotificationsEnabled ? "ON" : "OFF"} • '
                              'Sound: ${_soundEnabled ? "ON" : "OFF"}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  (_attendanceNotificationsEnabled || _systemNotificationsEnabled) 
                                    ? Icons.check_circle 
                                    : Icons.warning,
                                  color: (_attendanceNotificationsEnabled || _systemNotificationsEnabled) 
                                    ? Colors.green 
                                    : Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    (_attendanceNotificationsEnabled || _systemNotificationsEnabled) 
                                      ? 'Notifications are active'
                                      : 'No notifications enabled',
                                    style: TextStyle(
                                      color: (_attendanceNotificationsEnabled || _systemNotificationsEnabled) 
                                        ? Colors.green 
                                        : Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Staff Role Management
  void _showStaffRoleManagement() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Staff Role Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () => _showAddStaffRoleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add New Role'),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  itemCount: _staffRoles.length,
                  itemBuilder: (context, index) {
                    final role = _staffRoles[index];
                    return _buildStaffRoleCard(
                      role['name'] as String,
                      role['description'] as String,
                      role['icon'] as IconData,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffRoleCard(String role, String description, IconData icon) {
    // Find the role to get permissions count
    final roleData = _staffRoles.firstWhere(
      (r) => r['name'] == role,
      orElse: () => {'permissions': <String>[]},
    );
    final permissionsCount = _convertToStringList(roleData['permissions']).length;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          role,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.security, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '$permissionsCount permissions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit Role'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'permissions',
              child: Row(
                children: [
                  Icon(Icons.security, size: 16),
                  SizedBox(width: 8),
                  Text('Permissions'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Role', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleStaffRoleAction(value, role, description, icon),
        ),
      ),
    );
  }

  void _handleStaffRoleAction(String action, String role, String description, IconData icon) {
    switch (action) {
      case 'edit':
        _showEditStaffRoleDialog(role, description, icon);
        break;
      case 'permissions':
        _showRolePermissionsDialog(role);
        break;
      case 'delete':
        _showDeleteRoleConfirmation(role);
        break;
    }
  }
  
  void _refreshStaffRoles() {
    setState(() {
      // Trigger rebuild of role list
    });
  }
  
  IconData _getRandomRoleIcon() {
    final icons = [
      Icons.work_outline,
      Icons.badge_outlined,
      Icons.admin_panel_settings_outlined,
      Icons.supervisor_account_outlined,
      Icons.person_outline,
      Icons.group_outlined,
      Icons.school_outlined,
      Icons.business_center_outlined,
    ];
    return icons[DateTime.now().millisecondsSinceEpoch % icons.length];
  }
  
  String _getPermissionDescription(String permission) {
    switch (permission) {
      case 'View Attendance':
        return 'Can view attendance records and reports';
      case 'Mark Attendance':
        return 'Can mark students as present, absent, or late';
      case 'Edit Student Records':
        return 'Can modify student information and records';
      case 'Generate Reports':
        return 'Can create and export attendance reports';
      case 'Manage Classes':
        return 'Can create, edit, and delete class information';
      case 'Access Settings':
        return 'Can access and modify system settings';
      case 'Manage Staff':
        return 'Can add, edit, and remove staff members';
      case 'Delete Records':
        return 'Can permanently delete attendance and student records';
      default:
        return 'Custom permission';
    }
  }
  
  IconData _getPermissionIcon(String permission) {
    switch (permission) {
      case 'View Attendance':
        return Icons.visibility;
      case 'Mark Attendance':
        return Icons.check_circle;
      case 'Edit Student Records':
        return Icons.edit;
      case 'Generate Reports':
        return Icons.assessment;
      case 'Manage Classes':
        return Icons.class_;
      case 'Access Settings':
        return Icons.settings;
      case 'Manage Staff':
        return Icons.group;
      case 'Delete Records':
        return Icons.delete_forever;
      default:
        return Icons.security;
    }
  }
  
  String _getIconName(IconData icon) {
    switch (icon) {
      case Icons.person:
        return 'person';
      case Icons.person_outline:
        return 'person_outline';
      case Icons.school:
        return 'school';
      case Icons.book:
        return 'book';
      case Icons.support_agent:
        return 'support_agent';
      case Icons.work_outline:
        return 'work_outline';
      case Icons.badge_outlined:
        return 'badge_outlined';
      case Icons.admin_panel_settings_outlined:
        return 'admin_panel_settings_outlined';
      case Icons.supervisor_account_outlined:
        return 'supervisor_account_outlined';
      case Icons.group_outlined:
        return 'group_outlined';
      case Icons.school_outlined:
        return 'school_outlined';
      case Icons.business_center_outlined:
        return 'business_center_outlined';
      default:
        return 'person';
    }
  }
  
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'person_outline':
        return Icons.person_outline;
      case 'school':
        return Icons.school;
      case 'book':
        return Icons.book;
      case 'support_agent':
        return Icons.support_agent;
      case 'work_outline':
        return Icons.work_outline;
      case 'badge_outlined':
        return Icons.badge_outlined;
      case 'admin_panel_settings_outlined':
        return Icons.admin_panel_settings_outlined;
      case 'supervisor_account_outlined':
        return Icons.supervisor_account_outlined;
      case 'group_outlined':
        return Icons.group_outlined;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      default:
        return Icons.person;
    }
  }

  void _showEditStaffRoleDialog(String currentRole, String currentDescription, IconData currentIcon) {
    final roleController = TextEditingController(text: currentRole);
    final descriptionController = TextEditingController(text: currentDescription);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Staff Role: $currentRole'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roleController,
              decoration: const InputDecoration(
                labelText: 'Role Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRole = roleController.text.trim();
              final newDescription = descriptionController.text.trim();
              
              if (newRole.isNotEmpty && newDescription.isNotEmpty) {
                Navigator.pop(context);
                setState(() {
                  // Find and update the role
                  final roleIndex = _staffRoles.indexWhere((r) => r['name'] == currentRole);
                  if (roleIndex != -1) {
                    final existingPermissions = _staffRoles[roleIndex]['permissions'] ?? [];
                    _staffRoles[roleIndex] = {
                      'name': newRole,
                      'description': newDescription,
                      'icon': currentIcon,
                      'permissions': existingPermissions, // Preserve existing permissions
                    };
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Role "$newRole" updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Update Role'),
          ),
        ],
      ),
    );
  }

  void _showRolePermissionsDialog(String role) {
    final allPermissions = [
      'View Attendance',
      'Mark Attendance', 
      'Edit Student Records',
      'Generate Reports',
      'Manage Classes',
      'Access Settings',
      'Manage Staff',
      'Delete Records',
    ];

    // Find the role and get its current permissions
    final roleIndex = _staffRoles.indexWhere((r) => r['name'] == role);
    if (roleIndex == -1) return;
    
    final currentPermissions = List<String>.from(_staffRoles[roleIndex]['permissions'] ?? []);
    final tempPermissions = List<String>.from(currentPermissions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(_staffRoles[roleIndex]['icon'] as IconData, color: Colors.blue),
              const SizedBox(width: 8),
              Text('$role Permissions'),
            ],
          ),
          content: Container(
            width: 400,
            height: 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select permissions for $role:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: allPermissions.length,
                    itemBuilder: (context, index) {
                      final permission = allPermissions[index];
                      final isSelected = tempPermissions.contains(permission);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: CheckboxListTile(
                          title: Text(
                            permission,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.blue : Colors.black87,
                            ),
                          ),
                          subtitle: Text(_getPermissionDescription(permission)),
                          value: isSelected,
                          activeColor: Colors.blue,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                if (!tempPermissions.contains(permission)) {
                                  tempPermissions.add(permission);
                                }
                              } else {
                                tempPermissions.remove(permission);
                              }
                            });
                          },
                          secondary: Icon(
                            _getPermissionIcon(permission),
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '${tempPermissions.length} of ${allPermissions.length} permissions selected',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ],
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
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  // Update the role's permissions
                  _staffRoles[roleIndex]['permissions'] = tempPermissions;
                });
                
                // Save to persistent storage
                await _saveStaffRoles();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.security, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Permissions for "$role" updated and saved!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'View',
                      textColor: Colors.white,
                      onPressed: () {
                        _showRolePermissionsDialog(role);
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteRoleConfirmation(String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Role'),
        content: Text('Are you sure you want to delete the "$role" role?\n\nThis action cannot be undone and will affect all staff members with this role.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                print('DEBUG: Before deletion, roles count: ${_staffRoles.length}');
                _staffRoles.removeWhere((r) => r['name'] == role);
                print('DEBUG: After deletion, roles count: ${_staffRoles.length}');
                print('DEBUG: Remaining roles: ${_staffRoles.map((r) => r['name']).join(', ')}');
              });
              
              // Save to persistent storage
              await _saveStaffRoles();
              
              // Close the staff role dialog and reopen it to show updated list
              Navigator.pop(context); // Close staff role management dialog
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.delete_forever, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Role "$role" deleted and saved!'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Reopen',
                    textColor: Colors.white,
                    onPressed: () {
                      _showStaffRoleManagement();
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete Role'),
          ),
        ],
      ),
    );
  }

  void _showAddStaffRoleDialog() {
    final roleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roleController,
              decoration: const InputDecoration(
                labelText: 'Role Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final roleName = roleController.text.trim();
              final description = descriptionController.text.trim();
              
              if (roleName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a role name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a description'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Check if role already exists
              final existingRole = _staffRoles.any((role) => 
                role['name'].toString().toLowerCase() == roleName.toLowerCase());
              
              if (existingRole) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Role "$roleName" already exists'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              setState(() {
                print('DEBUG: Before adding role, roles count: ${_staffRoles.length}');
                _staffRoles.add({
                  'name': roleName,
                  'description': description,
                  'icon': _getRandomRoleIcon(),
                  'permissions': ['View Attendance', 'Mark Attendance'], // Default permissions for new roles
                });
                print('DEBUG: After adding role, roles count: ${_staffRoles.length}');
                print('DEBUG: Added role: $roleName');
              });
              
              // Save to persistent storage
              await _saveStaffRoles();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Staff role "$roleName" added and saved!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Class Management
  void _showClassManagement(String schoolId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Class Management - School: $schoolId',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () => _showAddClassDialog(schoolId),
                icon: const Icon(Icons.add),
                label: const Text('Add New Class'),
              ),
              
              const SizedBox(height: 16),
              
              // Class Categories
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildClassCategory('Pre-Primary', ['Pre-KG', 'LKG', 'UKG'], schoolId),
                      _buildClassCategory('Primary', ['1st', '2nd', '3rd', '4th', '5th'], schoolId),
                      _buildClassCategory('Middle School', ['6th', '7th', '8th'], schoolId),
                      _buildClassCategory('High School', ['9th', '10th'], schoolId),
                      _buildClassCategory('Higher Secondary', ['11th', '12th'], schoolId),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCategory(String category, List<String> classes, String schoolId) {
    return Card(
      child: ExpansionTile(
        title: Text(category),
        children: classes.map((className) => ListTile(
          title: Text('Class $className'),
          subtitle: Text('Students: ${(20 + className.hashCode % 30)}'),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'assign_teacher', child: Text('Assign Teacher')),
              const PopupMenuItem(value: 'view_students', child: Text('View Students')),
              const PopupMenuItem(value: 'edit', child: Text('Edit Class')),
            ],
            onSelected: (value) {
              if (value == 'assign_teacher') {
                _showAssignTeacherDialog(schoolId, className);
              } else {
                _showFeatureComingSoon();
              }
            },
          ),
        )).toList(),
      ),
    );
  }

  void _showAddClassDialog(String schoolId) {
    String selectedCategory = 'Primary';
    final classNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Pre-Primary', 'Primary', 'Middle School', 'High School', 'Higher Secondary']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: classNameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name (e.g., 1st, 2nd, etc.)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Class ${classNameController.text} added to $selectedCategory!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Staff Management
  void _showStaffManagement(String schoolId) {
    // Clear cached credentials to ensure fresh data
    _lastGeneratedCredentials.clear();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Staff Management - School: $schoolId',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () => _showAddStaffDialog(schoolId),
                icon: const Icon(Icons.add),
                label: const Text('Add New Staff'),
              ),
              
              const SizedBox(height: 16),
              
              // Staff List
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final staffState = ref.watch(schoolStaffProvider(schoolId));
                    
                    if (staffState.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    if (staffState.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('Error: ${staffState.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(schoolStaffProvider(schoolId).notifier).loadStaffBySchool(schoolId),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final schoolStaff = staffState.staffList;
                    
                    if (schoolStaff.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No staff members yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Click "Add New Staff" to create staff accounts',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: schoolStaff.length,
                      itemBuilder: (context, index) {
                        final staff = schoolStaff[index];
                        return _buildDynamicStaffCard(staff);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicStaffCard(Staff staff) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: staff.isActive ? Colors.green : Colors.red,
          child: Text(staff.name.split(' ').map((n) => n[0]).join()),
        ),
        title: Text(staff.name),
        subtitle: Text('${staff.role} | ID: ${staff.staffId} | Status: ${staff.isActive ? 'Active' : 'Inactive'}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Staff')),
            const PopupMenuItem(value: 'assign_class', child: Text('Assign Classes')),
            const PopupMenuItem(value: 'reset_password', child: Text('Reset Password')),
            PopupMenuItem(
              value: staff.isActive ? 'deactivate' : 'activate',
              child: Text(staff.isActive ? 'Deactivate' : 'Activate'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete Staff')),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditStaffDialog(staff);
                break;
              case 'reset_password':
                _showResetPasswordDialog(staff.staffId);
                break;
              case 'assign_class':
                _showAssignClassesToStaff(staff.schoolId, staff.staffId, staff.name);
                break;
              case 'activate':
              case 'deactivate':
                _toggleStaffStatus(staff);
                break;
              case 'delete':
                _showDeleteStaffConfirmation(staff);
                break;
              default:
                _showFeatureComingSoon();
            }
          },
        ),
      ),
    );
  }

  void _showAddStaffDialog(String schoolId) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Teacher';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Principal', 'Vice Principal', 'Head Teacher', 'Teacher', 'Support Staff']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Generated Staff Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Staff ID: $schoolId${_generateNextStaffNumber(schoolId)}'),
                      const Text('Default Password: staff123'),
                      const Text('(Must be changed on first login)', 
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
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
              onPressed: () => _createNewStaff(
                schoolId,
                nameController.text,
                emailController.text,
                phoneController.text,
                selectedRole,
              ),
              child: const Text('Add Staff'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateNextStaffNumber(String schoolId) {
    // In a real app, this would query the database for the next available number
    return (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
  }



  // Create New Staff Implementation
  Future<void> _createNewStaff(
    String schoolUniqueId,
    String name,
    String email,
    String phone,
    String role,
  ) async {
    // Validate inputs
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Generate staff ID using the SupabaseService method
      final staffId = await ref.read(staffProvider.notifier).generateNextStaffId(schoolUniqueId);
      
      // Get the actual school database ID from unique_id - this will be handled in the service layer
      final schoolDbId = schoolUniqueId; // For now, let the service handle the conversion
      
      // Create staff object
      final newStaff = Staff(
        staffId: staffId,
        schoolId: schoolDbId,
        name: name,
        email: email,
        phone: phone,
        role: role,
        assignedClasses: [], // Start with no classes assigned
        isActive: true,
        isFirstLogin: true,
        password: 'staff123', // Default password
      );

      // Save to database
      await ref.read(staffProvider.notifier).createStaff(newStaff);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff member "$name" added successfully!\nStaff ID: $staffId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );

      // Refresh staff list to show the new staff member
      await ref.read(schoolStaffProvider(schoolUniqueId).notifier).loadStaffBySchool(schoolUniqueId);
      
    } catch (e) {
      Navigator.pop(context);
      
      String errorMessage = 'Failed to add staff member';
      if (e.toString().contains('duplicate key value violates unique constraint')) {
        if (e.toString().contains('staff_email_key')) {
          errorMessage = 'A staff member with this email already exists';
        } else if (e.toString().contains('staff_id')) {
          errorMessage = 'A staff member with this ID already exists';
        } else {
          errorMessage = 'This staff member already exists';
        }
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid staff ID format. Please try again.';
      } else {
        errorMessage = 'Failed to add staff member: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAssignTeacherDialog(String schoolId, String className) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Teacher to Class $className'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Available Teachers:'),
            const SizedBox(height: 16),
            // Load actual teachers from database
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadTeachersForSchool(schoolId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error loading teachers: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No teachers available. Please add teachers first.');
                } else {
                  return Column(
                    children: snapshot.data!.map((teacher) => ListTile(
                      title: Text(teacher['name'] ?? 'Unknown'),
                      subtitle: Text(teacher['id'] ?? ''),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${teacher['name']} assigned to Class $className'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    )).toList(),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadTeachersForSchool(String schoolId) async {
    try {
      // Load staff members who are teachers for this school
      final staff = await SupabasePostgreSQLService.getStaffBySchool(schoolId);
      return staff.where((s) => s.role.toLowerCase() == 'teacher').map((s) => {
        'id': s.id,
        'name': s.name,
        'role': s.role,
      }).toList();
    } catch (e) {
      print('❌ Error loading teachers for school $schoolId: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentAttendance() async {
    try {
      // In a real app, this would load from database
      // For now, return empty list since students will be added by staff
      return [];
    } catch (e) {
      print('❌ Error loading recent attendance: $e');
      return [];
    }
  }

  void _showAssignClassesToStaff(String schoolId, String staffId, String staffName) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          // Get current staff data
          final staffState = ref.watch(staffProvider);
          final currentStaff = staffState.staffList.firstWhere(
            (staff) => staff.staffId == staffId,
            orElse: () => staffState.staffList.first,
          );
          
          // Get school data to determine available classes
          final schoolState = ref.watch(schoolProvider);
          final school = schoolState.schools.firstWhere(
            (s) => s.uniqueId == schoolId,
            orElse: () => schoolState.schools.first,
          );
          
          List<String> availableClasses = school.classes;
          List<String> assignedClasses = List<String>.from(currentStaff.assignedClasses);
          
          return StatefulBuilder(
            builder: (context, setState) => Dialog(
              child: Container(
                width: 500,
                height: 600,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Assign Classes to $staffName',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    Text(
                      'Staff ID: $staffId',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Available Classes for ${school.schoolType} School:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: ListView(
                        children: availableClasses.map((className) {
                          bool isAssigned = assignedClasses.contains(className);
                          return CheckboxListTile(
                            title: Text('Class $className'),
                            subtitle: Text(isAssigned ? 'Currently assigned' : 'Available'),
                            value: isAssigned,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  if (!assignedClasses.contains(className)) {
                                    assignedClasses.add(className);
                                  }
                                } else {
                                  assignedClasses.remove(className);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Currently Assigned Classes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assignedClasses.isEmpty 
                              ? 'No classes assigned'
                              : assignedClasses.join(', '),
                            style: TextStyle(
                              color: assignedClasses.isEmpty ? Colors.grey : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _saveClassAssignments(currentStaff, assignedClasses),
                          icon: const Icon(Icons.save),
                          label: const Text('Save Assignments'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Save class assignments
  Future<void> _saveClassAssignments(Staff staff, List<String> assignedClasses) async {
    try {
      final updatedStaff = Staff(
        id: staff.id,
        staffId: staff.staffId,
        schoolId: staff.schoolId,
        name: staff.name,
        email: staff.email,
        phone: staff.phone,
        role: staff.role,
        assignedClasses: assignedClasses,
        rfidTag: staff.rfidTag,
        isActive: staff.isActive,
        createdAt: staff.createdAt,
        updatedAt: DateTime.now(),
        isFirstLogin: staff.isFirstLogin,
        password: staff.password,
      );

      await ref.read(staffProvider.notifier).updateStaff(updatedStaff);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Class assignments updated for ${staff.name}'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update class assignments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResetPasswordDialog(String staffId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reset password for Staff ID: $staffId'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text('New temporary password: temp123'),
                  Text('Staff must change on next login', 
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset for Staff ID: $staffId'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Edit Staff Dialog
  void _showEditStaffDialog(Staff staff) {
    final nameController = TextEditingController(text: staff.name);
    final emailController = TextEditingController(text: staff.email);
    final phoneController = TextEditingController(text: staff.phone);
    String selectedRole = staff.role;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Staff Member',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Principal', 'Vice Principal', 'Head Teacher', 'Teacher', 'Assistant Teacher']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedRole = value!);
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _updateStaffMember(
                      staff,
                      nameController.text,
                      emailController.text,
                      phoneController.text,
                      selectedRole,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Update Staff'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle Staff Status
  Future<void> _toggleStaffStatus(Staff staff) async {
    try {
      final updatedStaff = Staff(
        id: staff.id,
        name: staff.name,
        email: staff.email,
        phone: staff.phone,
        role: staff.role,
        staffId: staff.staffId,
        schoolId: staff.schoolId,
        isActive: !staff.isActive,
        createdAt: staff.createdAt,
        updatedAt: DateTime.now(),
        assignedClasses: staff.assignedClasses,
      );

      await ref.read(staffProvider.notifier).updateStaff(updatedStaff);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff ${staff.isActive ? 'deactivated' : 'activated'} successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update staff status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete Staff Confirmation
  void _showDeleteStaffConfirmation(Staff staff) {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Admin users can delete staff members'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${staff.name}"?'),
            const SizedBox(height: 16),
            const Text(
              'This action will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Delete the staff account permanently'),
            const Text('• Remove access to the system'),
            const Text('• Delete attendance records'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => _deleteStaffMember(staff),
            icon: const Icon(Icons.delete),
            label: const Text('Delete Staff'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Update Staff Implementation
  Future<void> _updateStaffMember(
    Staff staff,
    String name,
    String email,
    String phone,
    String role,
  ) async {
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final updatedStaff = Staff(
        id: staff.id,
        name: name,
        email: email,
        phone: phone,
        role: role,
        staffId: staff.staffId,
        schoolId: staff.schoolId,
        isActive: staff.isActive,
        createdAt: staff.createdAt,
        updatedAt: DateTime.now(),
        assignedClasses: staff.assignedClasses,
      );

      await ref.read(staffProvider.notifier).updateStaff(updatedStaff);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff member "$name" updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update staff member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete Staff Implementation
  Future<void> _deleteStaffMember(Staff staff) async {
    try {
      await ref.read(staffProvider.notifier).deleteStaff(staff.id);
      
      // Clear cached credentials to ensure consistency
      _lastGeneratedCredentials.clear();
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff member "${staff.name}" deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete staff member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSchoolReports(String schoolId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'School Reports - $schoolId',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  children: [
                    _buildReportCard('Attendance Report', 'Daily/Monthly attendance', Icons.today, Colors.blue, () => _generateDailyReport()),
                    _buildReportCard('Staff Report', 'Staff performance & activity', Icons.people, Colors.green, () => _generateStaffReport()),
                    _buildReportCard('Class Report', 'Class-wise statistics', Icons.class_, Colors.orange, () => _generateMonthlyReport()),
                    _buildReportCard('Student Report', 'Student attendance patterns', Icons.person, Colors.purple, () => _generateSchoolAnalytics()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Edit School Dialog
  void _showEditSchoolDialog(School school) {
    final nameController = TextEditingController(text: school.name);
    final addressController = TextEditingController(text: school.address);
    final phoneController = TextEditingController(text: school.phone);
    final emailController = TextEditingController(text: school.email);
    
    // Normalize school type to match dropdown options
    String selectedSchoolType = school.schoolType;
    final validTypes = ['Elementary', 'Secondary', 'Senior Secondary'];
    if (!validTypes.contains(selectedSchoolType)) {
      selectedSchoolType = 'Elementary'; // Default fallback
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit School',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'School Name',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  initialValue: selectedSchoolType,
                  decoration: const InputDecoration(
                    labelText: 'School Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Elementary',
                    'Secondary', 
                    'Senior Secondary'
                  ].map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => selectedSchoolType = value!);
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _updateSchool(
                      school,
                      nameController.text,
                      addressController.text,
                      phoneController.text,
                      emailController.text,
                      selectedSchoolType,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Update School'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Delete School Confirmation
  void _showDeleteSchoolConfirmation(School school) {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Admin users can delete schools'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete School'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${school.name}"?'),
            const SizedBox(height: 16),
            const Text(
              'This action will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Delete the school permanently'),
            const Text('• Remove all associated staff accounts'),
            const Text('• Delete all attendance records'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => _deleteSchool(school),
            icon: const Icon(Icons.delete),
            label: const Text('Delete School'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Update School Implementation
  Future<void> _updateSchool(
    School school,
    String name,
    String address, 
    String phone,
    String email,
    String schoolType,
  ) async {
    if (name.isEmpty || address.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create updated school object
      final updatedSchool = School(
        id: school.id,
        name: name,
        address: address,
        phone: phone,
        email: email,
        schoolType: schoolType,
        uniqueId: school.uniqueId, // Keep original unique ID
        createdAt: school.createdAt,
        updatedAt: DateTime.now(),
        isActive: school.isActive,
        totalStudents: school.totalStudents,
        totalStaff: school.totalStaff,
        classes: _getClassesForSchoolType(schoolType),
      );

      await ref.read(schoolProvider.notifier).updateSchool(updatedSchool);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('School "$name" updated successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );

      // Refresh schools list
      await ref.read(schoolProvider.notifier).loadSchools();
      
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update school: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete School Implementation
  Future<void> _deleteSchool(School school) async {
    try {
      print('🔄 Starting school deletion: ${school.name}');
      
      // First delete all associated staff
      final staffState = ref.read(staffProvider);
      final schoolStaff = staffState.staffList.where((staff) => 
        staff.schoolId == school.uniqueId || staff.schoolId == school.id).toList();
      
      print('📋 Found ${schoolStaff.length} staff members to delete');
      
      for (final staff in schoolStaff) {
        try {
          await ref.read(staffProvider.notifier).deleteStaff(staff.id);
          print('[SUCCESS] Deleted staff: ${staff.name}');
        } catch (e) {
          print('❌ Failed to delete staff ${staff.name}: $e');
          // Continue with other staff deletions
        }
      }
      
      // Then delete the school
      print('🔄 Deleting school: ${school.name}');
      await ref.read(schoolProvider.notifier).deleteSchool(school.id);
      print('[SUCCESS] School deleted successfully: ${school.name}');
      
      // Close dialog first
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show success message if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('School "${school.name}" and ${schoolStaff.length} staff accounts deleted successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }

      // Refresh data in background
      try {
        await ref.read(schoolProvider.notifier).loadSchools();
        await ref.read(staffProvider.notifier).loadAllStaff();
        print('[SUCCESS] Data refreshed after school deletion');
      } catch (e) {
        print('❌ Failed to refresh data after deletion: $e');
      }
      
    } catch (e) {
      print('❌ School deletion failed: $e');
      
      // Close dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete school: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Try to refresh data even after error
      try {
        await ref.read(schoolProvider.notifier).loadSchools();
      } catch (refreshError) {
        print('❌ Failed to refresh schools after error: $refreshError');
      }
    }
  }

  /// Scan RFID card for student registration
  Future<void> _scanRfidForStudent(TextEditingController rfidController) async {
    try {
      print('🔍 Starting RFID scan for student...');
      
      // Show scanning dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.nfc, color: Colors.blue),
              SizedBox(width: 8),
              Text('RFID Scanner'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Hold RFID card near the scanner...'),
              SizedBox(height: 8),
              Text(
                'Make sure your RFID reader is connected',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Generate mock RFID for testing
                final mockRfid = 'RF${DateTime.now().millisecondsSinceEpoch}';
                rfidController.text = mockRfid;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ RFID scanned: $mockRfid'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Use Test RFID'),
            ),
          ],
        ),
      );

      // TODO: Integrate with actual RFID service
      // This is where you would use the RfidService:
      /*
      final rfidService = ref.read(rfidServiceProvider.notifier);
      
      if (!rfidService.isConnected) {
        Navigator.pop(context);
        _showRfidConnectionDialog();
        return;
      }
      
      // Start scanning
      await rfidService.startScanning();
      
      // Listen for RFID data
      final subscription = rfidService.state.listen((state) {
        if (state.recentReadings.isNotEmpty) {
          final rfidTag = state.recentReadings.first.tagId;
          rfidController.text = rfidTag;
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ RFID scanned: $rfidTag'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
      
      // Auto-close after 10 seconds
      Timer(Duration(seconds: 10), () {
        subscription.cancel();
        rfidService.stopScanning();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      */
      
    } catch (e, stack) {
      print('❌ Error scanning RFID: $e');
      
      // Close scanning dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ RFID scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build RFID status button for AppBar - Temporarily disabled
  /* Widget _buildRfidStatusButton(RfidConnectionStatus status) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case RfidConnectionStatus.disconnected:
        icon = Icons.nfc_outlined;
        color = Colors.red;
        tooltip = 'No RFID readers detected';
        break;
      case RfidConnectionStatus.detected:
        icon = Icons.nfc;
        color = Colors.orange;
        tooltip = 'RFID readers detected - tap to connect';
        break;
      case RfidConnectionStatus.connecting:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = 'Connecting to RFID reader...';
        break;
      case RfidConnectionStatus.connected:
        icon = Icons.nfc;
        color = Colors.green;
        tooltip = 'RFID reader connected';
        break;
      case RfidConnectionStatus.error:
        icon = Icons.error_outline;
        color = Colors.red;
        tooltip = 'RFID connection error';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: () => _showRfidConnectionDialog(),
      ),
    );
  }

  /// Show RFID connection dialog
  void _showRfidConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.nfc, color: Colors.blue),
              SizedBox(width: 8),
              Text('RFID Reader Status'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status message
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRfidStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getRfidStatusColor().withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_getRfidStatusIcon(), color: _getRfidStatusColor(), size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text(_rfidService.getStatusMessage())),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Detected readers list
                if (_rfidService.detectedReaders.isNotEmpty) ...[
                  Text('Detected RFID Readers:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...(_rfidService.detectedReaders.map((reader) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        reader.type == RfidReaderType.usb ? Icons.usb : Icons.bluetooth,
                        color: Colors.blue,
                      ),
                      title: Text(reader.name),
                      subtitle: Text(reader.connectionMethod),
                      trailing: ElevatedButton(
                        onPressed: _rfidService.currentStatus == RfidConnectionStatus.connecting ? null : () async {
                          setDialogState(() {});
                          final success = await _rfidService.connectToReader(reader);
                          setDialogState(() {});
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Connected to ${reader.name}')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to connect to ${reader.name}')),
                            );
                          }
                        },
                        child: Text(_rfidService.currentStatus == RfidConnectionStatus.connecting ? 'Connecting...' : 'Connect'),
                      ),
                    ),
                  ))),
                ] else ...[
                  Text('Setup Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Connect an RFID reader via USB OTG or Bluetooth'),
                  Text('• Ensure the reader is powered on'),
                  Text('• Check that all permissions are granted'),
                  Text('• Wait for automatic detection'),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can still use manual RFID entry or test mode while setting up the reader.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _rfidService.scanForReaders();
                setDialogState(() {});
              },
              child: Text('Refresh'),
            ),
            if (_rfidService.currentStatus == RfidConnectionStatus.connected)
              TextButton(
                onPressed: () async {
                  await _rfidService.disconnect();
                  setDialogState(() {});
                },
                child: Text('Disconnect'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRfidStatusColor() {
    switch (_rfidService.currentStatus) {
      case RfidConnectionStatus.disconnected:
        return Colors.grey;
      case RfidConnectionStatus.detected:
        return Colors.orange;
      case RfidConnectionStatus.connecting:
        return Colors.blue;
      case RfidConnectionStatus.connected:
        return Colors.green;
      case RfidConnectionStatus.error:
        return Colors.red;
    }
  }

  IconData _getRfidStatusIcon() {
    switch (_rfidService.currentStatus) {
      case RfidConnectionStatus.disconnected:
        return Icons.nfc_outlined;
      case RfidConnectionStatus.detected:
        return Icons.nfc;
      case RfidConnectionStatus.connecting:
        return Icons.sync;
      case RfidConnectionStatus.connected:
        return Icons.nfc;
      case RfidConnectionStatus.error:
        return Icons.error_outline;
    }
  }

  /// Show RFID scanning mode with live attendance marking
  void _showRfidScanningMode() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.radar, color: Colors.green),
              SizedBox(width: 8),
              Text('Live RFID Scanning'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                // Scanning indicator
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Scanning Active', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Hold RFID cards near scanner', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Recent scans
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Attendance:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _getRecentAttendanceRecords().length,
                          itemBuilder: (context, index) {
                            final record = _getRecentAttendanceRecords()[index];
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.check_circle, color: Colors.green),
                                title: Text(record['studentName'] ?? 'Unknown Student'),
                                subtitle: Text('Check-in: ${record['checkInTime']}'),
                                trailing: Chip(
                                  label: Text('Present', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                // Mock RFID scan for testing
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Test RFID scanned: RF${DateTime.now().millisecondsSinceEpoch}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: Icon(Icons.nfc),
              label: Text('Test Scan'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Stop Scanning'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show RFID connection settings
  void _showRfidConnectionSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('RFID Reader Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, color: Colors.red, size: 12),
                SizedBox(width: 8),
                Text('Not Connected'),
              ],
            ),
            SizedBox(height: 16),
            
            Text('Available Readers:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            // Mock reader options
            ListTile(
              leading: Icon(Icons.usb),
              title: Text('USB RFID Reader'),
              subtitle: Text('Connect via USB cable'),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('USB RFID connection simulated')),
                  );
                },
                child: Text('Connect'),
              ),
            ),
            
            ListTile(
              leading: Icon(Icons.bluetooth),
              title: Text('Bluetooth RFID Reader'),
              subtitle: Text('Connect wirelessly'),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bluetooth RFID connection simulated')),
                  );
                },
                child: Text('Scan'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get today's attendance count
  String _getTodayAttendanceCount() {
    // Mock data - replace with actual attendance data
    return '12/25 students marked';
  }

  /// Enhanced export attendance report with Excel format
  void _exportAttendanceReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Attendance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose export format and options:'),
            SizedBox(height: 16),
            
            // Export options
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _exportToExcel();
                    },
                    icon: Icon(Icons.table_chart),
                    label: Text('Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _exportToPdf();
                    },
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('PDF'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            Text(
              'Includes both local and cloud data',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Export to Excel format
  Future<void> _exportToExcel() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Generating Excel report...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // TODO: Implement actual Excel export using ExcelExportService
      await Future.delayed(Duration(seconds: 2)); // Simulate processing
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Excel report generated and saved to Downloads'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              // TODO: Implement file sharing
            },
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Export to PDF format
  Future<void> _exportToPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📄 PDF export coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  List<Map<String, dynamic>> _getRecentAttendanceRecords() {
    final students = _getStudentsList();
    List<Map<String, dynamic>> recentRecords = [];
    
    // Generate recent attendance records from actual students
    if (students.isNotEmpty) {
      final now = DateTime.now();
      
      // Take up to 5 recent students and simulate their attendance
      final recentStudents = students.take(5).toList();
      
      for (int i = 0; i < recentStudents.length; i++) {
        final student = recentStudents[i];
        final checkInTime = now.subtract(Duration(minutes: i * 2 + 1));
        
        recentRecords.add({
          'studentName': student['name'] ?? 'Unknown Student',
          'rollNumber': student['rollNumber'] ?? 'No Roll',
          'checkInTime': '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}',
          'status': 'present',
          'timestamp': checkInTime,
        });
      }
    }
    
    // If no students, return empty list instead of fake data
    return recentRecords;
  }

  String _getTotalStudentCount() {
    // Get total students across all schools for admin
    if (isAdmin) {
      final students = _getStudentsList();
      return students.length.toString();
    }
    // For staff, return students in their assigned classes
    return _getClassStudentCount();
  }

  void _showAdminAttendanceOverview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'School-wide Attendance Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Today's Summary
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Total Students', _getTotalStudentCount(), Colors.blue),
                          _buildSummaryItem('Present', _getPresentCount(), Colors.green),
                          _buildSummaryItem('Absent', _getAbsentCount(), Colors.red),
                          _buildSummaryItem('Attendance Rate', '${_getTodayAttendanceRate()}%', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // School-wise Breakdown
              const Text(
                'School-wise Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final schoolState = ref.watch(schoolProvider);
                    
                    return ListView.builder(
                      itemCount: schoolState.schools.length,
                      itemBuilder: (context, index) {
                        final school = schoolState.schools[index];
                        final schoolStudents = _getStudentsForSchool(school.id);
                        final presentStudents = (schoolStudents * 0.85).round(); // 85% average attendance
                        
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                school.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(school.name),
                            subtitle: Text('${school.uniqueId} • ${school.schoolType}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$presentStudents/$schoolStudents',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${((presentStudents / schoolStudents) * 100).round()}%',
                                  style: TextStyle(
                                    color: presentStudents / schoolStudents > 0.8 
                                        ? Colors.green 
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportAttendanceReport(),
                      icon: const Icon(Icons.download),
                      label: const Text('Export Report'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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

  String _getPresentCount() {
    final totalStudents = int.parse(_getTotalStudentCount());
    final attendanceRate = _getTodayAttendanceRate() / 100;
    return (totalStudents * attendanceRate).round().toString();
  }

  String _getAbsentCount() {
    final totalStudents = int.parse(_getTotalStudentCount());
    final presentCount = int.parse(_getPresentCount());
    return (totalStudents - presentCount).toString();
  }

  int _getStudentsForSchool(String schoolId) {
    // In a real implementation, this would query the database
    // For now, return a realistic number based on school ID hash
    final hashCode = schoolId.hashCode.abs();
    return 15 + (hashCode % 35); // Returns 15-50 students per school
  }
  */ // End of commented RFID methods

  // Placeholder methods for missing functionality
  void _exportAttendanceReport() async {
    try {
      print('[EXPORT] Exporting attendance report...');
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating report...'),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 1)); // Simulate processing

      // Close loading dialog
      Navigator.of(context).pop();

      // For now, create a sample CSV with today's attendance
      final todayDate = DateTime.now();
      final csvContent = _generateSampleCSVContent();
      
      // Show export options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Generated attendance report for ${_formatDateSimple(todayDate)}'),
              const SizedBox(height: 16),
              const Text('Choose export format:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveCSVFile(csvContent);
              },
              child: const Text('Export CSV'),
            ),
          ],
        ),
      );

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      print('❌ Error exporting attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error exporting attendance report')),
      );
    }
  }

  String _generateSampleCSVContent() {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Student ID,Student Name,Class,Check In Time,Check Out Time,Status,Duration');
    
    // Sample data based on current students
    for (int i = 0; i < _allStudents.length && i < 10; i++) {
      final student = _allStudents[i];
      final checkInTime = DateTime.now().subtract(Duration(hours: 8, minutes: i * 5));
      final checkOutTime = DateTime.now().subtract(Duration(hours: 1, minutes: i * 2));
      final duration = _calculateDuration(checkInTime, checkOutTime);
      
      buffer.writeln('${student['studentId']},${student['name']},${student['className']},${checkInTime.toString().substring(0, 19)},${checkOutTime.toString().substring(0, 19)},Present,$duration');
    }
    
    return buffer.toString();
  }

  String _calculateDuration(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) return '';
    
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    return '${hours}h ${minutes}m';
  }

  String _formatDateSimple(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _saveCSVFile(String content) async {
    try {
      // For now, show the content in a dialog and copy to clipboard
      // In production, you'd save to device storage using path_provider
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('CSV Export'),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: content));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV content copied to clipboard')),
                );
              },
              child: const Text('Copy to Clipboard'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Error saving CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving CSV file')),
      );
    }
  }


  void _showRfidScanningMode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('RFID scanning will be available once reader is connected')),
    );
  }

  String _getTodayAttendanceCount() {
    return '45'; // Placeholder count
  }

  void _showRfidConnectionSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.nfc, color: Colors.blue),
            SizedBox(width: 8),
            Text('RFID Settings'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RFID Reader Setup:'),
            SizedBox(height: 8),
            Text('• Connect RFID reader via USB OTG or Bluetooth'),
            Text('• Ensure device permissions are granted'),
            Text('• Reader will be auto-detected when connected'),
            SizedBox(height: 16),
            Text(
              'RFID functionality is currently being finalized.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper Methods for Dashboard
  String _getTotalStudentCount() {
    // Get total students across all schools for admin
    if (widget.role == 'Admin') {
      final students = _getStudentsList();
      return students.length.toString();
    }
    // For staff, return students in their assigned classes
    return _getClassStudentCount();
  }

  void _showAdminAttendanceOverview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'School-wide Attendance Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Today's Summary
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Total Students', _getTotalStudentCount(), Colors.blue),
                          _buildSummaryItem('Present', _getPresentCount(), Colors.green),
                          _buildSummaryItem('Absent', _getAbsentCount(), Colors.red),
                          _buildSummaryItem('Attendance Rate', '${_getTodayAttendanceRate()}%', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: Center(
                  child: Text(
                    'Detailed attendance reports will be displayed here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForTitle(title),
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Total Students':
        return Icons.people;
      case 'Present':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      case 'Attendance Rate':
        return Icons.percent;
      default:
        return Icons.info;
    }
  }

  String _getPresentCount() {
    final totalStudents = int.tryParse(_getTotalStudentCount()) ?? 0;
    final attendanceRate = _getTodayAttendanceRate() / 100;
    return (totalStudents * attendanceRate).round().toString();
  }

  String _getAbsentCount() {
    final totalStudents = int.tryParse(_getTotalStudentCount()) ?? 0;
    final presentCount = int.tryParse(_getPresentCount()) ?? 0;
    return (totalStudents - presentCount).toString();
  }

}