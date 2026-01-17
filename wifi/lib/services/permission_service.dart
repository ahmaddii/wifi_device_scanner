import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Service to handle runtime permissions for WiFi scanning
class PermissionService {
  /// Request all necessary permissions for WiFi scanning
  static Future<bool> requestWifiPermissions(BuildContext context) async {
    // Check Android version and request appropriate permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );

    if (!allGranted) {
      // Show dialog explaining why we need permissions
      if (context.mounted) {
        _showPermissionDeniedDialog(context, statuses);
      }
      return false;
    }

    return true;
  }

  /// Check if WiFi permissions are already granted
  static Future<bool> hasWifiPermissions() async {
    final locationStatus = await Permission.location.status;
    final wifiStatus = await Permission.nearbyWifiDevices.status;

    return (locationStatus.isGranted || locationStatus.isLimited) ||
        (wifiStatus.isGranted || wifiStatus.isLimited);
  }

  /// Show dialog when permissions are denied
  static void _showPermissionDeniedDialog(
    BuildContext context,
    Map<Permission, PermissionStatus> statuses,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs location/WiFi permissions to:\n\n'
          '• Read WiFi network name (SSID)\n'
          '• Get your IP address\n'
          '• Scan for devices on your network\n\n'
          'Note: We do NOT track your location. '
          'This is an Android requirement to access WiFi information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Request location permission specifically
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request nearby WiFi devices permission (Android 13+)
  static Future<bool> requestNearbyWifiPermission() async {
    final status = await Permission.nearbyWifiDevices.request();
    return status.isGranted || status.isLimited;
  }
}
