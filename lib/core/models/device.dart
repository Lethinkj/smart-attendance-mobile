import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

/// Device model for tracking registered devices
@HiveType(typeId: 4)
@JsonSerializable()
class Device extends HiveObject {
  /// Unique device identifier (UUID)
  @HiveField(0)
  final String uuid;
  
  /// Device name/label
  @HiveField(1)
  final String name;
  
  /// Device type (mobile, tablet, etc.)
  @HiveField(2)
  final String type;
  
  /// Operating system
  @HiveField(3)
  final String platform;
  
  /// OS version
  @HiveField(4)
  final String osVersion;
  
  /// App version
  @HiveField(5)
  final String appVersion;
  
  /// Device model/brand
  @HiveField(6)
  final String? model;
  
  /// User ID who registered the device
  @HiveField(7)
  final String userId;
  
  /// Device status (active, inactive, blocked)
  @HiveField(8)
  final String status;
  
  /// Last activity timestamp
  @HiveField(9)
  final DateTime? lastActiveAt;
  
  /// Device registration timestamp
  @HiveField(10)
  final DateTime registeredAt;
  
  /// Push notification token
  @HiveField(11)
  final String? pushToken;
  
  /// Supported RFID capabilities
  @HiveField(12)
  final List<String> rfidCapabilities;
  
  /// Device settings/preferences
  @HiveField(13)
  final Map<String, dynamic>? settings;
  
  Device({
    required this.uuid,
    required this.name,
    required this.type,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    this.model,
    required this.userId,
    this.status = 'active',
    this.lastActiveAt,
    DateTime? registeredAt,
    this.pushToken,
    this.rfidCapabilities = const [],
    this.settings,
  }) : registeredAt = registeredAt ?? DateTime.now();
  
  /// Create device from JSON
  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  
  /// Convert device to JSON
  Map<String, dynamic> toJson() => _$DeviceToJson(this);
  
  /// Create copy with updated fields
  Device copyWith({
    String? uuid,
    String? name,
    String? type,
    String? platform,
    String? osVersion,
    String? appVersion,
    String? model,
    String? userId,
    String? status,
    DateTime? lastActiveAt,
    DateTime? registeredAt,
    String? pushToken,
    List<String>? rfidCapabilities,
    Map<String, dynamic>? settings,
  }) {
    return Device(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      model: model ?? this.model,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      registeredAt: registeredAt ?? this.registeredAt,
      pushToken: pushToken ?? this.pushToken,
      rfidCapabilities: rfidCapabilities ?? this.rfidCapabilities,
      settings: settings ?? this.settings,
    );
  }
  
  /// Get device display name
  String get displayName {
    if (model != null) {
      return '$name ($model)';
    }
    return name;
  }
  
  /// Check if device is active
  bool get isActive => status == 'active';
  
  /// Check if device supports specific RFID capability
  bool supportsRfid(String capability) {
    return rfidCapabilities.contains(capability);
  }
  
  /// Check if device supports Bluetooth Classic RFID
  bool get supportsBluetoothClassic => supportsRfid('bluetooth_classic');
  
  /// Check if device supports BLE RFID
  bool get supportsBle => supportsRfid('ble');
  
  /// Check if device supports USB-OTG RFID
  bool get supportsUsbOtg => supportsRfid('usb_otg');
  
  /// Check if device supports NFC
  bool get supportsNfc => supportsRfid('nfc');
  
  /// Check if device supports HID/Keyboard input
  bool get supportsHid => supportsRfid('hid_keyboard');
  
  /// Get platform icon
  String get platformIcon {
    switch (platform.toLowerCase()) {
      case 'android':
        return '🤖';
      case 'ios':
        return '🍎';
      default:
        return '📱';
    }
  }
  
  /// Check if device is recently active (within last 24 hours)
  bool get isRecentlyActive {
    if (lastActiveAt == null) return false;
    final dayAgo = DateTime.now().subtract(const Duration(days: 1));
    return lastActiveAt!.isAfter(dayAgo);
  }
  
  /// Get time since last activity
  String? get lastActivityDisplay {
    if (lastActiveAt == null) return null;
    
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
  
  @override
  String toString() {
    return 'Device(uuid: $uuid, name: $name, platform: $platform, status: $status)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.uuid == uuid;
  }
  
  @override
  int get hashCode => uuid.hashCode;
}