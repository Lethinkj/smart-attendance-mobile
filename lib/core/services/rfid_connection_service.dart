import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:usb_serial/usb_serial.dart';
import '../utils/logger.dart';

/// Service to detect and manage RFID reader connections
/// Supports both USB and Bluetooth RFID readers
class RfidConnectionService {
  static RfidConnectionService? _instance;
  static RfidConnectionService get instance => _instance ??= RfidConnectionService._();
  
  RfidConnectionService._();

  // Connection status streams
  final _connectionStatusController = StreamController<RfidConnectionStatus>.broadcast();
  Stream<RfidConnectionStatus> get connectionStatus => _connectionStatusController.stream;

  // Current connection status
  RfidConnectionStatus _currentStatus = RfidConnectionStatus.disconnected;
  RfidConnectionStatus get currentStatus => _currentStatus;

  // Detected readers
  List<RfidReaderDevice> _detectedReaders = [];
  List<RfidReaderDevice> get detectedReaders => List.unmodifiable(_detectedReaders);

  Timer? _scanTimer;
  bool _isScanning = false;

  /// Initialize the RFID connection service
  Future<void> initialize() async {
    try {
      Logger.info('Initializing RFID connection service...');
      
      // Start periodic scanning for RFID readers
      startPeriodicScan();
      
      Logger.info('RFID connection service initialized');
    } catch (e, stack) {
      Logger.error('RfidConnectionService', 'Initialization failed', e, stack);
    }
  }

  /// Start periodic scanning for RFID readers
  void startPeriodicScan() {
    if (_isScanning) return;
    
    _isScanning = true;
    Logger.info('Starting periodic RFID reader scan...');
    
    // Scan immediately
    scanForReaders();
    
    // Then scan every 10 seconds
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      scanForReaders();
    });
  }

  /// Stop periodic scanning
  void stopPeriodicScan() {
    _isScanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    Logger.info('Stopped periodic RFID reader scan');
  }

  /// Scan for available RFID readers
  Future<void> scanForReaders() async {
    try {
      final previousCount = _detectedReaders.length;
      _detectedReaders.clear();

      // Scan for USB RFID readers
      await _scanUsbReaders();
      
      // Scan for Bluetooth RFID readers
      await _scanBluetoothReaders();

      // Update connection status
      if (_detectedReaders.isNotEmpty) {
        if (_currentStatus == RfidConnectionStatus.disconnected) {
          _updateConnectionStatus(RfidConnectionStatus.detected);
        }
      } else {
        if (_currentStatus != RfidConnectionStatus.disconnected) {
          _updateConnectionStatus(RfidConnectionStatus.disconnected);
        }
      }

      // Log changes
      if (_detectedReaders.length != previousCount) {
        Logger.info('RFID readers detected: ${_detectedReaders.length}');
        for (var reader in _detectedReaders) {
          Logger.info('  - ${reader.name} (${reader.type.name}) - ${reader.connectionMethod}');
        }
      }

    } catch (e, stack) {
      Logger.error('RfidConnectionService', 'Reader scan failed', e, stack);
    }
  }

  /// Scan for USB RFID readers
  Future<void> _scanUsbReaders() async {
    try {
      final usbDevices = await UsbSerial.listDevices();
      
      for (var device in usbDevices) {
        // Check if device might be an RFID reader based on vendor ID or product name
        if (_isLikelyRfidReader(device)) {
          _detectedReaders.add(RfidReaderDevice(
            id: 'usb_${device.deviceId}',
            name: device.productName ?? 'USB RFID Reader',
            type: RfidReaderType.usb,
            connectionMethod: 'USB OTG',
            deviceInfo: {
              'vendorId': device.vid,
              'productId': device.pid,
              'deviceId': device.deviceId,
              'productName': device.productName,
              'manufacturerName': device.manufacturerName,
            },
          ));
        }
      }
    } catch (e) {
      Logger.warning('USB scan failed: $e');
    }
  }

  /// Scan for Bluetooth RFID readers
  Future<void> _scanBluetoothReaders() async {
    try {
      // Check if Bluetooth is available
      final isAvailable = await FlutterBluetoothSerial.instance.isAvailable ?? false;
      if (!isAvailable) return;

      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (!isEnabled) return;

      // Get bonded devices
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      for (var device in bondedDevices) {
        // Check if device might be an RFID reader based on name
        if (_isLikelyBluetoothRfidReader(device)) {
          _detectedReaders.add(RfidReaderDevice(
            id: 'bt_${device.address}',
            name: device.name ?? 'Bluetooth RFID Reader',
            type: RfidReaderType.bluetooth,
            connectionMethod: 'Bluetooth Classic',
            deviceInfo: {
              'address': device.address,
              'name': device.name,
              'type': device.type.toString(),
              'isConnected': device.isConnected,
            },
          ));
        }
      }
    } catch (e) {
      Logger.warning('Bluetooth scan failed: $e');
    }
  }

  /// Check if USB device is likely an RFID reader
  bool _isLikelyRfidReader(UsbDevice device) {
    final productName = (device.productName ?? '').toLowerCase();
    final manufacturerName = (device.manufacturerName ?? '').toLowerCase();
    
    // Common RFID reader indicators
    final rfidKeywords = [
      'rfid', 'reader', 'card', 'tag', 'nfc', 
      'mifare', 'proximity', 'access', 'hid',
      'em4100', 'em4102', '125khz', '13.56mhz'
    ];
    
    // Common RFID reader manufacturers
    final rfidManufacturers = [
      'elatec', 'acs', 'omnikey', 'cherry', 
      'identiv', 'hid', 'gemalto', 'bit4id'
    ];
    
    return rfidKeywords.any((keyword) => 
      productName.contains(keyword) || manufacturerName.contains(keyword)
    ) || rfidManufacturers.any((manufacturer) => 
      manufacturerName.contains(manufacturer)
    );
  }

  /// Check if Bluetooth device is likely an RFID reader
  bool _isLikelyBluetoothRfidReader(BluetoothDevice device) {
    final name = (device.name ?? '').toLowerCase();
    
    // Common Bluetooth RFID reader names
    final rfidNames = [
      'rfid', 'reader', 'card reader', 'tag reader',
      'nfc', 'mifare', 'proximity', 'access reader',
      'hid', 'prox', 'badge'
    ];
    
    return rfidNames.any((rfidName) => name.contains(rfidName));
  }

  /// Connect to a specific RFID reader
  Future<bool> connectToReader(RfidReaderDevice reader) async {
    try {
      Logger.info('Attempting to connect to RFID reader: ${reader.name}');
      
      _updateConnectionStatus(RfidConnectionStatus.connecting);
      
      bool connected = false;
      
      switch (reader.type) {
        case RfidReaderType.usb:
          connected = await _connectUsbReader(reader);
          break;
        case RfidReaderType.bluetooth:
          connected = await _connectBluetoothReader(reader);
          break;
      }
      
      if (connected) {
        _updateConnectionStatus(RfidConnectionStatus.connected);
        Logger.info('Successfully connected to RFID reader: ${reader.name}');
      } else {
        _updateConnectionStatus(RfidConnectionStatus.error);
        Logger.warning('Failed to connect to RFID reader: ${reader.name}');
      }
      
      return connected;
    } catch (e, stack) {
      Logger.error('RfidConnectionService', 'Connection failed', e, stack);
      _updateConnectionStatus(RfidConnectionStatus.error);
      return false;
    }
  }

  /// Connect to USB RFID reader
  Future<bool> _connectUsbReader(RfidReaderDevice reader) async {
    try {
      // Implementation would depend on specific USB RFID reader protocol
      // This is a placeholder for USB connection logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate connection time
      return true;
    } catch (e) {
      Logger.error('RfidConnectionService', 'USB connection failed', e);
      return false;
    }
  }

  /// Connect to Bluetooth RFID reader
  Future<bool> _connectBluetoothReader(RfidReaderDevice reader) async {
    try {
      final address = reader.deviceInfo['address'] as String;
      // Implementation would depend on specific Bluetooth RFID reader protocol
      // This is a placeholder for Bluetooth connection logic
      await Future.delayed(const Duration(seconds: 3)); // Simulate connection time
      return true;
    } catch (e) {
      Logger.error('RfidConnectionService', 'Bluetooth connection failed', e);
      return false;
    }
  }

  /// Disconnect from current RFID reader
  Future<void> disconnect() async {
    try {
      Logger.info('Disconnecting from RFID reader...');
      _updateConnectionStatus(RfidConnectionStatus.disconnected);
      Logger.info('Disconnected from RFID reader');
    } catch (e, stack) {
      Logger.error('RfidConnectionService', 'Disconnect failed', e, stack);
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(RfidConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _connectionStatusController.add(status);
      Logger.info('RFID connection status changed to: ${status.name}');
    }
  }

  /// Get user-friendly connection status message
  String getStatusMessage() {
    switch (_currentStatus) {
      case RfidConnectionStatus.disconnected:
        return _detectedReaders.isEmpty 
          ? 'No RFID readers detected. Please connect a USB or Bluetooth RFID reader.'
          : 'RFID readers detected but not connected. Tap to connect.';
      case RfidConnectionStatus.detected:
        return '${_detectedReaders.length} RFID reader(s) detected. Tap to connect.';
      case RfidConnectionStatus.connecting:
        return 'Connecting to RFID reader...';
      case RfidConnectionStatus.connected:
        return 'RFID reader connected and ready.';
      case RfidConnectionStatus.error:
        return 'RFID reader connection error. Please check device and try again.';
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopPeriodicScan();
    await _connectionStatusController.close();
  }
}

/// RFID connection status
enum RfidConnectionStatus {
  disconnected,
  detected,
  connecting,
  connected,
  error,
}

/// RFID reader type
enum RfidReaderType {
  usb,
  bluetooth,
}

/// RFID reader device information
class RfidReaderDevice {
  final String id;
  final String name;
  final RfidReaderType type;
  final String connectionMethod;
  final Map<String, dynamic> deviceInfo;

  const RfidReaderDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.connectionMethod,
    required this.deviceInfo,
  });
}