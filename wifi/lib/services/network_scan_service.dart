import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import '../models/device_model.dart';
import 'arp_service.dart';
import 'mac_vendor_service.dart';

/// Enhanced service to scan local network and discover connected devices
///
/// MULTI-METHOD DETECTION:
/// 1. ARP Table Scan - Fastest, reads existing connections
/// 2. TCP Port Scan - Detects devices that block ping (like Linux/Mac)
/// 3. ICMP Ping Scan - Traditional ping method
///
/// This ensures we find ALL devices, even those with firewalls
class NetworkScanService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Current WiFi SSID
  String? currentSsid;

  /// Current device IP address
  String? currentIp;

  /// Gateway/Router IP address
  String? gatewayIp;

  /// Get current WiFi network information
  /// Returns true if connected to WiFi
  Future<bool> getWifiInfo() async {
    try {
      // Get WiFi SSID
      currentSsid = await _networkInfo.getWifiName();

      // Get device IP address
      currentIp = await _networkInfo.getWifiIP();

      // Get gateway IP (router)
      gatewayIp = await _networkInfo.getWifiGatewayIP();

      // Remove quotes from SSID (Android returns SSID with quotes)
      if (currentSsid != null) {
        currentSsid = currentSsid!.replaceAll('"', '');
      }

      debugPrint(
        'WiFi Info - SSID: $currentSsid, IP: $currentIp, Gateway: $gatewayIp',
      );

      // Check if connected to WiFi
      return currentSsid != null && currentIp != null && gatewayIp != null;
    } catch (e) {
      debugPrint('Error getting WiFi info: $e');
      return false;
    }
  }

  /// Enhanced scan with multiple detection methods
  /// Returns list of discovered devices
  ///
  /// [onProgress] callback receives progress percentage (0-100)
  Future<List<DeviceModel>> scanNetwork({Function(int)? onProgress}) async {
    List<DeviceModel> devices = [];
    Set<String> foundIps = {}; // Track unique IPs

    try {
      // Ensure we have network info
      if (currentIp == null || gatewayIp == null) {
        final connected = await getWifiInfo();
        if (!connected) {
          debugPrint('Not connected to WiFi');
          return devices;
        }
      }

      // Calculate subnet to scan
      final subnet = _getSubnet(currentIp!);
      if (subnet == null) {
        debugPrint('Invalid IP address format');
        return devices;
      }

      debugPrint('🔍 Starting enhanced network scan on $subnet.*');

      // PHASE 1: Quick ARP Table Scan (0-10%)
      debugPrint('📋 Phase 1: Reading ARP table...');
      if (onProgress != null) onProgress(5);

      final arpTable = await ArpService.getArpTable();
      debugPrint('Found ${arpTable.length} entries in ARP table');

      // Add devices from ARP table
      for (final entry in arpTable.entries) {
        if (entry.key.startsWith(subnet)) {
          foundIps.add(entry.key);
        }
      }

      if (onProgress != null) onProgress(10);

      // PHASE 2: TCP Port Scan (10-60%)
      // This finds devices that block ping (Linux, Mac, Windows with firewall)
      debugPrint('🔌 Phase 2: TCP port scanning...');

      List<int> commonPorts = [80, 443, 22, 445, 139, 8080, 53];
      int hostsToScan = 254;
      int scannedHosts = 0;

      List<Future<void>> scanFutures = [];

      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';

        final future = _tcpPortScan(ip, commonPorts).then((isActive) {
          if (isActive && !foundIps.contains(ip)) {
            foundIps.add(ip);
            debugPrint('✓ TCP scan found: $ip');
          }

          scannedHosts++;
          if (onProgress != null) {
            final progress = 10 + ((scannedHosts / hostsToScan) * 50).round();
            onProgress(progress);
          }
        });

        scanFutures.add(future);
      }

      await Future.wait(scanFutures);
      debugPrint('TCP scan complete. Total found: ${foundIps.length}');

      // PHASE 3: ICMP Ping Scan (60-90%)
      // Fallback for devices that respond to ping
      debugPrint('📡 Phase 3: ICMP ping scanning...');

      scannedHosts = 0;
      scanFutures.clear();

      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';

        // Skip if already found
        if (foundIps.contains(ip)) {
          scannedHosts++;
          continue;
        }

        final future = _pingHost(ip).then((isActive) {
          if (isActive && !foundIps.contains(ip)) {
            foundIps.add(ip);
            debugPrint('✓ Ping found: $ip');
          }

          scannedHosts++;
          if (onProgress != null) {
            final progress = 60 + ((scannedHosts / hostsToScan) * 30).round();
            onProgress(progress);
          }
        });

        scanFutures.add(future);
      }

      await Future.wait(scanFutures);
      debugPrint('Ping scan complete. Total found: ${foundIps.length}');

      // PHASE 4: Build device list (90-100%)
      debugPrint('📦 Phase 4: Building device list...');
      if (onProgress != null) onProgress(90);

      // Re-read ARP table (may have new entries after scanning)
      final finalArpTable = await ArpService.getArpTable();
      debugPrint('Final ARP table has ${finalArpTable.length} entries');

      // Create device models
      for (final ip in foundIps) {
        final macAddress = finalArpTable[ip];
        final vendor = MacVendorService.getVendor(macAddress);
        final isRouter = (ip == gatewayIp);

        final device = DeviceModel(
          ipAddress: ip,
          macAddress: macAddress,
          vendor: vendor,
          isRouter: isRouter,
        );

        devices.add(device);
      }

      // Sort devices: Router first, then by IP
      devices.sort((a, b) {
        if (a.isRouter) return -1;
        if (b.isRouter) return 1;
        return _compareIpAddresses(a.ipAddress, b.ipAddress);
      });

      if (onProgress != null) onProgress(100);
      debugPrint('✅ Scan complete! Found ${devices.length} devices');
    } catch (e) {
      debugPrint('Error during network scan: $e');
    }

    return devices;
  }

  /// TCP port scan to detect devices
  /// Tries to connect to common ports
  /// Returns true if any port is open
  Future<bool> _tcpPortScan(String ip, List<int> ports) async {
    try {
      // Try each port with very short timeout
      for (final port in ports) {
        try {
          final socket = await Socket.connect(
            ip,
            port,
            timeout: const Duration(milliseconds: 100),
          );
          socket.destroy();
          return true; // Port is open, device is active
        } catch (e) {
          // Port closed or timeout, try next port
          continue;
        }
      }
      return false; // No ports responded
    } catch (e) {
      return false;
    }
  }

  /// Ping a host to check if it's active
  /// Returns true if host responds
  Future<bool> _pingHost(String ip) async {
    try {
      final ping = Ping(ip, count: 1, timeout: 1);

      await for (final event in ping.stream) {
        if (event.response != null) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Extract subnet from IP address
  /// Example: 192.168.1.100 -> 192.168.1
  String? _getSubnet(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length != 4) return null;

      return '${parts[0]}.${parts[1]}.${parts[2]}';
    } catch (e) {
      return null;
    }
  }

  /// Compare two IP addresses for sorting
  int _compareIpAddresses(String ip1, String ip2) {
    try {
      final parts1 = ip1.split('.').map(int.parse).toList();
      final parts2 = ip2.split('.').map(int.parse).toList();

      for (int i = 0; i < 4; i++) {
        if (parts1[i] != parts2[i]) {
          return parts1[i].compareTo(parts2[i]);
        }
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Quick scan - only scan first 50 IPs (for testing)
  Future<List<DeviceModel>> quickScan({Function(int)? onProgress}) async {
    List<DeviceModel> devices = [];
    Set<String> foundIps = {};

    try {
      if (currentIp == null || gatewayIp == null) {
        final connected = await getWifiInfo();
        if (!connected) return devices;
      }

      final subnet = _getSubnet(currentIp!);
      if (subnet == null) return devices;

      debugPrint('Quick scan on $subnet.1-50');

      // Quick ARP read
      final arpTable = await ArpService.getArpTable();
      for (final entry in arpTable.entries) {
        if (entry.key.startsWith(subnet)) {
          foundIps.add(entry.key);
        }
      }

      // Scan first 50 IPs
      int scannedHosts = 0;
      int totalHosts = 50;

      List<Future<void>> scanFutures = [];

      for (int i = 1; i <= 50; i++) {
        final ip = '$subnet.$i';

        if (foundIps.contains(ip)) {
          scannedHosts++;
          continue;
        }

        final future =
            Future.wait([
              _tcpPortScan(ip, [80, 443, 22]),
              _pingHost(ip),
            ]).then((results) {
              if (results[0] || results[1]) {
                foundIps.add(ip);
              }

              scannedHosts++;
              if (onProgress != null) {
                final progress = ((scannedHosts / totalHosts) * 100).round();
                onProgress(progress);
              }
            });

        scanFutures.add(future);
      }

      await Future.wait(scanFutures);

      final finalArpTable = await ArpService.getArpTable();

      for (final ip in foundIps) {
        final macAddress = finalArpTable[ip];
        final vendor = MacVendorService.getVendor(macAddress);
        final isRouter = (ip == gatewayIp);

        devices.add(
          DeviceModel(
            ipAddress: ip,
            macAddress: macAddress,
            vendor: vendor,
            isRouter: isRouter,
          ),
        );
      }

      devices.sort((a, b) {
        if (a.isRouter) return -1;
        if (b.isRouter) return 1;
        return _compareIpAddresses(a.ipAddress, b.ipAddress);
      });
    } catch (e) {
      debugPrint('Error during quick scan: $e');
    }

    return devices;
  }
}
