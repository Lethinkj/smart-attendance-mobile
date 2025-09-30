import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Service to handle Android runtime permissions
class PermissionService {
  static bool _initialized = false;

  /// Initialize and request all required permissions
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      Logger.info('Requesting Android permissions...');

      // List of essential permissions for attendance system
      final criticalPermissions = [
        Permission.storage,                    // For offline data storage
        Permission.manageExternalStorage,      // For Android 11+ storage access
        Permission.ignoreBatteryOptimizations, // For background data sync
      ];

      final optionalPermissions = [
        Permission.bluetoothConnect,           // For Bluetooth RFID devices
        Permission.bluetoothScan,              // For Bluetooth device discovery
        Permission.bluetoothAdvertise,         // For Bluetooth advertising
        Permission.notification,               // For attendance notifications
        Permission.camera,                     // For QR code scanning (optional)
        Permission.microphone,                 // For voice attendance (optional)
        Permission.nearbyWifiDevices,          // For nearby device detection
        // Note: Location not needed with neverForLocation flag in manifest
      ];

      final allPermissions = [...criticalPermissions, ...optionalPermissions];

      // Request all permissions
      Map<Permission, PermissionStatus> statuses = await allPermissions.request();

      // Check results
      bool allGranted = true;
      for (var entry in statuses.entries) {
        final permission = entry.key;
        final status = entry.value;
        
        Logger.info('Permission ${permission.toString()}: ${status.toString()}');
        
        if (status.isDenied || status.isPermanentlyDenied) {
          if (criticalPermissions.contains(permission)) {
            // Critical permissions for persistent authentication and background sync
            allGranted = false;
            Logger.warning('Critical permission denied: ${permission.toString()}');
          } else {
            // Non-critical permissions (Bluetooth, notifications, camera) - warn but don't block
            Logger.warning('Optional permission denied: ${permission.toString()}');
          }
        }
      }

      // Special handling for battery optimization
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        Logger.info('Requesting battery optimization whitelist...');
        await Permission.ignoreBatteryOptimizations.request();
      }

      _initialized = true;
      Logger.info('Permission initialization completed. All critical permissions granted: $allGranted');
      return allGranted;

    } catch (e, stack) {
      Logger.error('PermissionService', 'Permission request failed', e, stack);
      return false;
    }
  }

  /// Check if all critical permissions are granted
  static Future<bool> checkCriticalPermissions() async {
    try {
      final storage = await Permission.storage.isGranted;
      final batteryOptim = await Permission.ignoreBatteryOptimizations.isGranted;
      
      return storage && batteryOptim;
    } catch (e) {
      Logger.error('PermissionService', 'Permission check failed', e);
      return false;
    }
  }

  /// Show permission dialog to user
  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismissing
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('Optional Permissions'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Smart Attendance needs these essential permissions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                _PermissionItem(
                  icon: Icons.storage,
                  title: 'Storage Access',
                  description: 'Store attendance data and login credentials offline',
                ),
                _PermissionItem(
                  icon: Icons.battery_saver,
                  title: 'Background Data Access',
                  description: 'Auto-sync attendance data and maintain persistent login',
                ),
                _PermissionItem(
                  icon: Icons.usb,
                  title: 'Device Access',
                  description: 'Connect to USB/Bluetooth attendance devices (no location needed)',
                ),
                SizedBox(height: 12),
                Text(
                  'These permissions ensure the app remembers your login and works offline.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await initialize();
              },
              child: const Text('Grant Permissions'),
            ),
          ],
        );
      },
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}