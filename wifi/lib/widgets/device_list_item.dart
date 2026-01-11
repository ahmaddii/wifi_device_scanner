import 'package:flutter/material.dart';
import '../models/device_model.dart';

/// Widget displaying a single network device in the list
/// Shows icon, IP, MAC, vendor, and Block button
class DeviceListItem extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onBlockTapped;

  const DeviceListItem({
    super.key,
    required this.device,
    required this.onBlockTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Device Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getDeviceColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getDeviceIcon(),
                color: _getDeviceColor(),
                size: 32,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor / Device Name
                  Text(
                    device.displayVendor,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // IP Address
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.ipAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // MAC Address
                  Row(
                    children: [
                      const Icon(
                        Icons.label,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          device.displayMac,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Block Button
            if (!device.isRouter) // Don't show block button for router
              ElevatedButton.icon(
                onPressed: onBlockTapped,
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Block'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get icon based on device type
  IconData _getDeviceIcon() {
    switch (device.deviceType) {
      case DeviceType.router:
        return Icons.router;
      case DeviceType.phone:
        return Icons.phone_android;
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.unknown:
      default:
        return Icons.devices;
    }
  }

  /// Get color based on device type
  Color _getDeviceColor() {
    switch (device.deviceType) {
      case DeviceType.router:
        return Colors.blue;
      case DeviceType.phone:
        return Colors.green;
      case DeviceType.computer:
        return Colors.orange;
      case DeviceType.unknown:
      default:
        return Colors.grey;
    }
  }
}