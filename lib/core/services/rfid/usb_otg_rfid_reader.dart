import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/logger.dart';
import 'rfid_reader_interface.dart';

/// USB-OTG RFID Reader Implementation (Android Only)
/// Supports RFID readers connected via USB-OTG cable
/// 
/// Features:
/// - USB device detection and permission handling
/// - Serial communication over USB
/// - Multiple baud rate support
/// - Data parsing with configurable terminators
/// - Hot plug/unplug detection
/// - Graceful fallback on unsupported devices
class UsbOtgRfidReader implements RfidReaderInterface {
  static const String _logTag = 'UsbOtgRfidReader';
  
  // USB connection
  UsbDevice? _targetDevice;
  UsbPort? _usbPort;
  
  // Stream controllers
  final StreamController<RfidTagReading> _tagReadingsController = 
      StreamController<RfidTagReading>.broadcast();
  final StreamController<RfidConnectionStatus> _connectionStatusController = 
      StreamController<RfidConnectionStatus>.broadcast();
  
  // State management
  RfidConnectionStatus _currentStatus = RfidConnectionStatus.disconnected;
  bool _isScanning = false;
  bool _isDisposed = false;
  
  // Data buffer for incomplete reads
  final List<int> _dataBuffer = [];
  
  // Configuration
  final UsbOtgConfig _config;
  
  // Reader information
  late RfidReaderInfo _readerInfo;
  
  // USB monitoring subscription
  StreamSubscription? _usbEventSubscription;
  
  UsbOtgRfidReader({UsbOtgConfig? config})
      : _config = config ?? UsbOtgConfig.defaultConfig() {
    
    _readerInfo = RfidReaderInfo(
      name: _config.readerName ?? 'USB RFID Reader',
      type: RfidReaderType.usbOtg,
      supportedTagTypes: ['ISO14443A', 'ISO14443B', 'ISO15693', 'MIFARE', 'EM4100'],
      capabilities: ['read_uid', 'read_data', 'write_data', 'hot_plug'],
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
  bool get isConnected => _usbPort != null;
  
  @override
  RfidReaderInfo get readerInfo => _readerInfo;
  
  @override
  Future<void> initialize() async {
    Logger.info(_logTag, 'Initializing USB-OTG RFID reader');
    
    try {
      // Check if USB OTG is supported (Android only)
      final devices = await UsbSerial.listDevices();
      Logger.info(_logTag, 'USB devices found: ${devices.length}');
      
      // Request necessary permissions
      await _requestPermissions();
      
      // Setup USB event monitoring
      _setupUsbEventMonitoring();
      
      Logger.info(_logTag, 'USB-OTG RFID reader initialized successfully');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to initialize USB-OTG RFID reader', e, stack);
      _updateStatus(RfidConnectionStatus.unavailable);
      
      // This is expected on iOS or devices without USB OTG support
      if (e.toString().contains('not supported') || e.toString().contains('permission')) {
        throw const RfidReaderException(
          'USB-OTG is not supported on this device',
          readerType: RfidReaderType.usbOtg,
          errorCode: 'USB_OTG_NOT_SUPPORTED',
        );
      }
      
      rethrow;
    }
  }
  
  @override
  Future<void> connect() async {
    if (_isDisposed) return;
    
    Logger.info(_logTag, 'Connecting to USB-OTG RFID reader');
    _updateStatus(RfidConnectionStatus.connecting);
    
    try {
      // Find target device
      if (_targetDevice == null) {
        await _discoverDevice();
      }
      
      if (_targetDevice == null) {
        throw const RfidReaderException(
          'USB RFID reader device not found',
          readerType: RfidReaderType.usbOtg,
          errorCode: 'DEVICE_NOT_FOUND',
        );
      }
      
      // Request permission to access the USB device
      final hasPermission = await UsbSerial.requestPermission(_targetDevice!);
      if (!hasPermission) {
        throw const RfidReaderException(
          'USB device permission denied',
          readerType: RfidReaderType.usbOtg,
          errorCode: 'PERMISSION_DENIED',
        );
      }
      
      // Create USB port and open connection
      _usbPort = await _targetDevice!.create();
      if (_usbPort == null) {
        throw const RfidReaderException(
          'Failed to create USB port',
          readerType: RfidReaderType.usbOtg,
          errorCode: 'PORT_CREATION_FAILED',
        );
      }
      
      // Configure port settings
      await _configurePort();
      
      // Open the port
      final openResult = await _usbPort!.open();
      if (!openResult) {
        throw const RfidReaderException(
          'Failed to open USB port',
          readerType: RfidReaderType.usbOtg,
          errorCode: 'PORT_OPEN_FAILED',
        );
      }
      
      // Setup data listener
      _setupDataListener();
      
      // Update reader info with device details
      _updateReaderInfo();
      
      _updateStatus(RfidConnectionStatus.connected);
      Logger.info(_logTag, 'Successfully connected to USB RFID reader');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to connect to USB-OTG RFID reader', e, stack);
      _updateStatus(RfidConnectionStatus.error);
      await _cleanup();
      
      throw RfidReaderException(
        'Failed to connect to USB RFID reader: $e',
        readerType: RfidReaderType.usbOtg,
        originalError: e,
      );
    }
  }
  
  @override
  Future<void> disconnect() async {
    Logger.info(_logTag, 'Disconnecting from USB-OTG RFID reader');
    
    await stopScanning();
    await _cleanup();
    _updateStatus(RfidConnectionStatus.disconnected);
    
    Logger.info(_logTag, 'Disconnected from USB-OTG RFID reader');
  }
  
  @override
  Future<void> startScanning() async {
    if (_isDisposed || !isConnected) {
      throw const RfidReaderException(
        'Cannot start scanning: reader not connected',
        readerType: RfidReaderType.usbOtg,
        errorCode: 'NOT_CONNECTED',
      );
    }
    
    if (_isScanning) return;
    
    Logger.info(_logTag, 'Starting USB RFID tag scanning');
    _isScanning = true;
    _updateStatus(RfidConnectionStatus.scanning);
    
    // Send scan command if configured
    if (_config.scanCommand != null) {
      try {
        await _usbPort!.write(Uint8List.fromList(_config.scanCommand!));
        Logger.info(_logTag, 'Scan command sent');
      } catch (e) {
        Logger.error(_logTag, 'Failed to send scan command', e);
      }
    }
  }
  
  @override
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    
    Logger.info(_logTag, 'Stopping USB RFID tag scanning');
    _isScanning = false;
    
    // Send stop command if configured
    if (_config.stopCommand != null && isConnected) {
      try {
        await _usbPort!.write(Uint8List.fromList(_config.stopCommand!));
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
    
    Logger.info(_logTag, 'Disposing USB-OTG RFID reader');
    _isDisposed = true;
    
    await stopScanning();
    await disconnect();
    
    // Cancel USB event monitoring
    await _usbEventSubscription?.cancel();
    
    await _tagReadingsController.close();
    await _connectionStatusController.close();
    
    Logger.info(_logTag, 'USB-OTG RFID reader disposed');
  }
  
  /// Request required permissions for USB operations
  Future<void> _requestPermissions() async {
    // USB permissions are handled by the UsbSerial plugin
    // Additional permissions might be needed for specific devices
    final permissions = [
      Permission.storage, // Sometimes needed for USB access
    ];
    
    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        Logger.warning(_logTag, 'Permission ${permission.toString()} not granted');
      }
    }
  }
  
  /// Discover and find the target USB RFID reader device
  Future<void> _discoverDevice() async {
    Logger.info(_logTag, 'Discovering USB devices');
    
    try {
      final devices = await UsbSerial.listDevices();
      Logger.info(_logTag, 'Found ${devices.length} USB devices');
      
      for (final device in devices) {
        Logger.info(_logTag, 'USB Device: ${device.productName} (VID: ${device.vid}, PID: ${device.pid})');
        
        // Check if this is our target device
        if (_isTargetDevice(device)) {
          _targetDevice = device;
          Logger.info(_logTag, 'Found target RFID reader: ${device.productName}');
          return;
        }
      }
      
      // If no specific device configured, use the first available serial device
      if (_config.vendorId == null && _config.productId == null && devices.isNotEmpty) {
        _targetDevice = devices.first;
        Logger.info(_logTag, 'Using first available USB device: ${_targetDevice!.productName}');
      }
      
    } catch (e, stack) {
      Logger.error(_logTag, 'USB device discovery failed', e, stack);
      rethrow;
    }
  }
  
  /// Check if device is the target RFID reader
  bool _isTargetDevice(UsbDevice device) {
    // Check by vendor and product ID
    if (_config.vendorId != null && _config.productId != null) {
      return device.vid == _config.vendorId && device.pid == _config.productId;
    }
    
    // Check by product name
    if (_config.productName != null) {
      return device.productName?.toLowerCase().contains(_config.productName!.toLowerCase()) ?? false;
    }
    
    // Check for common RFID reader identifiers
    final productName = device.productName?.toLowerCase() ?? '';
    return productName.contains('rfid') ||
           productName.contains('reader') ||
           productName.contains('tag') ||
           productName.contains('mifare') ||
           productName.contains('serial') ||
           productName.contains('usb');
  }
  
  /// Configure USB port settings
  Future<void> _configurePort() async {
    if (_usbPort == null) return;
    
    Logger.info(_logTag, 'Configuring USB port settings');
    
    try {
      // Set baud rate
      await _usbPort!.setPortParameters(
        _config.baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      
      // Set flow control if needed
      if (_config.flowControl) {
        await _usbPort!.setDTR(true);
        await _usbPort!.setRTS(true);
      }
      
      Logger.info(_logTag, 'USB port configured - Baud: ${_config.baudRate}');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to configure USB port', e, stack);
      rethrow;
    }
  }
  
  /// Setup data listener for incoming USB data
  void _setupDataListener() {
    if (_usbPort == null) return;
    
    Logger.info(_logTag, 'Setting up USB data listener');
    
    _usbPort!.inputStream?.listen(
      _handleIncomingData,
      onError: (error) {
        Logger.error(_logTag, 'USB data listener error', error);
        _updateStatus(RfidConnectionStatus.error);
      },
      onDone: () {
        Logger.info(_logTag, 'USB connection closed');
        _updateStatus(RfidConnectionStatus.disconnected);
      },
    );
  }
  
  /// Handle incoming data from the USB RFID reader
  void _handleIncomingData(Uint8List data) {
    if (_isDisposed || !_isScanning || data.isEmpty) return;
    
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
        readerType: RfidReaderType.usbOtg,
        metadata: {
          'device_name': _targetDevice?.productName,
          'vendor_id': _targetDevice?.vid,
          'product_id': _targetDevice?.pid,
          'frame_length': frameData.length,
          'encoding': _config.encoding,
          'baud_rate': _config.baudRate,
        },
      );
      
      // Emit tag reading
      _tagReadingsController.add(tagReading);
      Logger.info(_logTag, 'USB RFID tag detected: ${tagReading.tagId}');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to parse USB frame data', e, stack);
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
  
  /// Setup USB event monitoring for hot plug/unplug detection
  void _setupUsbEventMonitoring() {
    _usbEventSubscription = UsbSerial.usbEventStream?.listen(
      (UsbEvent event) {
        Logger.info(_logTag, 'USB event: ${event.toString()}');
        
        if (event.device != null && _isTargetDevice(event.device!)) {
          if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
            Logger.info(_logTag, 'Target USB device attached');
            if (!isConnected && !_isDisposed) {
              // Auto-connect when target device is attached
              connect().catchError((e) {
                Logger.error(_logTag, 'Auto-connect failed', e);
              });
            }
          } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
            Logger.info(_logTag, 'Target USB device detached');
            _updateStatus(RfidConnectionStatus.disconnected);
            _cleanup();
          }
        }
      },
      onError: (error) {
        Logger.error(_logTag, 'USB event monitoring error', error);
      },
    );
  }
  
  /// Update reader info with device details
  void _updateReaderInfo() {
    if (_targetDevice == null) return;
    
    _readerInfo = RfidReaderInfo(
      name: _targetDevice!.productName ?? 'USB RFID Reader',
      type: RfidReaderType.usbOtg,
      hardwareId: '${_targetDevice!.vid}:${_targetDevice!.pid}',
      manufacturer: _targetDevice!.manufacturerName,
      model: _targetDevice!.productName,
      supportedTagTypes: _readerInfo.supportedTagTypes,
      capabilities: _readerInfo.capabilities,
      connectionParams: {
        ..._config.toMap(),
        'vendor_id': _targetDevice!.vid,
        'product_id': _targetDevice!.pid,
        'serial_number': _targetDevice!.serial,
      },
    );
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
      await _usbPort?.close();
      _usbPort = null;
      _targetDevice = null;
      _dataBuffer.clear();
    } catch (e, stack) {
      Logger.error(_logTag, 'Error during cleanup', e, stack);
    }
  }
}

/// Configuration for USB-OTG RFID reader
class UsbOtgConfig {
  /// Target device vendor ID
  final int? vendorId;
  
  /// Target device product ID
  final int? productId;
  
  /// Target device product name (for discovery)
  final String? productName;
  
  /// Reader display name
  final String? readerName;
  
  /// Serial communication baud rate
  final int baudRate;
  
  /// Enable flow control (DTR/RTS)
  final bool flowControl;
  
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
  
  const UsbOtgConfig({
    this.vendorId,
    this.productId,
    this.productName,
    this.readerName,
    this.baudRate = 9600,
    this.flowControl = false,
    this.encoding = 'ascii',
    this.frameTerminators = const [[10]], // Default: LF
    this.maxBufferSize = 1024,
    this.scanCommand,
    this.stopCommand,
    this.removePrefix,
    this.removeSuffix,
    this.regexFilter,
  });
  
  /// Default configuration for common USB RFID readers
  factory UsbOtgConfig.defaultConfig() {
    return const UsbOtgConfig(
      baudRate: 9600,
      encoding: 'ascii',
      frameTerminators: [[10], [13, 10]], // LF and CRLF
      maxBufferSize: 1024,
    );
  }
  
  /// Configuration for specific reader models
  factory UsbOtgConfig.forModel(String model) {
    switch (model.toLowerCase()) {
      case 'acr122u':
        return const UsbOtgConfig(
          vendorId: 0x072F,
          productId: 0x2200,
          productName: 'ACR122U',
          baudRate: 115200,
        );
      
      case 'rdm6300':
        return const UsbOtgConfig(
          baudRate: 9600,
          encoding: 'hex',
          frameTerminators: [[0x03]], // ETX
          removePrefix: '02', // STX
          regexFilter: r'[0-9A-Fa-f]{10}',
        );
      
      default:
        return UsbOtgConfig.defaultConfig();
    }
  }
  
  /// Convert configuration to map
  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'product_id': productId,
      'product_name': productName,
      'reader_name': readerName,
      'baud_rate': baudRate,
      'flow_control': flowControl,
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