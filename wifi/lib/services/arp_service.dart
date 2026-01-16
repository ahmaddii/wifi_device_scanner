import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to read ARP (Address Resolution Protocol) table
/// ARP table maps IP addresses to MAC addresses
///
/// ANDROID ONLY - iOS does not expose ARP table
/// Location: /proc/net/arp
class ArpService {
  static const String _arpFilePath = '/proc/net/arp';

  /// Read and parse the ARP table
  /// Returns a map of IP address -> MAC address
  static Future<Map<String, String>> getArpTable() async {
    Map<String, String> arpTable = {};

    try {
      // Check if platform is Android
      if (!Platform.isAndroid) {
        debugPrint('⚠️ ARP table reading is only supported on Android');
        return arpTable;
      }

      // Read the ARP file
      final File arpFile = File(_arpFilePath);

      if (!await arpFile.exists()) {
        debugPrint('⚠️ ARP file not found at $_arpFilePath');
        return arpTable;
      }

      // Read file contents
      final String contents = await arpFile.readAsString();
      final List<String> lines = contents.split('\n');

      debugPrint('📋 ARP file has ${lines.length} lines');
      debugPrint('--- ARP Table Contents ---');
      debugPrint(contents);
      debugPrint('--- End ARP Table ---');

      // Skip header line (first line)
      for (int i = 1; i < lines.length; i++) {
        final String line = lines[i].trim();

        if (line.isEmpty) continue;

        debugPrint('Processing line $i: $line');

        // Split by whitespace (one or more spaces/tabs)
        final List<String> parts = line.split(RegExp(r'\s+'));

        debugPrint('  Parts (${parts.length}): $parts');

        // ARP table format: IP HW_Type Flags MAC Mask Device
        // Minimum 4 parts needed (IP, Type, Flags, MAC)
        if (parts.length >= 4) {
          final String ipAddress = parts[0];
          final String macAddress = parts[3];

          debugPrint('  Extracted - IP: $ipAddress, MAC: $macAddress');

          // Validate IP address format
          if (_isValidIpAddress(ipAddress)) {
            // Validate MAC - but be more lenient
            if (_isValidMacAddress(macAddress)) {
              arpTable[ipAddress] = macAddress;
              debugPrint('  ✅ Added to table');
            } else {
              debugPrint('  ❌ Invalid MAC format: $macAddress');
            }
          } else {
            debugPrint('  ❌ Invalid IP format: $ipAddress');
          }
        } else {
          debugPrint('  ⚠️ Insufficient parts in line');
        }
      }

      debugPrint('📋 ARP table parsed: ${arpTable.length} valid entries');
      arpTable.forEach((ip, mac) {
        debugPrint('  $ip -> $mac');
      });
    } catch (e) {
      debugPrint('❌ Error reading ARP table: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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
  static bool _isValidIpAddress(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length != 4) return false;

      for (final part in parts) {
        final num = int.tryParse(part);
        if (num == null || num < 0 || num > 255) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate MAC address format - MORE LENIENT
  /// Accepts various formats:
  /// - XX:XX:XX:XX:XX:XX (standard)
  /// - XX-XX-XX-XX-XX-XX (Windows style)
  /// - XXXXXXXXXXXX (no separators)
  static bool _isValidMacAddress(String mac) {
    try {
      // Check if MAC is all zeros or incomplete
      if (mac == '00:00:00:00:00:00' ||
          mac == '00-00-00-00-00-00' ||
          mac == '000000000000') {
        return false;
      }

      // Remove separators
      String cleanMac = mac
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceAll('.', '');

      // Should be 12 hex characters
      if (cleanMac.length != 12) {
        return false;
      }

      // Check if all characters are valid hex
      final hexRegex = RegExp(r'^[0-9A-Fa-f]{12}$');
      if (!hexRegex.hasMatch(cleanMac)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
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

  /// Force ARP cache refresh by pinging all devices
  /// This helps populate the ARP table before scanning
  static Future<void> refreshArpCache(
    String subnet, {
    int maxHosts = 254,
  }) async {
    debugPrint('🔄 Refreshing ARP cache for $subnet.*');

    List<Future<void>> pingFutures = [];

    for (int i = 1; i <= maxHosts; i++) {
      final ip = '$subnet.$i';

      // Quick ping to populate ARP
      final future = _quickPing(ip);
      pingFutures.add(future);

      // Don't overwhelm the system
      if (pingFutures.length >= 50) {
        await Future.wait(pingFutures);
        pingFutures.clear();
      }
    }

    // Wait for remaining pings
    if (pingFutures.isNotEmpty) {
      await Future.wait(pingFutures);
    }

    // Give ARP table time to update
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('✅ ARP cache refresh complete');
  }

  /// Quick ping to populate ARP cache
  static Future<void> _quickPing(String ip) async {
    try {
      await Socket.connect(
        ip,
        80, // Try HTTP port
        timeout: const Duration(milliseconds: 50),
      ).then((socket) => socket.destroy()).catchError((_) {});
    } catch (e) {
      // Ignore errors - we just want to populate ARP
    }
  }

  /// Clear cached ARP entries (requires root - NOT IMPLEMENTED)
  static Future<void> clearArpCache() async {
    debugPrint('⚠️ ARP cache clearing is not supported (requires root)');
  }
}
