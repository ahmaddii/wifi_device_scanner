import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device_model.dart';
import '../services/network_scan_service.dart';
import '../widgets/wifi_info_card.dart';
import '../widgets/device_list_item.dart';
import 'router_webview_screen.dart';

/// Main scan screen
/// Shows WiFi info, scan button, and list of discovered devices
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final NetworkScanService _scanService = NetworkScanService();

  List<DeviceModel> _devices = [];
  bool _isScanning = false;
  bool _hasScanned = false;
  int _scanProgress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWifiInfo();
  }

  /// Initialize WiFi information on screen load
  Future<void> _initializeWifiInfo() async {
    await _scanService.getWifiInfo();
    setState(() {});
  }

  /// Request necessary permissions
  /// Location permission required for WiFi SSID on Android 10+
  Future<bool> _requestPermissions() async {
    // Check if permissions are already granted
    if (await Permission.location.isGranted) {
      return true;
    }

    // Request location permission
    final status = await Permission.location.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      if (mounted) {
        _showPermissionDialog();
      }
      return false;
    } else {
      // Permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to scan WiFi'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Show dialog when permission is permanently denied
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Location permission is required to access WiFi information. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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

  /// Start network scan
  Future<void> _startScan() async {
    // Request permissions first
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return;

    setState(() {
      _isScanning = true;
      _hasScanned = true;
      _scanProgress = 0;
      _errorMessage = null;
      _devices = [];
    });

    try {
      // Get WiFi info
      final connected = await _scanService.getWifiInfo();

      if (!connected) {
        setState(() {
          _errorMessage =
              'Not connected to WiFi. Please connect and try again.';
          _isScanning = false;
        });
        return;
      }

      // Scan network
      final devices = await _scanService.scanNetwork(
        onProgress: (progress) {
          setState(() {
            _scanProgress = progress;
          });
        },
      );

      setState(() {
        _devices = devices;
        _isScanning = false;
      });

      // Show result message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${devices.length} devices on your network'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during scan: $e';
        _isScanning = false;
      });
    }
  }

  /// Open router admin panel in WebView
  void _openRouterPanel(DeviceModel device) {
    if (_scanService.gatewayIp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Router IP not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to WebView screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouterWebViewScreen(
          routerIp: _scanService.gatewayIp!,
          targetDevice: device,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WiFi Scanner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // WiFi Info Card
          WifiInfoCard(
            ssid: _scanService.currentSsid,
            ipAddress: _scanService.currentIp,
            gateway: _scanService.gatewayIp,
          ),

          // Scan Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isScanning ? 'Scanning... $_scanProgress%' : 'Scan Network',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Device List or Messages
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// Build content based on current state
  Widget _buildContent() {
    // Show error message
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading
    if (_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Scanning network... $_scanProgress%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take a minute',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show device list
    if (_devices.isNotEmpty) {
      return ListView.builder(
        itemCount: _devices.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Found ${_devices.length} devices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            );
          }

          final device = _devices[index - 1];
          return DeviceListItem(
            device: device,
            onBlockTapped: () => _openRouterPanel(device),
          );
        },
      );
    }

    // Show initial message
    if (!_hasScanned) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_find, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              const Text(
                'Tap "Scan Network" to discover\ndevices connected to your WiFi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    // Show no devices found
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No devices found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try scanning again',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
