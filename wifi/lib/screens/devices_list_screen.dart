import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/device_model.dart';
import '../services/network_scan_service.dart';
import '../widgets/device_list_item.dart';

class DevicesListScreen extends StatefulWidget {
  final NetworkScanService scanService;

  const DevicesListScreen({super.key, required this.scanService});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  List<DeviceModel> _devices = [];
  bool _isScanning = false;
  int _scanProgress = 0;

  @override
  void initState() {
    super.initState();
    _startScan(); // Auto-start scan when screen opens
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanProgress = 0;
      _devices = [];
    });

    try {
      final devices = await widget.scanService.scanNetwork(
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _scanProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Scan error: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          // Device List
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isScanning
                  ? _buildScanningProgress()
                  : _devices.isEmpty
                  ? const Center(
                      child: Text(
                        'No devices found',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : _buildDeviceList(),
            ),
          ),

          // Bottom Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildScanningProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie Animation
          Lottie.asset(
            'assets/loaders.json',
            width: 130,
            height: 130,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'Scanning network...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_scanProgress%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C4A6D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return DeviceListItem(
          device: device,
          onTap: () {
            _showDeviceDetails(device);
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      color: const Color(0xFF2C4A6D),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Device count
          if (!_isScanning && _devices.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '${_devices.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Devices Found',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Rescan button
          ElevatedButton(
            onPressed: _isScanning ? null : _startScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Rescan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeviceDetails(DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('IP Address', device.ipAddress),
            if (device.hostname != null)
              _buildDetailRow('Hostname', device.hostname!),
            if (device.vendor != null)
              _buildDetailRow('Vendor', device.vendor!),
            _buildDetailRow(
              'Type',
              device.deviceType.toString().split('.').last,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!device.isRouter && !device.isCurrentDevice)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showBlockDialog(device);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Block Device'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Device'),
        content: Text(
          'Are you sure you want to block ${device.displayName}?\n\n'
          'IP: ${device.ipAddress}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement blocking logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.displayName} has been blocked'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}
