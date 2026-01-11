import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to read ARP (Address Resolution Protocol) table
/// ARP table maps IP addresses to MAC addresses
/// 
/// ANDROID ONLY - iOS does not expose ARP table
/// Location: /proc/net/arp
/// 
/// IMPORTANT NOTES:
/// - No root required (read-only file)
/// - Only shows devices that have recently communicated
/// - May not contain all devices immediately after scan
/// - Entries expire after inactivity
class ArpService {
  static const String _arpFilePath = '/proc/net/arp';

  /// Read and parse the ARP table
  /// Returns a map of IP address -> MAC address
  /// 
  /// Example ARP file format:
  /// IP address       HW type     Flags       HW address            Mask     Device
  /// 192.168.1.1      0x1         0x2         aa:bb:cc:dd:ee:ff     *        wlan0
  /// 192.168.1.5      0x1         0x2         11:22:33:44:55:66     *        wlan0
  static Future<Map<String, String>> getArpTable() async {
    Map<String, String> arpTable = {};

    try {
      // Check if platform is Android
      if (!Platform.isAndroid) {
        debugPrint('ARP table reading is only supported on Android');
        return arpTable;
      }

      // Read the ARP file
      final File arpFile = File(_arpFilePath);
      
      if (!await arpFile.exists()) {
        debugPrint('ARP file not found at $_arpFilePath');
        return arpTable;
      }

      // Read file contents
      final String contents = await arpFile.readAsString();
      final List<String> lines = contents.split('\n');

      // Skip header line (first line)
      for (int i = 1; i < lines.length; i++) {
        final String line = lines[i].trim();
        
        if (line.isEmpty) continue;

        // Split by whitespace
        final List<String> parts = line.split(RegExp(r'\s+'));

        // ARP table format has at least 6 columns
        // [IP, HW_Type, Flags, MAC, Mask, Device]
        if (parts.length >= 4) {
          final String ipAddress = parts[0];
          final String macAddress = parts[3];
          
          // Validate IP address format
          if (_isValidIpAddress(ipAddress) && _isValidMacAddress(macAddress)) {
            arpTable[ipAddress] = macAddress;
          }
        }
      }

      debugPrint('ARP table read successfully: ${arpTable.length} entries');
      
    } catch (e) {
      debugPrint('Error reading ARP table: $e');
    }

    return arpTable;
  }

  /// Get MAC address for a specific IP
  /// Returns null if not found
  static Future<String?> getMacForIp(String ipAddress) async {
    final arpTable = await getArpTable();
    return arpTable[ipAddress];
  }

  /// Validate IP address format
  /// Simple check for IPv4 format
  static bool _isValidIpAddress(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }

    return true;
  }

  /// Validate MAC address format
  /// Checks for standard MAC format (XX:XX:XX:XX:XX:XX)
  /// Also accepts incomplete MAC (00:00:00:00:00:00 is invalid)
  static bool _isValidMacAddress(String mac) {
    // Check if MAC is all zeros (incomplete entry)
    if (mac == '00:00:00:00:00:00') return false;
    
    // Check basic format
    final parts = mac.split(':');
    if (parts.length != 6) return false;

    for (final part in parts) {
      if (part.length != 2) return false;
      // Check if hexadecimal
      if (int.tryParse(part, radix: 16) == null) {
        return false;
      }
    }

    return true;
  }

  /// Check if ARP reading is available on current platform
  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final File arpFile = File(_arpFilePath);
      return await arpFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Clear cached ARP entries (requires root - NOT IMPLEMENTED)
  /// This is here for documentation purposes only
  /// 
  /// IMPORTANT: This app does NOT use root access
  /// To clear ARP cache, users would need root access and run:
  /// ip -s -s neigh flush all
  /// 
  /// This is NOT implemented in this app for Play Store compliance
  static Future<void> clearArpCache() async {
    debugPrint('ARP cache clearing is not supported (requires root)');
    // NO IMPLEMENTATION - requires root access
  }
}