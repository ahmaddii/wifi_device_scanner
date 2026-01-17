import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/network_scan_service.dart';
import '../services/permission_service.dart';
import 'devices_list_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final NetworkScanService _scanService = NetworkScanService();

  String? _wifiSsid;
  String? _wifiIp;
  String? _gatewayIp;
  bool _isLoading = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // First request permissions
    final hasPermission = await PermissionService.requestWifiPermissions(
      context,
    );

    setState(() {
      _permissionGranted = hasPermission;
    });

    if (hasPermission) {
      await _loadWifiInfo();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWifiInfo() async {
    setState(() {
      _isLoading = true;
    });

    // Add a small delay to ensure permissions are properly set
    await Future.delayed(const Duration(milliseconds: 500));

    final connected = await _scanService.getWifiInfo();

    debugPrint('WiFi Connection Status: $connected');
    debugPrint('SSID: ${_scanService.currentSsid}');
    debugPrint('IP: ${_scanService.currentIp}');
    debugPrint('Gateway: ${_scanService.gatewayIp}');

    if (connected) {
      setState(() {
        _wifiSsid = _scanService.currentSsid;
        _wifiIp = _scanService.currentIp;
        _gatewayIp = _scanService.gatewayIp;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showNotConnectedDialog();
      }
    }
  }

  void _showNotConnectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Not Connected'),
        content: const Text(
          'Please connect to a WiFi network first.\n\n'
          'Make sure:\n'
          '• WiFi is turned on\n'
          '• You are connected to a network\n'
          '• Location permissions are granted',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initialize(); // Try again
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _startScanning() {
    if (!_permissionGranted) {
      _initialize();
      return;
    }

    if (_wifiSsid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to WiFi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DevicesListScreen(scanService: _scanService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C4A6D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C4A6D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Who is on my WiFi?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/loaders.json',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          const Text('Loading WiFi information...'),
                        ],
                      ),
                    )
                  : !_permissionGranted
                  ? _buildPermissionDenied()
                  : _buildWifiInfoCard(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Permissions Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please grant location/WiFi permissions\nto access network information',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initialize,
              icon: const Icon(Icons.refresh),
              label: const Text('Grant Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C4A6D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiInfoCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C4A6D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi,
                    size: 64,
                    color: Color(0xFF2C4A6D),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _wifiSsid ?? 'Unknown Network',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connected Network',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.phone_android, 'Your IP', _wifiIp ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.router, 'Gateway IP', _gatewayIp ?? 'N/A'),
                const SizedBox(height: 24),
                const Text(
                  'Tap "Scan" below to find all devices\nconnected to this network',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2C4A6D)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      color: const Color(0xFF2C4A6D),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Spacer(),
          ElevatedButton(
            onPressed: _isLoading ? null : _startScanning,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Scan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
