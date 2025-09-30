import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/splash/splash_screen.dart';

/// Main app widget with routing and theme configuration
class SmartAttendanceApp extends ConsumerWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Smart Attendance',
      theme: AppTheme.lightTheme,
      home: _getInitialScreen(ref),
      debugShowCheckedModeBanner: false,
      
      // Global navigator key for navigation from services
      navigatorKey: _AppNavigator.navigatorKey,
      
      // Route configuration
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      
      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
        );
      },
    );
  }
  
  /// Determine initial screen based on auth state
  Widget _getInitialScreen(WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    
    // Show splash screen while loading
    if (authState.isLoading) {
      return const SplashScreen();
    }
    
    // Show dashboard if authenticated
    if (authState.isAuthenticated && authState.user != null) {
      return const DashboardScreen();
    }
    
    // Show login screen if not authenticated
    return const LoginScreen();
  }
}

/// Global navigator for service-level navigation
class _AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  /// Navigate to named route
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }
  
  /// Replace current route
  static Future<T?> pushReplacementNamed<T>(String routeName, {Object? arguments}) {
    return navigator!.pushReplacementNamed<T>(routeName, arguments: arguments);
  }
  
  /// Clear stack and navigate
  static Future<T?> pushNamedAndClearStack<T>(String routeName, {Object? arguments}) {
    return navigator!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  /// Go back
  static void pop<T>([T? result]) {
    navigator!.pop<T>(result);
  }
  
  /// Show snackbar
  static void showSnackBar(String message, {bool isError = false}) {
    final context = navigator!.context;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Show dialog
  static Future<T?> showAppDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: navigator!.context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }
  
  /// Show bottom sheet
  static Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: navigator!.context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }
}

/// 404 Not Found screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '404',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global app navigator instance
final appNavigator = _AppNavigator();