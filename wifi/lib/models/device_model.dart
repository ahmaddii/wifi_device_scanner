/// Model representing a network device with hostname detection
class DeviceModel {
  final String ipAddress;
  final String? macAddress;
  final String? vendor;
  final String? hostname; // Device hostname (e.g., "realme-note-50")
  final bool isRouter;
  final bool isCurrentDevice;

  DeviceModel({
    required this.ipAddress,
    this.macAddress,
    this.vendor,
    this.hostname,
    this.isRouter = false,
    this.isCurrentDevice = false,
  });

  /// Get device type based on vendor
  DeviceType get deviceType {
    if (isRouter) return DeviceType.router;

    if (vendor != null) {
      final vendorLower = vendor!.toLowerCase();

      // Phone manufacturers
      if (vendorLower.contains('infinix') ||
          vendorLower.contains('realme') ||
          vendorLower.contains('xiaomi') ||
          vendorLower.contains('redmi') ||
          vendorLower.contains('oppo') ||
          vendorLower.contains('vivo') ||
          vendorLower.contains('samsung') ||
          vendorLower.contains('apple') ||
          vendorLower.contains('huawei') ||
          vendorLower.contains('oneplus') ||
          vendorLower.contains('tecno') ||
          vendorLower.contains('motorola')) {
        return DeviceType.phone;
      }

      // Computer manufacturers
      if (vendorLower.contains('dell') ||
          vendorLower.contains('hp') ||
          vendorLower.contains('lenovo') ||
          vendorLower.contains('asus') ||
          vendorLower.contains('acer') ||
          vendorLower.contains('microsoft') ||
          vendorLower.contains('intel')) {
        return DeviceType.computer;
      }
    }

    return DeviceType.unknown;
  }

  /// Display name - prioritize hostname, then vendor, then IP
  String get displayName {
    if (isCurrentDevice) {
      // Show device model from vendor if available
      if (vendor != null && vendor!.isNotEmpty) {
        return vendor!;
      }
      return 'My Device';
    }

    if (isRouter) {
      return ipAddress;
    }

    // Use hostname if available (e.g., "realme-note-50")
    if (hostname != null && hostname!.isNotEmpty) {
      return hostname!;
    }

    // Otherwise use vendor if available
    if (vendor != null && vendor!.isNotEmpty) {
      return vendor!;
    }

    // Fallback to IP
    return ipAddress;
  }

  /// Secondary label (shown below device name)
  String get displayLabel {
    if (isCurrentDevice) {
      return '(My Device)';
    }

    if (isRouter) {
      return '(Router)';
    }

    return 'Unknow'; // Match the screenshot spelling
  }
}

enum DeviceType { router, phone, computer, unknown }
