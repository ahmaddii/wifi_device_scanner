import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to resolve hostnames for IP addresses using multiple methods
class HostnameResolverService {
  /// Try to get hostname using multiple methods
  static Future<String?> getHostname(String ipAddress) async {
    String? hostname;

    // Method 1: DNS reverse lookup
    hostname = await _dnsReverseLookup(ipAddress);
    if (hostname != null && hostname != ipAddress) {
      debugPrint('✅ DNS lookup found: $hostname for $ipAddress');
      return _cleanHostname(hostname);
    }

    // Method 2: NBT-NS lookup (Windows/Samba devices)
    hostname = await _nbtLookup(ipAddress);
    if (hostname != null) {
      debugPrint('✅ NBT lookup found: $hostname for $ipAddress');
      return _cleanHostname(hostname);
    }

    // Method 3: mDNS lookup (Apple/Linux devices)
    hostname = await _mdnsLookup(ipAddress);
    if (hostname != null) {
      debugPrint('✅ mDNS lookup found: $hostname for $ipAddress');
      return _cleanHostname(hostname);
    }

    debugPrint('❌ No hostname found for $ipAddress');
    return null;
  }

  /// DNS reverse lookup
  static Future<String?> _dnsReverseLookup(String ipAddress) async {
    try {
      final result = await InternetAddress.lookup(
        ipAddress,
      ).timeout(const Duration(seconds: 2));

      if (result.isNotEmpty && result.first.host != ipAddress) {
        return result.first.host;
      }
    } catch (e) {
      debugPrint('DNS lookup failed for $ipAddress: $e');
    }
    return null;
  }

  /// NBT-NS lookup using nmblookup (for Windows/Samba devices)
  static Future<String?> _nbtLookup(String ipAddress) async {
    if (!Platform.isAndroid && !Platform.isLinux) return null;

    try {
      // Try nmblookup command (available on some Android devices with busybox)
      final result = await Process.run('nmblookup', [
        '-A',
        ipAddress,
      ], runInShell: true).timeout(const Duration(seconds: 2));

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Parse output for hostname
        final lines = output.split('\n');
        for (final line in lines) {
          if (line.contains('<00>') && !line.contains('<GROUP>')) {
            final hostname = line.trim().split(' ').first;
            if (hostname.isNotEmpty) {
              return hostname;
            }
          }
        }
      }
    } catch (e) {
      // nmblookup not available, skip
    }
    return null;
  }

  /// mDNS lookup (for Apple/Linux devices)
  static Future<String?> _mdnsLookup(String ipAddress) async {
    try {
      // Try avahi-resolve command (Linux/Android with avahi)
      final result = await Process.run('avahi-resolve', [
        '-a',
        ipAddress,
      ], runInShell: true).timeout(const Duration(seconds: 2));

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          final parts = output.split('\t');
          if (parts.length > 1) {
            return parts[1];
          }
        }
      }
    } catch (e) {
      // avahi not available, skip
    }
    return null;
  }

  /// Clean and format hostname
  static String _cleanHostname(String hostname) {
    // Remove domain suffixes
    hostname = hostname
        .replaceAll('.local', '')
        .replaceAll('.lan', '')
        .replaceAll('.home', '');

    // Remove trailing dots
    if (hostname.endsWith('.')) {
      hostname = hostname.substring(0, hostname.length - 1);
    }

    return hostname;
  }

  /// Extract device name from hostname
  /// Examples: "realme-note-50" -> "Realme Note 50"
  ///          "pop-os" -> "Pop OS"
  ///          "DESKTOP-ABC123" -> "DESKTOP-ABC123"
  static String formatHostname(String hostname) {
    // Common patterns to clean up
    hostname = hostname
        .replaceAll('_', '-')
        .replaceAll('.local', '')
        .replaceAll('.lan', '');

    // Check for common patterns
    if (hostname.toLowerCase().startsWith('android-')) {
      return 'Android Device';
    }

    if (hostname.toLowerCase().startsWith('desktop-') ||
        hostname.toLowerCase().startsWith('laptop-')) {
      return hostname; // Keep as-is for Windows devices
    }

    // For hyphenated names (realme-note-50, pop-os)
    if (hostname.contains('-')) {
      final parts = hostname.split('-');
      final formatted = parts
          .map(
            (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
          )
          .join(' ');
      return formatted;
    }

    // Capitalize first letter
    return hostname[0].toUpperCase() + hostname.substring(1);
  }
}
