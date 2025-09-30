import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';
import 'rfid/bluetooth_classic_rfid_reader.dart';
import 'rfid/usb_otg_rfid_reader.dart';
import 'rfid/rfid_reader_interface.dart';

/// RFID Service Provider
final rfidServiceProvider = StateNotifierProvider<RfidService, RfidServiceState>((ref) {
  return RfidService();
});

/// RFID Service State
class RfidServiceState {
  final RfidConnectionStatus connectionStatus;
  final RfidReaderType? activeReaderType;
  final RfidReaderInfo? readerInfo;
  final List<RfidTagReading> recentReadings;
  final String? errorMessage;
  
  const RfidServiceState({
    this.connectionStatus = RfidConnectionStatus.disconnected,
    this.activeReaderType,
    this.readerInfo,
    this.recentReadings = const [],
    this.errorMessage,
  });
  
  RfidServiceState copyWith({
    RfidConnectionStatus? connectionStatus,
    RfidReaderType? activeReaderType,
    RfidReaderInfo? readerInfo,
    List<RfidTagReading>? recentReadings,
    String? errorMessage,
  }) {
    return RfidServiceState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      activeReaderType: activeReaderType ?? this.activeReaderType,
      readerInfo: readerInfo ?? this.readerInfo,
      recentReadings: recentReadings ?? this.recentReadings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// RFID Service - Manages USB and Bluetooth RFID readers
class RfidService extends StateNotifier<RfidServiceState> {
  static const String _logTag = 'RfidService';
  
  // Available RFID readers
  RfidReaderInterface? _bluetoothReader;
  RfidReaderInterface? _usbReader;
  RfidReaderInterface? _activeReader;
  
  // Stream subscriptions
  final List<StreamSubscription> _subscriptions = [];
  
  RfidService() : super(const RfidServiceState()) {
    _initializeReaders();
  }
  
  /// Initialize available RFID readers
  Future<void> _initializeReaders() async {
    Logger.info(_logTag, 'Initializing RFID readers');
    
    try {
      // Initialize Bluetooth Classic reader
      _bluetoothReader = BluetoothClassicRfidReader();
      await _bluetoothReader!.initialize();
      Logger.info(_logTag, 'Bluetooth RFID reader initialized');
    } catch (e) {
      Logger.warning(_logTag, 'Bluetooth RFID reader not available: $e');
    }
    
    try {
      // Initialize USB-OTG reader
      _usbReader = UsbOtgRfidReader();
      await _usbReader!.initialize();
      Logger.info(_logTag, 'USB RFID reader initialized');
    } catch (e) {
      Logger.warning(_logTag, 'USB RFID reader not available: $e');
    }
  }
  
  /// Get available reader types
  List<RfidReaderType> getAvailableReaders() {
    final available = <RfidReaderType>[];
    
    if (_bluetoothReader != null) {
      available.add(RfidReaderType.bluetoothClassic);
    }
    
    if (_usbReader != null) {
      available.add(RfidReaderType.usbOtg);
    }
    
    return available;
  }
  
  /// Connect to specific reader type
  Future<void> connectToReader(RfidReaderType readerType) async {
    Logger.info(_logTag, 'Connecting to $readerType reader');
    
    // Disconnect current reader if any
    if (_activeReader != null) {
      await disconnectReader();
    }
    
    try {
      RfidReaderInterface? reader;
      
      switch (readerType) {
        case RfidReaderType.bluetoothClassic:
          reader = _bluetoothReader;
          break;
        case RfidReaderType.usbOtg:
          reader = _usbReader;
          break;
        default:
          throw UnsupportedError('Reader type $readerType not supported');
      }
      
      if (reader == null) {
        throw Exception('Reader not available or not initialized');
      }
      
      // Setup event listeners
      _setupReaderListeners(reader);
      
      // Connect to reader
      await reader.connect();
      
      _activeReader = reader;
      
      state = state.copyWith(
        activeReaderType: readerType,
        readerInfo: reader.readerInfo,
        connectionStatus: reader.currentStatus,
        errorMessage: null,
      );
      
      Logger.info(_logTag, 'Connected to $readerType reader successfully');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to connect to $readerType reader', e, stack);
      
      state = state.copyWith(
        connectionStatus: RfidConnectionStatus.error,
        errorMessage: e.toString(),
      );
      
      rethrow;
    }
  }
  
  /// Disconnect current reader
  Future<void> disconnectReader() async {
    if (_activeReader == null) return;
    
    Logger.info(_logTag, 'Disconnecting RFID reader');
    
    try {
      await _activeReader!.disconnect();
      _clearReaderListeners();
      
      state = state.copyWith(
        connectionStatus: RfidConnectionStatus.disconnected,
        activeReaderType: null,
        readerInfo: null,
        errorMessage: null,
      );
      
      _activeReader = null;
      
      Logger.info(_logTag, 'RFID reader disconnected');
      
    } catch (e, stack) {
      Logger.error(_logTag, 'Error disconnecting RFID reader', e, stack);
    }
  }
  
  /// Start scanning for RFID tags
  Future<void> startScanning() async {
    if (_activeReader == null) {
      throw Exception('No RFID reader connected');
    }
    
    Logger.info(_logTag, 'Starting RFID scanning');
    
    try {
      await _activeReader!.startScanning();
      Logger.info(_logTag, 'RFID scanning started');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to start RFID scanning', e, stack);
      rethrow;
    }
  }
  
  /// Stop scanning for RFID tags
  Future<void> stopScanning() async {
    if (_activeReader == null) return;
    
    Logger.info(_logTag, 'Stopping RFID scanning');
    
    try {
      await _activeReader!.stopScanning();
      Logger.info(_logTag, 'RFID scanning stopped');
    } catch (e, stack) {
      Logger.error(_logTag, 'Failed to stop RFID scanning', e, stack);
    }
  }
  
  /// Get recent tag readings
  List<RfidTagReading> getRecentReadings({int limit = 50}) {
    return state.recentReadings.take(limit).toList();
  }
  
  /// Clear recent readings
  void clearReadings() {
    state = state.copyWith(recentReadings: []);
  }
  
  /// Setup listeners for reader events
  void _setupReaderListeners(RfidReaderInterface reader) {
    // Listen to tag readings
    final tagSubscription = reader.tagReadings.listen(
      (reading) {
        Logger.info(_logTag, 'Tag reading: ${reading.tagId}');
        
        // Add to recent readings (keep last 100)
        final updatedReadings = [reading, ...state.recentReadings].take(100).toList();
        
        state = state.copyWith(recentReadings: updatedReadings);
      },
      onError: (error) {
        Logger.error(_logTag, 'Tag reading error', error);
      },
    );
    
    // Listen to connection status changes
    final statusSubscription = reader.connectionStatus.listen(
      (status) {
        Logger.info(_logTag, 'Connection status changed: $status');
        
        state = state.copyWith(
          connectionStatus: status,
          errorMessage: status == RfidConnectionStatus.error ? 'Connection error' : null,
        );
      },
      onError: (error) {
        Logger.error(_logTag, 'Connection status error', error);
      },
    );
    
    _subscriptions.addAll([tagSubscription, statusSubscription]);
  }
  
  /// Clear all reader listeners
  void _clearReaderListeners() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
  
  /// Check if scanning is active
  bool get isScanning => _activeReader?.isScanning ?? false;
  
  /// Check if reader is connected
  bool get isConnected => _activeReader?.isConnected ?? false;
  
  /// Get current reader info
  RfidReaderInfo? get currentReaderInfo => _activeReader?.readerInfo;
  
  @override
  void dispose() {
    Logger.info(_logTag, 'Disposing RFID service');
    
    _clearReaderListeners();
    _activeReader?.dispose();
    _bluetoothReader?.dispose();
    _usbReader?.dispose();
    
    super.dispose();
  }
}

/// Extension to get display name for reader type
extension RfidReaderTypeExtension on RfidReaderType {
  String get displayName {
    switch (this) {
      case RfidReaderType.bluetoothClassic:
        return 'Bluetooth RFID';
      case RfidReaderType.usbOtg:
        return 'USB RFID';
      default:
        return toString();
    }
  }
  
  String get description {
    switch (this) {
      case RfidReaderType.bluetoothClassic:
        return 'Connect RFID reader via Bluetooth';
      case RfidReaderType.usbOtg:
        return 'Connect RFID reader via USB cable';
      default:
        return '';
    }
  }
}