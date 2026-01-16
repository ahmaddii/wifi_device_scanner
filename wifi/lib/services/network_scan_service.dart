import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import '../models/device_model.dart';
import 'arp_service.dart';
import 'mac_vendor_service.dart';

/// Enhanced network scanner with proper vendor lookup and MAC resolution
class NetworkScanService {
  final NetworkInfo _networkInfo = NetworkInfo();

  String? currentSsid;
  String? currentIp;
  String? gatewayIp;

  /// Get current WiFi network information
  Future<bool> getWifiInfo() async {
    try {
      currentSsid = await _networkInfo.getWifiName();
      currentIp = await _networkInfo.getWifiIP();
      gatewayIp = await _networkInfo.getWifiGatewayIP();

      if (currentSsid != null) {
        currentSsid = currentSsid!.replaceAll('"', '');
      }

      debugPrint(
        'WiFi Info - SSID: $currentSsid, IP: $currentIp, Gateway: $gatewayIp',
      );

      return currentSsid != null && currentIp != null && gatewayIp != null;
    } catch (e) {
      debugPrint('Error getting WiFi info: $e');
      return false;
    }
  }

  /// Enhanced scan with ARP refresh and vendor lookup
  Future<List<DeviceModel>> scanNetwork({Function(int)? onProgress}) async {
    List<DeviceModel> devices = [];
    Set<String> foundIps = {};

    try {
      if (currentIp == null || gatewayIp == null) {
        final connected = await getWifiInfo();
        if (!connected) {
          debugPrint('Not connected to WiFi');
          return devices;
        }
      }

      final subnet = _getSubnet(currentIp!);
      if (subnet == null) {
        debugPrint('Invalid IP address format');
        return devices;
      }

      debugPrint('🔍 Starting enhanced network scan on $subnet.*');

      // PHASE 0: Initial ARP Table Read (0-5%)
      debugPrint('📋 Phase 0: Initial ARP table read...');
      if (onProgress != null) onProgress(2);

      final initialArpTable = await ArpService.getArpTable();
      debugPrint('Initial ARP entries: ${initialArpTable.length}');

      for (final entry in initialArpTable.entries) {
        if (entry.key.startsWith(subnet)) {
          foundIps.add(entry.key);
        }
      }

      if (onProgress != null) onProgress(5);

      // PHASE 1: ARP Cache Refresh (5-15%)
      debugPrint('🔄 Phase 1: Refreshing ARP cache...');
      
      await ArpService.refreshArpCache(subnet);
      
      if (onProgress != null) onProgress(15);

      // PHASE 2: Read refreshed ARP table (15-20%)
      debugPrint('📋 Phase 2: Reading refreshed ARP table...');
      
      final refreshedArpTable = await ArpService.getArpTable();
      debugPrint('Refreshed ARP entries: ${refreshedArpTable.length}');

      for (final entry in refreshedArpTable.entries) {
        if (entry.key.startsWith(subnet)) {
          foundIps.add(entry.key);
        }
      }

      if (onProgress != null) onProgress(20);

      // PHASE 3: TCP Port Scan (20-60%)
      debugPrint('🔌 Phase 3: TCP port scanning...');

      List<int> commonPorts = [80, 443, 8080, 22, 445, 139, 53];
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
            final progress = 20 + ((scannedHosts / hostsToScan) * 40).round();
            onProgress(progress);
          }
        });

        scanFutures.add(future);

        // Process in batches to avoid overwhelming the system
        if (scanFutures.length >= 50) {
          await Future.wait(scanFutures);
          scanFutures.clear();
        }
      }

      await Future.wait(scanFutures);
      debugPrint('TCP scan complete. Total found: ${foundIps.length}');

      // PHASE 4: ICMP Ping Scan (60-80%)
      debugPrint('📡 Phase 4: ICMP ping scanning...');

      scannedHosts = 0;
      scanFutures.clear();

      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';

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
            final progress = 60 + ((scannedHosts / hostsToScan) * 20).round();
            onProgress(progress);
          }
        });

        scanFutures.add(future);

        // Process in batches
        if (scanFutures.length >= 50) {
          await Future.wait(scanFutures);
          scanFutures.clear();
        }
      }

      await Future.wait(scanFutures);
      debugPrint('Ping scan complete. Total found: ${foundIps.length}');

      // PHASE 5: Final ARP read and device building (80-100%)
      debugPrint('📦 Phase 5: Building device list with vendor lookup...');
      if (onProgress != null) onProgress(85);

      // Final ARP table read to get MACs for all discovered IPs
      final finalArpTable = await ArpService.getArpTable();
      debugPrint('Final ARP table has ${finalArpTable.length} entries');

      // Create device models with vendor lookup
      int processedDevices = 0;
      List<Future<DeviceModel>> deviceFutures = [];

      for (final ip in foundIps) {
        deviceFutures.add(_createDeviceModel(ip, finalArpTable[ip]));
        
        // Process in batches to show progress
        if (deviceFutures.length >= 10) {
          final batchDevices = await Future.wait(deviceFutures);
          devices.addAll(batchDevices);
          
          processedDevices += batchDevices.length;
          if (onProgress != null) {
            final progress = 85 + ((processedDevices / foundIps.length) * 15).round();
            onProgress(progress);
          }
          
          deviceFutures.clear();
        }
      }

      // Process remaining devices
      if (deviceFutures.isNotEmpty) {
        final batchDevices = await Future.wait(deviceFutures);
        devices.addAll(batchDevices);
      }

      // Sort devices: Router first, then by IP
      devices.sort((a, b) {
        if (a.isRouter) return -1;
        if (b.isRouter) return 1;
        return _compareIpAddresses(a.ipAddress, b.ipAddress);
      });

      if (onProgress != null) onProgress(100);
      debugPrint('✅ Scan complete! Found ${devices.length} devices');

      // Print detailed summary
      int devicesWithMac = devices.where((d) => d.macAddress != null && d.macAddress!.isNotEmpty).length;
      int devicesWithVendor = devices.where((d) => d.vendor != null).length;
      
      debugPrint('═══════════════════════════════════════');
      debugPrint('SCAN SUMMARY');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Total Devices: ${devices.length}');
      debugPrint('With MAC Address: $devicesWithMac/${devices.length}');
      debugPrint('With Vendor Info: $devicesWithVendor/${devices.length}');
      debugPrint('═══════════════════════════════════════');
      
      // Print each device
      for (final device in devices) {
        debugPrint('${device.isRouter ? "🌐" : "📱"} ${device.ipAddress}');
        debugPrint('   MAC: ${device.macAddress ?? "Unknown"}');
        debugPrint('   Vendor: ${device.vendor ?? "Unknown"}');
      }
      debugPrint('═══════════════════════════════════════');
      
    } catch (e) {
      debugPrint('Error during network scan: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }

    return devices;
  }

  /// Create a device model with vendor lookup
  Future<DeviceModel> _createDeviceModel(String ip, String? macAddress) async {
    String? vendor;
    
    if (macAddress != null && macAddress.isNotEmpty) {
      vendor = await EnhancedMacVendorService.getVendor(macAddress);
    } else {
      debugPrint('⚠️ No MAC address for IP: $ip');
    }

    final isRouter = (ip == gatewayIp);

    return DeviceModel(
      ipAddress: ip,
      macAddress: macAddress,
      vendor: vendor,
      isRouter: isRouter,
    );
  }

  /// TCP port scan to detect devices
  Future<bool> _tcpPortScan(String ip, List<int> ports) async {
    try {
      for (final port in ports) {
        try {
          final socket = await Socket.connect(
            ip,
            port,
            timeout: const Duration(milliseconds: 100),
          );
          socket.destroy();
          return true;
        } catch (e) {
          continue;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Ping a host to check if it's active
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

      // Refresh ARP cache first
      await ArpService.refreshArpCache(subnet, maxHosts: 50);

      final arpTable = await ArpService.getArpTable();
      for (final entry in arpTable.entries) {
        if (entry.key.startsWith(subnet)) {
          foundIps.add(entry.key);
        }
      }

      int scannedHosts = 0;
      int totalHosts = 50;

      List<Future<void>> scanFutures = [];

      for (int i = 1; i <= 50; i++) {
        final ip = '$subnet.$i';

        if (foundIps.contains(ip)) {
          scannedHosts++;
          continue;
        }

        final future = Future.wait([
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
        final device = await _createDeviceModel(ip, finalArpTable[ip]);
        devices.add(device);
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