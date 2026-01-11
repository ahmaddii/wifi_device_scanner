/// Model representing a network device
/// Contains IP, MAC address, vendor info, and device type
class DeviceModel {
  final String ipAddress;
  final String? macAddress; // Nullable - may not be available on all platforms
  final String? vendor; // Device manufacturer (Apple, Samsung, etc.)
  final bool isRouter; // True if this is the gateway/router
  final DateTime discoveredAt;

  DeviceModel({
    required this.ipAddress,
    this.macAddress,
    this.vendor,
    this.isRouter = false,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  /// Get device type icon based on vendor and router status
  DeviceType get deviceType {
    if (isRouter) return DeviceType.router;
    
    if (vendor != null) {
      final vendorLower = vendor!.toLowerCase();
      
      // Check for common device types based on vendor
      if (vendorLower.contains('apple') || 
          vendorLower.contains('iphone') ||
          vendorLower.contains('ipad')) {
        return DeviceType.phone;
      }
      
      if (vendorLower.contains('samsung') ||
          vendorLower.contains('huawei') ||
          vendorLower.contains('xiaomi') ||
          vendorLower.contains('oppo') ||
          vendorLower.contains('vivo') ||
          vendorLower.contains('oneplus')) {
        return DeviceType.phone;
      }
      
      if (vendorLower.contains('tp-link') ||
          vendorLower.contains('cisco') ||
          vendorLower.contains('netgear') ||
          vendorLower.contains('asus') ||
          vendorLower.contains('d-link')) {
        return DeviceType.router;
      }
      
      if (vendorLower.contains('dell') ||
          vendorLower.contains('hp') ||
          vendorLower.contains('lenovo') ||
          vendorLower.contains('acer') ||
          vendorLower.contains('asus')) {
        return DeviceType.computer;
      }
    }
    
    return DeviceType.unknown;
  }

  /// Get display name for vendor
  String get displayVendor {
    if (isRouter) return 'Router (Gateway)';
    return vendor ?? 'Unknown Vendor';
  }

  /// Get display name for MAC address
  String get displayMac {
    if (macAddress == null || macAddress!.isEmpty) {
      return 'MAC: Not available';
    }
    return 'MAC: ${macAddress!.toUpperCase()}';
  }

  @override
  String toString() {
    return 'Device{IP: $ipAddress, MAC: ${macAddress ?? "N/A"}, Vendor: ${vendor ?? "Unknown"}, Router: $isRouter}';
  }

  /// Create a copy with updated fields
  DeviceModel copyWith({
    String? ipAddress,
    String? macAddress,
    String? vendor,
    bool? isRouter,
    DateTime? discoveredAt,
  }) {
    return DeviceModel(
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      vendor: vendor ?? this.vendor,
      isRouter: isRouter ?? this.isRouter,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }
}

/// Enum for device types
enum DeviceType {
  router,
  phone,
  computer,
  unknown,
}