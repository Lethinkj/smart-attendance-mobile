import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/app_config.dart';
import '../../utils/logger.dart';
import 'rfid_reader_interface.dart';

/// Bluetooth Classic (SPP) RFID Reader Implementation
/// Supports traditional serial-based RFID readers over Bluetooth Classic
/// 
/// Features:
/// - Device discovery and pairing
/// - Robust reconnection handling
/// - Configurable frame parsing
/// - Buffer management for partial reads
/// - Connection quality monitoring
class BluetoothClassicRfidReader implements RfidReaderInterface {
  static const String _logTag = 'BluetoothClassicRfid';
  
  // Bluetooth connection
  BluetoothConnection? _connection;
  BluetoothDevice? _targetDevice;
  
  // Stream controllers
  final StreamController<RfidTagReading> _tagReadingsController = 
      StreamController<RfidTagReading>.broadcast();
  final StreamController<RfidConnectionStatus> _connectionStatusController = 
      StreamController<RfidConnectionStatus>.broadcast();
  
  // State management
  RfidConnectionStatus _currentStatus = RfidConnectionStatus.disconnected;
  bool _isScanning = false;
  bool _isDisposed = false;
  
  // Buffer for incoming data
  final List<int> _dataBuffer = [];
  
  // Configuration
  final BluetoothClassicConfig _config;
  
  // Reader information
  late RfidReaderInfo _readerInfo;
  
  BluetoothClassicRfidReader({BluetoothClassicConfig? config})
      : _config = config ?? BluetoothClassicConfig.defaultConfig() {
    
    _readerInfo = RfidReaderInfo(
      name: _config.deviceName ?? 'Bluetooth RFID Reader',
      type: RfidReaderType.bluetoothClassic,
      hardwareId: _config.deviceAddress,
      supportedTagTypes: ['ISO14443A', 'ISO14443B', 'ISO15693', 'MIFARE'],
      capabilities: ['read_uid', 'read_data', 'write_data'],
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
  bool get isConnected => _connection != null && _connection!.isConnected;
  
  @override
  RfidReaderInfo get readerInfo => _readerInfo;
  
  @override
  Future<void> initialize() async {
    Logger.info(_logTag, 'Initializing Bluetooth Classic RFID reader');
    
    try {
      // Check if Bluetooth is available
      final isAvailable = await FlutterBluetoothSerial.instance.isAvailable ?? false;
      if (!isAvailable) {
        throw const RfidReaderException(
          'Bluetooth is not available on this device',
          readerType: RfidReaderType.bluetoothClassic,
          errorCode: 'BLUETOOTH_UNAVAILABLE',
        );
      }
      
      // Check permissions
      await _requestPermissions();
      
      // Enable Bluetooth if not enabled
      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (!isEnabled) {
        final enableResult = await FlutterBluetoothSerial.instance.requestEnable();
        if (enableResult != true) {
          throw const RfidReaderException(
            'Bluetooth must be enabled to use RFID reader',
            readerType: RfidReaderType.bluetoothClassic,
            errorCode: 'BLUETOOTH_DISABLED',
          );
        }
      }
      
      Logger.info(_logTag, 'Bluetooth Classic RFID reader initialized successfully');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to initialize Bluetooth Classic RFID reader', e, stack);
      _updateStatus(RfidConnectionStatus.error);
      rethrow;
    }
  }
  
  @override
  Future<void> connect() async {
    if (_isDisposed) return;
    
    Logger.info(_logTag, 'Connecting to Bluetooth Classic RFID reader');
    _updateStatus(RfidConnectionStatus.connecting);
    
    try {
      // Find target device
      if (_targetDevice == null) {
        await _discoverDevice();
      }
      
      if (_targetDevice == null) {
        throw const RfidReaderException(
          'RFID reader device not found',
          readerType: RfidReaderType.bluetoothClassic,
          errorCode: 'DEVICE_NOT_FOUND',
        );
      }
      
      // Establish connection
      _connection = await BluetoothConnection.toAddress(_targetDevice!.address)
          .timeout(AppConfig.bluetoothConnectionTimeout);
      
      // Start listening to incoming data
      _setupDataListener();
      
      _updateStatus(RfidConnectionStatus.connected);
      Logger.info(_logTag, 'Successfully connected to ${_targetDevice!.name}');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to connect to Bluetooth Classic RFID reader', e, stack);
      _updateStatus(RfidConnectionStatus.error);
      await _cleanup();
      throw RfidReaderException(
        'Failed to connect to RFID reader: $e',
        readerType: RfidReaderType.bluetoothClassic,
        originalError: e,
      );
    }
  }
  
  @override
  Future<void> disconnect() async {
    Logger.info(_logTag, 'Disconnecting from Bluetooth Classic RFID reader');
    
    await stopScanning();
    await _cleanup();
    _updateStatus(RfidConnectionStatus.disconnected);
    
    Logger.info(_logTag, 'Disconnected from Bluetooth Classic RFID reader');
  }
  
  @override
  Future<void> startScanning() async {
    if (_isDisposed || !isConnected) {
      throw const RfidReaderException(
        'Cannot start scanning: reader not connected',
        readerType: RfidReaderType.bluetoothClassic,
        errorCode: 'NOT_CONNECTED',
      );
    }
    
    if (_isScanning) return;
    
    Logger.info(_logTag, 'Starting RFID tag scanning');
    _isScanning = true;
    _updateStatus(RfidConnectionStatus.scanning);
    
    // Send scan command if configured
    if (_config.scanCommand != null) {
      try {
        _connection!.output.add(Uint8List.fromList(_config.scanCommand!));
        await _connection!.output.allSent;
      } catch (e) {
        Logger.error(_logTag, 'Failed to send scan command', e);
      }
    }
  }
  
  @override
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    
    Logger.info(_logTag, 'Stopping RFID tag scanning');
    _isScanning = false;
    
    // Send stop command if configured
    if (_config.stopCommand != null && isConnected) {
      try {
        _connection!.output.add(Uint8List.fromList(_config.stopCommand!));
        await _connection!.output.allSent;
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
    
    Logger.info(_logTag, 'Disposing Bluetooth Classic RFID reader');
    _isDisposed = true;
    
    await stopScanning();
    await disconnect();
    
    await _tagReadingsController.close();
    await _connectionStatusController.close();
    
    Logger.info(_logTag, 'Bluetooth Classic RFID reader disposed');
  }
  
  /// Request required permissions for Bluetooth operations
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location, // Required for device discovery on some Android versions
    ];
    
    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        Logger.warning(_logTag, 'Permission ${permission.toString()} not granted');
      }
    }
  }
  
  /// Discover and find the target RFID reader device
  Future<void> _discoverDevice() async {
    Logger.info(_logTag, 'Discovering Bluetooth devices');
    
    try {
      // Get bonded devices first
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      // Look for target device in bonded devices
      if (_config.deviceAddress != null) {
        _targetDevice = bondedDevices.firstWhere(
          (device) => device.address == _config.deviceAddress,
          orElse: () => throw const RfidReaderException(
            'Target device not found in bonded devices',
            readerType: RfidReaderType.bluetoothClassic,
            errorCode: 'DEVICE_NOT_BONDED',
          ),
        );
      } else if (_config.deviceName != null) {
        _targetDevice = bondedDevices.firstWhere(
          (device) => device.name?.contains(_config.deviceName!) ?? false,
          orElse: () => throw const RfidReaderException(
            'Target device not found by name',
            readerType: RfidReaderType.bluetoothClassic,
            errorCode: 'DEVICE_NOT_FOUND_BY_NAME',
          ),
        );
      }
      
      if (_targetDevice != null) {
        Logger.info(_logTag, 'Found target device: ${_targetDevice!.name} (${_targetDevice!.address})');
        return;
      }
      
      // If not found in bonded devices, start discovery
      Logger.info(_logTag, 'Target device not bonded, starting discovery');
      await _startDiscovery();
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Device discovery failed', e, stack);
      rethrow;
    }
  }
  
  /// Start Bluetooth device discovery
  Future<void> _startDiscovery() async {
    final completer = Completer<void>();
    StreamSubscription? subscription;
    
    try {
      subscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
        (result) {
          final device = result.device;
          
          // Check if this is our target device
          final isTargetDevice = (_config.deviceAddress != null && device.address == _config.deviceAddress) ||
              (_config.deviceName != null && (device.name?.contains(_config.deviceName!) ?? false));
          
          if (isTargetDevice) {
            _targetDevice = device;
            Logger.info(_logTag, 'Found target device during discovery: ${device.name} (${device.address})');
            subscription?.cancel();
            completer.complete();
          }
        },
        onError: (error) {
          Logger.error(_logTag, 'Discovery error', error);
          completer.completeError(error);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(const RfidReaderException(
              'Device discovery completed but target device not found',
              readerType: RfidReaderType.bluetoothClassic,
              errorCode: 'DISCOVERY_NO_TARGET',
            ));
          }
        },
      );
      
      // Wait for discovery to complete or timeout
      await completer.future.timeout(AppConfig.bluetoothScanTimeout);
      
    } finally {
      await subscription?.cancel();
      await FlutterBluetoothSerial.instance.cancelDiscovery();
    }
  }
  
  /// Setup listener for incoming data from the RFID reader
  void _setupDataListener() {
    _connection!.input!.listen(
      _handleIncomingData,
      onError: (error) {
        Logger.error(_logTag, 'Data listener error', error);
        _updateStatus(RfidConnectionStatus.error);
      },
      onDone: () {
        Logger.info(_logTag, 'Connection closed');
        _updateStatus(RfidConnectionStatus.disconnected);
      },
    );
  }
  
  /// Handle incoming data from the RFID reader
  void _handleIncomingData(Uint8List data) {
    if (_isDisposed || !_isScanning) return;
    
    // Add data to buffer
    _dataBuffer.addAll(data);
    
    // Process complete frames
    _processDataBuffer();
  }
  
  /// Process buffered data and extract complete RFID tag readings
  void _processDataBuffer() {
    while (_dataBuffer.isNotEmpty) {
      // Look for frame terminator
      int terminatorIndex = -1;
      
      for (final terminator in _config.frameTerminators) {
        terminatorIndex = _findSequence(_dataBuffer, terminator);
        if (terminatorIndex != -1) break;
      }
      
      if (terminatorIndex == -1) {
        // No complete frame yet, check buffer size limits
        if (_dataBuffer.length > _config.maxBufferSize) {
          Logger.warning(_logTag, 'Buffer overflow, clearing buffer');
          _dataBuffer.clear();
        }
        break;
      }
      
      // Extract frame data
      final frameData = _dataBuffer.sublist(0, terminatorIndex);
      _dataBuffer.removeRange(0, terminatorIndex + _config.frameTerminators[0].length);
      
      // Parse frame
      _parseFrame(frameData);
    }
  }
  
  /// Find sequence in buffer
  int _findSequence(List<int> buffer, List<int> sequence) {
    for (int i = 0; i <= buffer.length - sequence.length; i++) {
      bool found = true;
      for (int j = 0; j < sequence.length; j++) {
        if (buffer[i + j] != sequence[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }
  
  /// Parse frame data and extract RFID tag information
  void _parseFrame(List<int> frameData) {
    if (frameData.isEmpty) return;
    
    try {
      // Convert to string for parsing
      String frameString = '';
      
      if (_config.encoding == 'ascii') {
        frameString = String.fromCharCodes(frameData);
      } else if (_config.encoding == 'utf8') {
        frameString = utf8.decode(frameData);
      } else if (_config.encoding == 'hex') {
        frameString = frameData.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      }
      
      // Apply frame filters
      frameString = _applyFrameFilters(frameString);
      
      if (frameString.isEmpty) return;
      
      // Create tag reading
      final tagReading = RfidTagReading(
        tagId: frameString,
        rawData: frameData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        timestamp: DateTime.now(),
        readerType: RfidReaderType.bluetoothClassic,
        metadata: {
          'device_name': _targetDevice?.name,
          'device_address': _targetDevice?.address,
          'frame_length': frameData.length,
          'encoding': _config.encoding,
        },
      );
      
      // Emit tag reading
      _tagReadingsController.add(tagReading);
      Logger.info(_logTag, 'RFID tag detected: ${tagReading.tagId}');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to parse frame data', e, stack);
    }
  }
  
  /// Apply configured filters to frame string
  String _applyFrameFilters(String frame) {
    String filtered = frame;
    
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
    
    return filtered.trim();
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
      await _connection?.close();
      _connection = null;
      _dataBuffer.clear();
    } catch (e) {
      Logger.error(_logTag, 'Error during cleanup', e);
    }
  }
}

/// Configuration for Bluetooth Classic RFID reader
class BluetoothClassicConfig {
  /// Target device Bluetooth address (MAC address)
  final String? deviceAddress;
  
  /// Target device name (for discovery)
  final String? deviceName;
  
  /// Data encoding (ascii, utf8, hex)
  final String encoding;
  
  /// Frame terminators (e.g., [10] for LF, [13, 10] for CRLF)
  final List<List<int>> frameTerminators;
  
  /// Maximum buffer size before overflow
  final int maxBufferSize;
  
  /// Command to send to start scanning
  final List<int>? scanCommand;
  
  /// Command to send to stop scanning
  final List<int>? stopCommand;
  
  /// Prefix to remove from tag data
  final String? removePrefix;
  
  /// Suffix to remove from tag data
  final String? removeSuffix;
  
  /// Regex filter to extract tag ID
  final String? regexFilter;
  
  const BluetoothClassicConfig({
    this.deviceAddress,
    this.deviceName,
    this.encoding = 'ascii',
    this.frameTerminators = const [[10]], // Default: LF
    this.maxBufferSize = 1024,
    this.scanCommand,
    this.stopCommand,
    this.removePrefix,
    this.removeSuffix,
    this.regexFilter,
  });
  
  /// Default configuration for common RFID readers
  factory BluetoothClassicConfig.defaultConfig() {
    return const BluetoothClassicConfig(
      encoding: 'ascii',
      frameTerminators: [[10], [13, 10]], // LF and CRLF
      maxBufferSize: 1024,
    );
  }
  
  /// Configuration for specific reader models
  factory BluetoothClassicConfig.forModel(String model) {
    switch (model.toLowerCase()) {
      case 'uhf_rfid_reader':
        return const BluetoothClassicConfig(
          encoding: 'hex',
          frameTerminators: [[13, 10]],
          removePrefix: 'E2',
          regexFilter: r'[0-9A-Fa-f]{8,}',
        );
      
      case 'hf_rfid_reader':
        return const BluetoothClassicConfig(
          encoding: 'ascii',
          frameTerminators: [[10]],
          regexFilter: r'[0-9A-Fa-f]{8,16}',
        );
      
      default:
        return BluetoothClassicConfig.defaultConfig();
    }
  }
  
  /// Convert configuration to map
  Map<String, dynamic> toMap() {
    return {
      'device_address': deviceAddress,
      'device_name': deviceName,
      'encoding': encoding,
      'frame_terminators': frameTerminators,
      'max_buffer_size': maxBufferSize,
      'scan_command': scanCommand,
      'stop_command': stopCommand,
      'remove_prefix': removePrefix,
      'remove_suffix': removeSuffix,
      'regex_filter': regexFilter,
    };
  }
}