import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'utils/logger.dart';

/// Main application widget with routing, theming, and global state management
class SmartAttendanceApp extends ConsumerWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authServiceProvider);
    
    return MaterialApp.router(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: AppConfig.isDevelopment,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Routing
      routerConfig: router,
      
      // Localization
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('hi', 'IN'),
      ],
      
      // Global error handling
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          Logger.error('Widget Error', details.exception, details.stack);
          
          return Material(
            child: Container(
              color: Colors.red.shade50,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (AppConfig.isDevelopment)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          details.exception.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        };
        
        return child ?? const SizedBox.shrink();
      },
    );
  }
}