import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import '../models/device_model.dart';

/// Network scanner with hostname detection
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

  /// Scan network and detect hostnames
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

      debugPrint('🔍 Starting network scan on $subnet.*');

      // PHASE 1: Quick ping scan (0-40%)
      debugPrint('📡 Phase 1: Ping scanning...');

      int scannedHosts = 0;
      int totalHosts = 254;
      List<Future<void>> scanFutures = [];

      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';

        final future = _pingHost(ip).then((isActive) {
          if (isActive) {
            foundIps.add(ip);
            debugPrint('✓ Found: $ip');
          }

          scannedHosts++;
          if (onProgress != null) {
            final progress = ((scannedHosts / totalHosts) * 40).round();
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
      debugPrint('Ping scan complete. Found: ${foundIps.length} devices');

      // PHASE 2: TCP port scan for missed devices (40-70%)
      debugPrint('🔌 Phase 2: TCP port scanning...');

      List<int> commonPorts = [80, 443, 8080, 22];
      scannedHosts = 0;
      scanFutures.clear();

      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';

        if (foundIps.contains(ip)) {
          scannedHosts++;
          continue;
        }

        final future = _tcpPortScan(ip, commonPorts).then((isActive) {
          if (isActive) {
            foundIps.add(ip);
            debugPrint('✓ TCP found: $ip');
          }

          scannedHosts++;
          if (onProgress != null) {
            final progress = 40 + ((scannedHosts / totalHosts) * 30).round();
            onProgress(progress);
          }
        });

        scanFutures.add(future);

        if (scanFutures.length >= 50) {
          await Future.wait(scanFutures);
          scanFutures.clear();
        }
      }

      await Future.wait(scanFutures);
      debugPrint('TCP scan complete. Total found: ${foundIps.length}');

      // PHASE 3: Resolve hostnames and build device list (70-100%)
      debugPrint('📦 Phase 3: Resolving hostnames...');
      if (onProgress != null) onProgress(75);

      int processedDevices = 0;
      List<Future<DeviceModel>> deviceFutures = [];

      for (final ip in foundIps) {
        deviceFutures.add(_createDeviceModel(ip));

        if (deviceFutures.length >= 10) {
          final batchDevices = await Future.wait(deviceFutures);
          devices.addAll(batchDevices);

          processedDevices += batchDevices.length;
          if (onProgress != null) {
            final progress =
                75 + ((processedDevices / foundIps.length) * 25).round();
            onProgress(progress);
          }

          deviceFutures.clear();
        }
      }

      if (deviceFutures.isNotEmpty) {
        final batchDevices = await Future.wait(deviceFutures);
        devices.addAll(batchDevices);
      }

      // Sort: Current device first, then router, then by IP
      devices.sort((a, b) {
        if (a.isCurrentDevice) return -1;
        if (b.isCurrentDevice) return 1;
        if (a.isRouter) return -1;
        if (b.isRouter) return 1;
        return _compareIpAddresses(a.ipAddress, b.ipAddress);
      });

      if (onProgress != null) onProgress(100);
      debugPrint('✅ Scan complete! Found ${devices.length} devices');

      // Print summary
      debugPrint('═══════════════════════════════════════');
      debugPrint('SCAN SUMMARY');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Total Devices: ${devices.length}');
      for (final device in devices) {
        debugPrint(
          '${device.isCurrentDevice
              ? "📱"
              : device.isRouter
              ? "🌐"
              : "📱"} ${device.displayName}',
        );
        debugPrint('   IP: ${device.ipAddress}');
        debugPrint('   Hostname: ${device.hostname ?? "N/A"}');
      }
      debugPrint('═══════════════════════════════════════');
    } catch (e) {
      debugPrint('Error during network scan: $e');
    }

    return devices;
  }

  /// Create device model with hostname detection
  Future<DeviceModel> _createDeviceModel(String ip) async {
    final isRouter = (ip == gatewayIp);
    final isCurrentDevice = (ip == currentIp);

    String? hostname;
    String? vendor;

    try {
      // Try to resolve hostname
      final result = await InternetAddress.lookup(
        ip,
      ).timeout(const Duration(milliseconds: 500));

      if (result.isNotEmpty && result.first.host != ip) {
        hostname = result.first.host;
        debugPrint('Resolved hostname for $ip: $hostname');

        // Extract vendor from hostname if possible
        vendor = _extractVendorFromHostname(hostname);
      }
    } catch (e) {
      debugPrint('Could not resolve hostname for $ip');
    }

    // For current device, try to get device model
    if (isCurrentDevice && vendor == null) {
      vendor = await _getCurrentDeviceModel();
    }

    return DeviceModel(
      ipAddress: ip,
      hostname: hostname,
      vendor: vendor,
      isRouter: isRouter,
      isCurrentDevice: isCurrentDevice,
    );
  }

  /// Extract vendor name from hostname
  String? _extractVendorFromHostname(String hostname) {
    final hostnameLower = hostname.toLowerCase();

    // Common phone brands
    if (hostnameLower.contains('infinix'))
      return 'Infinix ${_extractModel(hostname)}';
    if (hostnameLower.contains('realme'))
      return 'Realme ${_extractModel(hostname)}';
    if (hostnameLower.contains('redmi'))
      return 'Redmi ${_extractModel(hostname)}';
    if (hostnameLower.contains('xiaomi'))
      return 'Xiaomi ${_extractModel(hostname)}';
    if (hostnameLower.contains('oppo'))
      return 'OPPO ${_extractModel(hostname)}';
    if (hostnameLower.contains('vivo'))
      return 'vivo ${_extractModel(hostname)}';
    if (hostnameLower.contains('samsung'))
      return 'Samsung ${_extractModel(hostname)}';
    if (hostnameLower.contains('iphone')) return 'iPhone';
    if (hostnameLower.contains('oneplus'))
      return 'OnePlus ${_extractModel(hostname)}';
    if (hostnameLower.contains('huawei'))
      return 'Huawei ${_extractModel(hostname)}';
    if (hostnameLower.contains('tecno'))
      return 'Tecno ${_extractModel(hostname)}';

    return null;
  }

  /// Extract model from hostname (e.g., "realme-note-50" -> "Note 50")
  String _extractModel(String hostname) {
    // Remove brand name and clean up
    String model = hostname
        .toLowerCase()
        .replaceAll('infinix-', '')
        .replaceAll('realme-', '')
        .replaceAll('redmi-', '')
        .replaceAll('xiaomi-', '')
        .replaceAll('oppo-', '')
        .replaceAll('vivo-', '')
        .replaceAll('samsung-', '')
        .replaceAll('oneplus-', '')
        .replaceAll('huawei-', '')
        .replaceAll('tecno-', '');

    // Capitalize and format
    return model
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .trim();
  }

  /// Get current device model (Android only)
  Future<String?> _getCurrentDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        // Try to read from system properties
        final result = await Process.run('getprop', ['ro.product.model']);
        if (result.exitCode == 0) {
          final model = result.stdout.toString().trim();
          if (model.isNotEmpty) {
            return model;
          }
        }
      }
    } catch (e) {
      debugPrint('Could not get device model: $e');
    }
    return null;
  }

  /// TCP port scan
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

  /// Ping a host
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

  /// Extract subnet from IP
  String? _getSubnet(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length != 4) return null;
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    } catch (e) {
      return null;
    }
  }

  /// Compare IP addresses
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
}
