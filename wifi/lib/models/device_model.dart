import '../services/hostname_resolver_service.dart';

/// Model representing a network device
class DeviceModel {
  final String ipAddress;
  final String? macAddress;
  final String? vendor;
  final String? hostname;
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

  /// Get device type based on vendor and hostname
  DeviceType get deviceType {
    if (isRouter) return DeviceType.router;

    // Check hostname for clues
    if (hostname != null) {
      final hostnameLower = hostname!.toLowerCase();

      // Desktop/Laptop keywords
      if (hostnameLower.contains('desktop') ||
          hostnameLower.contains('laptop') ||
          hostnameLower.contains('pc') ||
          hostnameLower.contains('pop-os') ||
          hostnameLower.contains('ubuntu') ||
          hostnameLower.contains('fedora') ||
          hostnameLower.contains('arch') ||
          hostnameLower.contains('manjaro') ||
          hostnameLower.contains('mint')) {
        return DeviceType.computer;
      }

      // Mobile keywords
      if (hostnameLower.contains('android') ||
          hostnameLower.contains('iphone') ||
          hostnameLower.contains('ipad') ||
          hostnameLower.contains('realme') ||
          hostnameLower.contains('redmi') ||
          hostnameLower.contains('xiaomi') ||
          hostnameLower.contains('samsung') ||
          hostnameLower.contains('oppo') ||
          hostnameLower.contains('vivo') ||
          hostnameLower.contains('oneplus') ||
          hostnameLower.contains('infinix')) {
        return DeviceType.phone;
      }
    }

    // Check vendor
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
          vendorLower.contains('motorola') ||
          vendorLower.contains('nokia') ||
          vendorLower.contains('htc')) {
        return DeviceType.phone;
      }

      // Computer manufacturers
      if (vendorLower.contains('dell') ||
          vendorLower.contains('hp') ||
          vendorLower.contains('lenovo') ||
          vendorLower.contains('asus') ||
          vendorLower.contains('acer') ||
          vendorLower.contains('microsoft') ||
          vendorLower.contains('intel') ||
          vendorLower.contains('toshiba') ||
          vendorLower.contains('sony')) {
        return DeviceType.computer;
      }
    }

    return DeviceType.unknown;
  }

  /// Display name - smart detection
  String get displayName {
    // Current device
    if (isCurrentDevice) {
      if (hostname != null && hostname!.isNotEmpty) {
        return HostnameResolverService.formatHostname(hostname!);
      }
      if (vendor != null && vendor!.isNotEmpty) {
        return vendor!;
      }
      return 'My Device';
    }

    // Router
    if (isRouter) {
      if (hostname != null && hostname!.isNotEmpty) {
        return HostnameResolverService.formatHostname(hostname!);
      }
      return ipAddress;
    }

    // Priority: Hostname > Vendor > IP
    if (hostname != null && hostname!.isNotEmpty) {
      // Format hostname nicely
      return HostnameResolverService.formatHostname(hostname!);
    }

    if (vendor != null && vendor!.isNotEmpty) {
      return vendor!;
    }

    return ipAddress;
  }

  /// Secondary label
  String get displayLabel {
    if (isCurrentDevice) {
      return '(My Device)';
    }

    if (isRouter) {
      return '(Router)';
    }

    // Show vendor as secondary info if hostname is primary
    if (hostname != null && hostname!.isNotEmpty && vendor != null) {
      return vendor!;
    }

    return 'Unknown';
  }
}

enum DeviceType { router, phone, computer, unknown }
