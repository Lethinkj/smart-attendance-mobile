import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/app_config.dart';
import '../../utils/logger.dart';
import 'rfid_reader_interface.dart';

/// Bluetooth Low Energy (BLE GATT) RFID Reader Implementation
/// Supports modern BLE-based RFID readers with GATT characteristics
/// 
/// Features:
/// - BLE device discovery and filtering
/// - GATT service and characteristic management
/// - Notification handling for tag events
/// - Battery level monitoring
/// - Background reconnection support
/// - Multiple encoding support (UTF-8, hex, binary)
class BluetoothLowEnergyRfidReader implements RfidReaderInterface {
  static const String _logTag = 'BleRfidReader';
  
  // BLE connection
  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _tagDataCharacteristic;
  BluetoothCharacteristic? _batteryCharacteristic;
  BluetoothCharacteristic? _controlCharacteristic;
  
  // Stream controllers
  final StreamController<RfidTagReading> _tagReadingsController = 
      StreamController<RfidTagReading>.broadcast();
  final StreamController<RfidConnectionStatus> _connectionStatusController = 
      StreamController<RfidConnectionStatus>.broadcast();
  
  // State management
  RfidConnectionStatus _currentStatus = RfidConnectionStatus.disconnected;
  bool _isScanning = false;
  bool _isDisposed = false;
  
  // Configuration
  final BleRfidConfig _config;
  
  // Reader information
  late RfidReaderInfo _readerInfo;
  
  // Subscriptions
  final List<StreamSubscription> _subscriptions = [];
  
  BluetoothLowEnergyRfidReader({BleRfidConfig? config})
      : _config = config ?? BleRfidConfig.defaultConfig() {
    
    _readerInfo = RfidReaderInfo(
      name: _config.deviceName ?? 'BLE RFID Reader',
      type: RfidReaderType.bluetoothLowEnergy,
      hardwareId: _config.deviceAddress,
      supportedTagTypes: ['ISO14443A', 'ISO14443B', 'ISO15693', 'MIFARE', 'NTAG'],
      capabilities: ['read_uid', 'read_ndef', 'battery_level', 'notifications'],
      connectionParams: _config.toMap(),
    );
  }
  
  @override
  Stream<RfidTagReading> get tagReadings => _tagReadingsController.stream;
  
  @override
  Stream<RfidConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  
  @override
  RfidConnectionStatus get currentStatus => _currentStatus;
  
  @override
  bool get isScanning => _isScanning;
  
  @override
  bool get isConnected => _targetDevice?.isConnected ?? false;
  
  @override
  RfidReaderInfo get readerInfo => _readerInfo;
  
  @override
  Future<void> initialize() async {
    Logger.info(_logTag, 'Initializing BLE RFID reader');
    
    try {
      // Check if BLE is supported
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        throw const RfidReaderException(
          'Bluetooth Low Energy is not supported on this device',
          readerType: RfidReaderType.bluetoothLowEnergy,
          errorCode: 'BLE_NOT_SUPPORTED',
        );
      }
      
      // Check permissions
      await _requestPermissions();
      
      // Check if Bluetooth is on
      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        throw const RfidReaderException(
          'Bluetooth must be enabled to use BLE RFID reader',
          readerType: RfidReaderType.bluetoothLowEnergy,
          errorCode: 'BLUETOOTH_DISABLED',
        );
      }
      
      Logger.info(_logTag, 'BLE RFID reader initialized successfully');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to initialize BLE RFID reader', e, stack);
      _updateStatus(RfidConnectionStatus.error);
      rethrow;
    }
  }
  
  @override
  Future<void> connect() async {
    if (_isDisposed) return;
    
    Logger.info(_logTag, 'Connecting to BLE RFID reader');
    _updateStatus(RfidConnectionStatus.connecting);
    
    try {
      // Find target device
      if (_targetDevice == null) {
        await _discoverDevice();
      }
      
      if (_targetDevice == null) {
        throw const RfidReaderException(
          'BLE RFID reader device not found',
          readerType: RfidReaderType.bluetoothLowEnergy,
          errorCode: 'DEVICE_NOT_FOUND',
        );
      }
      
      // Connect to device
      await _targetDevice!.connect(timeout: AppConfig.bluetoothConnectionTimeout);
      
      // Discover services and characteristics
      await _discoverServices();
      
      // Setup notifications
      await _setupNotifications();
      
      // Setup connection state monitoring
      _setupConnectionMonitoring();
      
      _updateStatus(RfidConnectionStatus.connected);
      Logger.info(_logTag, 'Successfully connected to ${_targetDevice!.name}');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to connect to BLE RFID reader', e, stack);
      _updateStatus(RfidConnectionStatus.error);
      await _cleanup();
      throw RfidReaderException(
        'Failed to connect to BLE RFID reader: $e',
        readerType: RfidReaderType.bluetoothLowEnergy,
        originalError: e,
      );
    }
  }
  
  @override
  Future<void> disconnect() async {
    Logger.info(_logTag, 'Disconnecting from BLE RFID reader');
    
    await stopScanning();
    await _cleanup();
    _updateStatus(RfidConnectionStatus.disconnected);
    
    Logger.info(_logTag, 'Disconnected from BLE RFID reader');
  }
  
  @override
  Future<void> startScanning() async {
    if (_isDisposed || !isConnected) {
      throw const RfidReaderException(
        'Cannot start scanning: reader not connected',
        readerType: RfidReaderType.bluetoothLowEnergy,
        errorCode: 'NOT_CONNECTED',
      );
    }
    
    if (_isScanning) return;
    
    Logger.info(_logTag, 'Starting BLE RFID tag scanning');
    _isScanning = true;
    _updateStatus(RfidConnectionStatus.scanning);
    
    // Send scan command if available
    if (_controlCharacteristic != null && _config.scanCommand != null) {
      try {
        await _controlCharacteristic!.write(_config.scanCommand!);
        Logger.info(_logTag, 'Scan command sent');
      } catch (e) {
        Logger.error(_logTag, 'Failed to send scan command', e);
      }
    }
  }
  
  @override
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    
    Logger.info(_logTag, 'Stopping BLE RFID tag scanning');
    _isScanning = false;
    
    // Send stop command if available
    if (_controlCharacteristic != null && _config.stopCommand != null) {
      try {
        await _controlCharacteristic!.write(_config.stopCommand!);
        Logger.info(_logTag, 'Stop command sent');
      } catch (e) {
        Logger.error(_logTag, 'Failed to send stop command', e);
      }
    }
    
    if (isConnected) {
      _updateStatus(RfidConnectionStatus.connected);
    }
  }
  
  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    Logger.info(_logTag, 'Disposing BLE RFID reader');
    _isDisposed = true;
    
    await stopScanning();
    await disconnect();
    
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    
    await _tagReadingsController.close();
    await _connectionStatusController.close();
    
    Logger.info(_logTag, 'BLE RFID reader disposed');
  }
  
  /// Request required permissions for BLE operations
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.location, // Required for BLE scanning on Android
    ];
    
    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        Logger.warning(_logTag, 'Permission ${permission.toString()} not granted');
      }
    }
  }
  
  /// Discover and find the target BLE RFID reader device
  Future<void> _discoverDevice() async {
    Logger.info(_logTag, 'Discovering BLE devices');
    
    final completer = Completer<void>();
    StreamSubscription? scanSubscription;
    
    try {
      // Check if device is already connected
      final connectedDevices = FlutterBluePlus.connectedDevices;
      for (final device in connectedDevices) {
        if (_isTargetDevice(device)) {
          _targetDevice = device;
          Logger.info(_logTag, 'Found target device in connected devices: ${device.name}');
          return;
        }
      }
      
      // Start scanning for devices
      scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (final result in results) {
            if (_isTargetDevice(result.device)) {
              _targetDevice = result.device;
              Logger.info(_logTag, 'Found target device during scan: ${result.device.name}');
              completer.complete();
              return;
            }
          }
        },
        onError: (error) {
          Logger.error(_logTag, 'BLE scan error', error);
          completer.completeError(error);
        },
      );
      
      // Start scanning
      await FlutterBluePlus.startScan(
        withServices: _config.serviceUuids.isNotEmpty ? _config.serviceUuids : null,
        timeout: AppConfig.bluetoothScanTimeout,
      );
      
      // Wait for device to be found or timeout
      await completer.future.timeout(AppConfig.bluetoothScanTimeout);
      
    } finally {
      await FlutterBluePlus.stopScan();
      await scanSubscription?.cancel();
    }
  }
  
  /// Check if device is the target RFID reader
  bool _isTargetDevice(BluetoothDevice device) {
    // Check by device address
    if (_config.deviceAddress != null) {
      return device.id.toString() == _config.deviceAddress;
    }
    
    // Check by device name
    if (_config.deviceName != null) {
      return device.name.contains(_config.deviceName!);
    }
    
    // Check by advertised service UUIDs
    if (_config.serviceUuids.isNotEmpty) {
      // This would require access to advertisement data
      // For now, we'll use name-based matching as fallback
      return device.name.toLowerCase().contains('rfid') ||
             device.name.toLowerCase().contains('tag') ||
             device.name.toLowerCase().contains('reader');
    }
    
    return false;
  }
  
  /// Discover GATT services and characteristics
  Future<void> _discoverServices() async {
    Logger.info(_logTag, 'Discovering GATT services');
    
    final services = await _targetDevice!.discoverServices();
    
    for (final service in services) {
      Logger.info(_logTag, 'Found service: ${service.uuid}');
      
      // Look for RFID data service
      if (_config.serviceUuids.contains(service.uuid)) {
        for (final characteristic in service.characteristics) {
          Logger.info(_logTag, 'Found characteristic: ${characteristic.uuid}');
          
          // Tag data characteristic
          if (characteristic.uuid == Guid(_config.tagDataCharacteristicUuid)) {
            _tagDataCharacteristic = characteristic;
            Logger.info(_logTag, 'Found tag data characteristic');
          }
          
          // Control characteristic
          if (_config.controlCharacteristicUuid != null &&
              characteristic.uuid == Guid(_config.controlCharacteristicUuid!)) {
            _controlCharacteristic = characteristic;
            Logger.info(_logTag, 'Found control characteristic');
          }
          
          // Battery characteristic
          if (_config.batteryCharacteristicUuid != null &&
              characteristic.uuid == Guid(_config.batteryCharacteristicUuid!)) {
            _batteryCharacteristic = characteristic;
            Logger.info(_logTag, 'Found battery characteristic');
          }
        }
      }
      
      // Standard battery service
      if (service.uuid == Guid('0000180f-0000-1000-8000-00805f9b34fb')) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == Guid('00002a19-0000-1000-8000-00805f9b34fb')) {
            _batteryCharacteristic = characteristic;
            Logger.info(_logTag, 'Found standard battery characteristic');
          }
        }
      }
    }
    
    if (_tagDataCharacteristic == null) {
      throw const RfidReaderException(
        'Tag data characteristic not found',
        readerType: RfidReaderType.bluetoothLowEnergy,
        errorCode: 'CHARACTERISTIC_NOT_FOUND',
      );
    }
  }
  
  /// Setup notifications for tag readings and battery updates
  Future<void> _setupNotifications() async {
    Logger.info(_logTag, 'Setting up BLE notifications');
    
    // Setup tag data notifications
    if (_tagDataCharacteristic!.properties.notify || _tagDataCharacteristic!.properties.indicate) {
      await _tagDataCharacteristic!.setNotifyValue(true);
      
      final subscription = _tagDataCharacteristic!.value.listen(
        _handleTagData,
        onError: (error) {
          Logger.error(_logTag, 'Tag data notification error', error);
        },
      );
      
      _subscriptions.add(subscription);
      Logger.info(_logTag, 'Tag data notifications enabled');
    }
    
    // Setup battery notifications if available
    if (_batteryCharacteristic != null &&
        (_batteryCharacteristic!.properties.notify || _batteryCharacteristic!.properties.indicate)) {
      
      await _batteryCharacteristic!.setNotifyValue(true);
      
      final subscription = _batteryCharacteristic!.value.listen(
        _handleBatteryData,
        onError: (error) {
          Logger.error(_logTag, 'Battery notification error', error);
        },
      );
      
      _subscriptions.add(subscription);
      Logger.info(_logTag, 'Battery notifications enabled');
    }
  }
  
  /// Setup connection state monitoring
  void _setupConnectionMonitoring() {
    final subscription = _targetDevice!.state.listen(
      (state) {
        Logger.info(_logTag, 'Device connection state: $state');
        
        switch (state) {
          case BluetoothDeviceState.connected:
            if (_currentStatus == RfidConnectionStatus.connecting) {
              _updateStatus(RfidConnectionStatus.connected);
            }
            break;
          case BluetoothDeviceState.disconnected:
            _updateStatus(RfidConnectionStatus.disconnected);
            // Attempt reconnection if not disposed
            if (!_isDisposed) {
              _attemptReconnection();
            }
            break;
          case BluetoothDeviceState.connecting:
            _updateStatus(RfidConnectionStatus.connecting);
            break;
          case BluetoothDeviceState.disconnecting:
            _updateStatus(RfidConnectionStatus.disconnected);
            break;
        }
      },
      onError: (error) {
        Logger.error(_logTag, 'Connection state monitoring error', error);
        _updateStatus(RfidConnectionStatus.error);
      },
    );
    
    _subscriptions.add(subscription);
  }
  
  /// Handle incoming tag data
  void _handleTagData(List<int> data) {
    if (_isDisposed || !_isScanning || data.isEmpty) return;
    
    try {
      String tagId = '';
      
      // Parse data based on encoding
      switch (_config.encoding) {
        case 'utf8':
          tagId = utf8.decode(data);
          break;
        case 'hex':
          tagId = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          break;
        case 'ascii':
          tagId = String.fromCharCodes(data);
          break;
        default:
          tagId = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      }
      
      // Apply filters
      tagId = _applyFilters(tagId);
      
      if (tagId.isEmpty) return;
      
      // Create tag reading
      final tagReading = RfidTagReading(
        tagId: tagId,
        rawData: data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        timestamp: DateTime.now(),
        readerType: RfidReaderType.bluetoothLowEnergy,
        metadata: {
          'device_name': _targetDevice?.name,
          'device_id': _targetDevice?.id.toString(),
          'data_length': data.length,
          'encoding': _config.encoding,
          'characteristic_uuid': _tagDataCharacteristic?.uuid.toString(),
        },
      );
      
      // Emit tag reading
      _tagReadingsController.add(tagReading);
      Logger.info(_logTag, 'BLE RFID tag detected: ${tagReading.tagId}');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to handle tag data', e, stack);
    }
  }
  
  /// Handle battery level data
  void _handleBatteryData(List<int> data) {
    if (data.isNotEmpty) {
      final batteryLevel = data[0];
      Logger.info(_logTag, 'Battery level: $batteryLevel%');
      
      // Update reader info with battery level
      _readerInfo = _readerInfo.copyWith(batteryLevel: batteryLevel);
    }
  }
  
  /// Apply configured filters to tag data
  String _applyFilters(String tagId) {
    String filtered = tagId.trim();
    
    // Remove prefix if configured
    if (_config.removePrefix != null && filtered.startsWith(_config.removePrefix!)) {
      filtered = filtered.substring(_config.removePrefix!.length);
    }
    
    // Remove suffix if configured
    if (_config.removeSuffix != null && filtered.endsWith(_config.removeSuffix!)) {
      filtered = filtered.substring(0, filtered.length - _config.removeSuffix!.length);
    }
    
    // Apply regex filter if configured
    if (_config.regexFilter != null) {
      final match = RegExp(_config.regexFilter!).firstMatch(filtered);
      if (match != null) {
        filtered = match.group(0) ?? filtered;
      }
    }
    
    return filtered;
  }
  
  /// Attempt automatic reconnection
  Future<void> _attemptReconnection() async {
    if (_isDisposed || _currentStatus == RfidConnectionStatus.connecting) return;
    
    Logger.info(_logTag, 'Attempting automatic reconnection');
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      await connect();
    } catch (e) {
      Logger.error(_logTag, 'Automatic reconnection failed', e);
    }
  }
  
  /// Update connection status and notify listeners
  void _updateStatus(RfidConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _connectionStatusController.add(status);
      Logger.info(_logTag, 'Status changed to: $status');
    }
  }
  
  /// Cleanup connection resources
  Future<void> _cleanup() async {
    try {
      // Disable notifications
      if (_tagDataCharacteristic != null) {
        await _tagDataCharacteristic!.setNotifyValue(false);
      }
      if (_batteryCharacteristic != null) {
        await _batteryCharacteristic!.setNotifyValue(false);
      }
      
      // Disconnect device
      if (_targetDevice != null && _targetDevice!.isConnected) {
        await _targetDevice!.disconnect();
      }
      
      _targetDevice = null;
      _tagDataCharacteristic = null;
      _batteryCharacteristic = null;
      _controlCharacteristic = null;
      
    } catch (e) {
      Logger.error(_logTag, 'Error during cleanup', e);
    }
  }
}

/// Configuration for BLE RFID reader
class BleRfidConfig {
  /// Target device Bluetooth address
  final String? deviceAddress;
  
  /// Target device name (for discovery)
  final String? deviceName;
  
  /// Service UUIDs to filter devices
  final List<Guid> serviceUuids;
  
  /// Tag data characteristic UUID
  final String tagDataCharacteristicUuid;
  
  /// Control characteristic UUID (optional)
  final String? controlCharacteristicUuid;
  
  /// Battery characteristic UUID (optional)
  final String? batteryCharacteristicUuid;
  
  /// Data encoding (utf8, hex, ascii)
  final String encoding;
  
  /// Command to start scanning
  final List<int>? scanCommand;
  
  /// Command to stop scanning
  final List<int>? stopCommand;
  
  /// Prefix to remove from tag data
  final String? removePrefix;
  
  /// Suffix to remove from tag data
  final String? removeSuffix;
  
  /// Regex filter to extract tag ID
  final String? regexFilter;
  
  const BleRfidConfig({
    this.deviceAddress,
    this.deviceName,
    this.serviceUuids = const [],
    required this.tagDataCharacteristicUuid,
    this.controlCharacteristicUuid,
    this.batteryCharacteristicUuid,
    this.encoding = 'utf8',
    this.scanCommand,
    this.stopCommand,
    this.removePrefix,
    this.removeSuffix,
    this.regexFilter,
  });
  
  /// Default configuration for generic BLE RFID readers
  factory BleRfidConfig.defaultConfig() {
    return const BleRfidConfig(
      tagDataCharacteristicUuid: '0000ffe1-0000-1000-8000-00805f9b34fb',
      encoding: 'utf8',
    );
  }
  
  /// Convert configuration to map
  Map<String, dynamic> toMap() {
    return {
      'device_address': deviceAddress,
      'device_name': deviceName,
      'service_uuids': serviceUuids.map((uuid) => uuid.toString()).toList(),
      'tag_data_characteristic_uuid': tagDataCharacteristicUuid,
      'control_characteristic_uuid': controlCharacteristicUuid,
      'battery_characteristic_uuid': batteryCharacteristicUuid,
      'encoding': encoding,
      'scan_command': scanCommand,
      'stop_command': stopCommand,
      'remove_prefix': removePrefix,
      'remove_suffix': removeSuffix,
      'regex_filter': regexFilter,
    };
  }
}

/// Extension to copy RfidReaderInfo with new values
extension RfidReaderInfoCopy on RfidReaderInfo {
  RfidReaderInfo copyWith({
    String? name,
    RfidReaderType? type,
    String? hardwareId,
    String? manufacturer,
    String? model,
    String? firmwareVersion,
    List<String>? supportedTagTypes,
    List<String>? capabilities,
    Map<String, dynamic>? connectionParams,
    int? batteryLevel,
    int? signalStrength,
  }) {
    return RfidReaderInfo(
      name: name ?? this.name,
      type: type ?? this.type,
      hardwareId: hardwareId ?? this.hardwareId,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      supportedTagTypes: supportedTagTypes ?? this.supportedTagTypes,
      capabilities: capabilities ?? this.capabilities,
      connectionParams: connectionParams ?? this.connectionParams,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }
}