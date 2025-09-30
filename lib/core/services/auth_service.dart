import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'offline_sync_service.dart';

/// Authentication service for admin and staff login
/// Handles JWT tokens and user session management
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  static const String _refreshTokenKey = 'refresh_token';
  
  static User? _currentUser;
  static String? _accessToken;
  static String? _refreshToken;
  static Timer? _tokenRefreshTimer;
  
  static final Dio _dio = Dio();
  
  // Stream controllers for auth state changes
  static final StreamController<User?> _authStateController = 
      StreamController<User?>.broadcast();
  
  /// Stream of authentication state changes
  static Stream<User?> get authStateChanges => _authStateController.stream;
  
  /// Current authenticated user
  static User? get currentUser => _currentUser;
  
  /// Whether user is authenticated
  static bool get isAuthenticated => _currentUser != null && _accessToken != null;
  
  /// Whether current user is admin
  static bool get isAdmin => _currentUser?.role == UserRole.admin;
  
  /// Whether current user is staff
  static bool get isStaff => _currentUser?.role == UserRole.staff;
  
  /// Current access token
  static String? get accessToken => _accessToken;
  
  /// Initialize auth service and restore session
  static Future<void> initialize() async {
    try {
      await _restoreSession();
      Logger.info('AuthService initialized');
    } catch (e, stack) {
      Logger.error('AuthService', 'Failed to initialize AuthService', e, stack);
    }
  }

  /// Check if user can login offline with cached credentials
  static Future<LoginResult> loginOffline({
    required String email,
    required String password,
  }) async {
    try {
      final storedCredentials = StorageService.getUserCredentials();
      final storedUser = StorageService.getCurrentUser();
      
      if (storedCredentials != null && storedUser != null) {
        final storedEmail = storedCredentials['email'] as String?;
        final storedPassword = storedCredentials['password'] as String?;
        
        if (storedEmail == email && storedPassword == password) {
          // Valid offline login
          final user = User.fromJson(storedUser);
          
          _currentUser = user;
          _accessToken = 'offline_token'; // Placeholder token for offline mode
          
          // Notify auth state change
          _authStateController.add(_currentUser);
          
          Logger.info('Offline login successful for: ${user.email}');
          return LoginResult.success(user);
        }
      }
      
      return LoginResult.failure('No cached credentials found or credentials mismatch');
    } catch (e, stack) {
      Logger.error('AuthService', 'Offline login error', e, stack);
      return LoginResult.failure('Offline login failed');
    }
  }
  
  /// Login with email and password (offline-first)
  static Future<LoginResult> login({
    required String email,
    required String password,
    String? schoolId, // Required for staff, optional for admin
  }) async {
    try {
      Logger.info('Attempting login for: $email');
      
      // First try online login
      try {
        final response = await _dio.post(
          '/api/auth/login',
          data: {
            'email': email,
            'password': password,
            if (schoolId != null) 'schoolId': schoolId,
          },
          options: Options(
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        
        if (response.statusCode == 200) {
          final data = response.data;
          
          // Parse user and tokens
          final user = User.fromJson(data['user']);
          final accessToken = data['accessToken'] as String;
          final refreshToken = data['refreshToken'] as String?;
          
          // Save session and credentials for offline use
          await _saveSession(user, accessToken, refreshToken);
          await StorageService.saveUserCredentials(email, password);
          await StorageService.saveCurrentUser(data['user']);
          
          // Set current user
          _currentUser = user;
          _accessToken = accessToken;
          _refreshToken = refreshToken;
          
          // Start token refresh timer
          _startTokenRefreshTimer();
          
          // Notify auth state change
          _authStateController.add(_currentUser);
          
          Logger.info('Online login successful for: ${user.email}');
          return LoginResult.success(user);
        } else {
          return LoginResult.failure('Invalid credentials');
        }
      } on DioException catch (e) {
        Logger.warning('Online login failed, trying offline: ${e.message}');
        
        // If online login fails due to network, try offline login
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          return await loginOffline(email: email, password: password);
        } else if (e.response?.statusCode == 401) {
          return LoginResult.failure('Invalid credentials');
        } else if (e.response?.statusCode == 403) {
          return LoginResult.failure('Account access denied');
        } else {
          // Try offline login as fallback
          return await loginOffline(email: email, password: password);
        }
      }
    } catch (e, stack) {
      Logger.error('AuthService', 'Login error', e, stack);
      
      // Try offline login as last resort
      try {
        return await loginOffline(email: email, password: password);
      } catch (offlineError) {
        return LoginResult.failure('Login failed. Please check your connection.');
      }
    }
  }
  
  /// Logout current user
  static Future<void> logout() async {
    try {
      // Cancel token refresh timer
      _tokenRefreshTimer?.cancel();
      
      // Call logout endpoint if we have a token
      if (_accessToken != null) {
        try {
          await _dio.post(
            '/api/auth/logout',
            options: Options(
              headers: {'Authorization': 'Bearer $_accessToken'},
            ),
          );
        } catch (e) {
          // Ignore logout endpoint errors
          Logger.warning('Logout endpoint error (ignored): $e');
        }
      }
      
      // Clear session data
      await _clearSession();
      
      // Reset state
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      
      // Notify auth state change
      _authStateController.add(null);
      
      Logger.info('Logout successful');
    } catch (e, stack) {
      Logger.error('AuthService', 'Logout error', e, stack);
    }
  }
  
  /// Refresh access token
  static Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String?;
        
        // Update tokens
        _accessToken = newAccessToken;
        if (newRefreshToken != null) {
          _refreshToken = newRefreshToken;
        }
        
        // Save updated session
        if (_currentUser != null) {
          await _saveSession(_currentUser!, _accessToken!, _refreshToken);
        }
        
        Logger.info('Token refresh successful');
        return true;
      }
    } catch (e) {
      Logger.error('AuthService', 'Token refresh failed', e);
    }
    
    return false;
  }
  
  /// Change password (offline-first)
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) return false;
    
    try {
      // First try online password change
      try {
        final response = await _dio.post(
          '/api/auth/change-password',
          data: {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $_accessToken'},
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        
        if (response.statusCode == 200) {
          // Update local credentials immediately
          await StorageService.updateUserPassword(newPassword);
          Logger.info('Password changed successfully (online)');
          return true;
        }
      } on DioException catch (e) {
        Logger.warning('Online password change failed, saving offline: ${e.message}');
        
        // If online change fails, save locally and sync later
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          
          // Verify current password against stored credentials
          final storedCredentials = StorageService.getUserCredentials();
          if (storedCredentials != null) {
            final storedPassword = storedCredentials['password'] as String?;
            if (storedPassword == currentPassword) {
              // Update local password
              await StorageService.updateUserPassword(newPassword);
              
              // Mark for sync when online
              await _markPasswordChangeForSync(currentPassword, newPassword);
              
              Logger.info('Password changed successfully (offline - will sync)');
              return true;
            } else {
              Logger.error('AuthService', 'Current password verification failed');
              return false;
            }
          }
        }
      }
      
      return false;
    } catch (e, stack) {
      Logger.error('AuthService', 'Password change error', e, stack);
      return false;
    }
  }

  /// Mark password change for sync when online
  static Future<void> _markPasswordChangeForSync(String oldPassword, String newPassword) async {
    try {
      // Store pending password change for sync
      await StorageService.savePendingPasswordChange({
        'old_password': oldPassword,
        'new_password': newPassword,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': _currentUser?.id,
        'sync_status': 'pending',
      });
    } catch (e, stack) {
      Logger.error('AuthService', 'Failed to mark password change for sync', e, stack);
    }
  }
  
  /// Reset password (send reset email)
  static Future<bool> resetPassword(String email) async {
    try {
      final response = await _dio.post(
        '/api/auth/reset-password',
        data: {'email': email},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      Logger.error('AuthService', 'Password reset failed', e);
      return false;
    }
  }
  
  /// Validate current session
  static Future<bool> validateSession() async {
    if (!isAuthenticated) return false;
    
    try {
      final response = await _dio.get(
        '/api/auth/validate',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      Logger.warning('Session validation failed: $e');
      
      // Try to refresh token
      if (await refreshToken()) {
        return await validateSession();
      }
      
      // If refresh fails, logout
      await logout();
      return false;
    }
  }
  
  /// Save session to storage
  static Future<void> _saveSession(User user, String accessToken, String? refreshToken) async {
    try {
      await StorageService.setSetting(_userKey, user.toJson());
      await StorageService.setSetting(_tokenKey, accessToken);
      if (refreshToken != null) {
        await StorageService.setSetting(_refreshTokenKey, refreshToken);
      }
    } catch (e, stack) {
      Logger.error('AuthService', 'Failed to save session', e, stack);
    }
  }
  
  /// Restore session from storage (offline-first)
  static Future<void> _restoreSession() async {
    try {
      // Check if user was logged in
      if (StorageService.isLoggedIn) {
        final storedUser = StorageService.getCurrentUser();
        final token = StorageService.accessToken;
        final refreshToken = StorageService.refreshToken;
        
        if (storedUser != null) {
          _currentUser = User.fromJson(storedUser);
          _accessToken = token ?? 'offline_token'; // Use offline token if no real token
          _refreshToken = refreshToken;
          
          // Try to validate session online, but don't fail if offline
          try {
            final isValid = await validateSession();
            if (isValid && token != null) {
              _startTokenRefreshTimer();
              Logger.info('Online session restored for: ${_currentUser!.email}');
            } else {
              Logger.info('Offline session restored for: ${_currentUser!.email}');
            }
          } catch (e) {
            // Continue with offline session
            Logger.info('Continuing with offline session for: ${_currentUser!.email}');
          }
          
          // Notify auth state change
          _authStateController.add(_currentUser);
          return;
        }
      }
      
      // Fallback to old session restoration method
      final userJson = StorageService.getSetting<Map<String, dynamic>>(_userKey);
      final token = StorageService.getSetting<String>(_tokenKey);
      final refreshToken = StorageService.getSetting<String>(_refreshTokenKey);
      
      if (userJson != null && token != null) {
        _currentUser = User.fromJson(userJson);
        _accessToken = token;
        _refreshToken = refreshToken;
        
        // Try to validate session online
        try {
          final isValid = await validateSession();
          if (isValid) {
            _startTokenRefreshTimer();
            _authStateController.add(_currentUser);
            Logger.info('Legacy session restored for: ${_currentUser!.email}');
          } else {
            await _clearSession();
          }
        } catch (e) {
          // Continue offline if validation fails
          _authStateController.add(_currentUser);
          Logger.info('Legacy offline session restored for: ${_currentUser!.email}');
        }
      }
    } catch (e, stack) {
      Logger.error('AuthService', 'Failed to restore session', e, stack);
      await _clearSession();
    }
  }
  
  /// Clear session from storage
  static Future<void> _clearSession() async {
    try {
      await StorageService.deleteSetting(_userKey);
      await StorageService.deleteSetting(_tokenKey);
      await StorageService.deleteSetting(_refreshTokenKey);
    } catch (e, stack) {
      Logger.error('AuthService', 'Failed to clear session', e, stack);
    }
  }
  
  /// Start token refresh timer
  static void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    
    // Refresh token every 45 minutes (assuming 1 hour expiry)
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 45),
      (_) async {
        final success = await refreshToken();
        if (!success) {
          Logger.warning('Token refresh failed, logging out');
          await logout();
        }
      },
    );
  }
  
  /// Check if user has permission for operation
  static bool hasPermission(Permission permission) {
    if (!isAuthenticated) return false;
    
    switch (permission) {
      case Permission.manageSchools:
      case Permission.manageUsers:
      case Permission.viewAllStats:
        return isAdmin;
        
      case Permission.manageStudents:
      case Permission.markAttendance:
      case Permission.viewClassStats:
        return isStaff || isAdmin;
        
      case Permission.viewOwnProfile:
        return true;
    }
  }
  
  /// Dispose auth service
  static void dispose() {
    _tokenRefreshTimer?.cancel();
    _authStateController.close();
  }
}

/// Login result wrapper
class LoginResult {
  final bool success;
  final String? message;
  final User? user;
  
  const LoginResult._({
    required this.success,
    this.message,
    this.user,
  });
  
  factory LoginResult.success(User user) => LoginResult._(
    success: true,
    user: user,
  );
  
  factory LoginResult.failure(String message) => LoginResult._(
    success: false,
    message: message,
  );
}

/// Permission enumeration
enum Permission {
  manageSchools,
  manageUsers,
  manageStudents,
  markAttendance,
  viewAllStats,
  viewClassStats,
  viewOwnProfile,
}

/// Riverpod provider for auth service
final authServiceProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Auth state notifier for Riverpod
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _init();
  }
  
  void _init() {
    // Listen to auth state changes
    AuthService.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    });
  }
  
  Future<LoginResult> login({
    required String email,
    required String password,
    String? schoolId,
  }) async {
    state = AuthState.loading();
    final result = await AuthService.login(
      email: email,
      password: password,
      schoolId: schoolId,
    );
    return result;
  }
  
  Future<void> logout() async {
    state = AuthState.loading();
    await AuthService.logout();
  }
}

/// Auth state for Riverpod
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;
  
  const AuthState._({
    required this.isLoading,
    required this.isAuthenticated,
    this.user,
    this.error,
  });
  
  factory AuthState.initial() => const AuthState._(
    isLoading: true,
    isAuthenticated: false,
  );
  
  factory AuthState.loading() => const AuthState._(
    isLoading: true,
    isAuthenticated: false,
  );
  
  factory AuthState.authenticated(User user) => AuthState._(
    isLoading: false,
    isAuthenticated: true,
    user: user,
  );
  
  factory AuthState.unauthenticated() => const AuthState._(
    isLoading: false,
    isAuthenticated: false,
  );
  
  factory AuthState.error(String error) => AuthState._(
    isLoading: false,
    isAuthenticated: false,
    error: error,
  );
}