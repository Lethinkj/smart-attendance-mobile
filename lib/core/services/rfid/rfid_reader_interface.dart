import 'dart:async';

/// Base interface for all RFID reader implementations
/// Provides a common contract for different reader types to ensure consistency
abstract class RfidReaderInterface {
  /// Stream of RFID tag readings
  Stream<RfidTagReading> get tagReadings;
  
  /// Stream of connection status changes
  Stream<RfidConnectionStatus> get connectionStatus;
  
  /// Current connection status
  RfidConnectionStatus get currentStatus;
  
  /// Initialize the RFID reader
  Future<void> initialize();
  
  /// Start scanning for RFID tags
  Future<void> startScanning();
  
  /// Stop scanning for RFID tags
  Future<void> stopScanning();
  
  /// Connect to RFID reader device
  Future<void> connect();
  
  /// Disconnect from RFID reader device
  Future<void> disconnect();
  
  /// Check if scanning is currently active
  bool get isScanning;
  
  /// Check if reader is connected
  bool get isConnected;
  
  /// Get reader capabilities and information
  RfidReaderInfo get readerInfo;
  
  /// Dispose resources and cleanup
  Future<void> dispose();
}

/// RFID tag reading data structure
class RfidTagReading {
  /// The RFID tag identifier (UID, EPC, etc.)
  final String tagId;
  
  /// Raw tag data (hex encoded)
  final String? rawData;
  
  /// RSSI signal strength (if available)
  final int? rssi;
  
  /// Timestamp when tag was read
  final DateTime timestamp;
  
  /// Reader type that detected the tag
  final RfidReaderType readerType;
  
  /// Additional tag metadata
  final Map<String, dynamic>? metadata;
  
  const RfidTagReading({
    required this.tagId,
    this.rawData,
    this.rssi,
    required this.timestamp,
    required this.readerType,
    this.metadata,
  });
  
  /// Create copy with updated fields
  RfidTagReading copyWith({
    String? tagId,
    String? rawData,
    int? rssi,
    DateTime? timestamp,
    RfidReaderType? readerType,
    Map<String, dynamic>? metadata,
  }) {
    return RfidTagReading(
      tagId: tagId ?? this.tagId,
      rawData: rawData ?? this.rawData,
      rssi: rssi ?? this.rssi,
      timestamp: timestamp ?? this.timestamp,
      readerType: readerType ?? this.readerType,
      metadata: metadata ?? this.metadata,
    );
  }
  
  @override
  String toString() {
    return 'RfidTagReading(tagId: $tagId, readerType: $readerType, timestamp: $timestamp)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RfidTagReading &&
        other.tagId == tagId &&
        other.timestamp == timestamp &&
        other.readerType == readerType;
  }
  
  @override
  int get hashCode => tagId.hashCode ^ timestamp.hashCode ^ readerType.hashCode;
}

/// RFID reader connection status
enum RfidConnectionStatus {
  /// Reader is disconnected and not available
  disconnected,
  
  /// Reader is attempting to connect
  connecting,
  
  /// Reader is connected but not scanning
  connected,
  
  /// Reader is connected and actively scanning
  scanning,
  
  /// Reader connection failed or lost
  error,
  
  /// Reader is pairing (for Bluetooth devices)
  pairing,
  
  /// Reader is not available or not supported
  unavailable,
}

/// RFID reader types supported by the application
enum RfidReaderType {
  /// Bluetooth Classic (SPP/Serial) RFID reader
  bluetoothClassic,
  
  /// Bluetooth Low Energy (BLE GATT) RFID reader
  bluetoothLowEnergy,
  
  /// USB-OTG connected RFID reader (Android only)
  usbOtg,
  
  /// NFC using phone's built-in NFC capability
  nfc,
  
  /// HID/Keyboard emulation RFID reader
  hidKeyboard,
  
  /// QR code scanning using camera
  qrCode,
}

/// RFID reader information and capabilities
class RfidReaderInfo {
  /// Reader display name
  final String name;
  
  /// Reader type
  final RfidReaderType type;
  
  /// Hardware identifier (MAC address, serial number, etc.)
  final String? hardwareId;
  
  /// Manufacturer information
  final String? manufacturer;
  
  /// Model information
  final String? model;
  
  /// Firmware version
  final String? firmwareVersion;
  
  /// Supported tag types
  final List<String> supportedTagTypes;
  
  /// Reader capabilities
  final List<String> capabilities;
  
  /// Connection parameters
  final Map<String, dynamic>? connectionParams;
  
  /// Battery level (if available)
  final int? batteryLevel;
  
  /// Signal strength or connection quality
  final int? signalStrength;
  
  const RfidReaderInfo({
    required this.name,
    required this.type,
    this.hardwareId,
    this.manufacturer,
    this.model,
    this.firmwareVersion,
    this.supportedTagTypes = const [],
    this.capabilities = const [],
    this.connectionParams,
    this.batteryLevel,
    this.signalStrength,
  });
  
  /// Get reader type display name
  String get typeDisplayName {
    switch (type) {
      case RfidReaderType.bluetoothClassic:
        return 'Bluetooth Classic';
      case RfidReaderType.bluetoothLowEnergy:
        return 'Bluetooth Low Energy';
      case RfidReaderType.usbOtg:
        return 'USB-OTG';
      case RfidReaderType.nfc:
        return 'NFC';
      case RfidReaderType.hidKeyboard:
        return 'HID/Keyboard';
      case RfidReaderType.qrCode:
        return 'QR Code';
    }
  }
  
  /// Check if reader supports specific capability
  bool hasCapability(String capability) {
    return capabilities.contains(capability);
  }
  
  /// Check if reader supports specific tag type
  bool supportsTagType(String tagType) {
    return supportedTagTypes.contains(tagType);
  }
  
  @override
  String toString() {
    return 'RfidReaderInfo(name: $name, type: $type, model: $model)';
  }
}

/// RFID reader exception
class RfidReaderException implements Exception {
  final String message;
  final RfidReaderType? readerType;
  final String? errorCode;
  final dynamic originalError;
  
  const RfidReaderException(
    this.message, {
    this.readerType,
    this.errorCode,
    this.originalError,
  });
  
  @override
  String toString() {
    return 'RfidReaderException: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
  }
}

/// RFID discovery result for available readers
class RfidDiscoveryResult {
  /// Available RFID readers
  final List<RfidReaderInfo> readers;
  
  /// Discovery timestamp
  final DateTime timestamp;
  
  /// Discovery duration
  final Duration duration;
  
  /// Any errors encountered during discovery
  final List<String> errors;
  
  const RfidDiscoveryResult({
    required this.readers,
    required this.timestamp,
    required this.duration,
    this.errors = const [],
  });
  
  /// Check if any readers were found
  bool get hasReaders => readers.isNotEmpty;
  
  /// Get readers by type
  List<RfidReaderInfo> getReadersByType(RfidReaderType type) {
    return readers.where((reader) => reader.type == type).toList();
  }
}