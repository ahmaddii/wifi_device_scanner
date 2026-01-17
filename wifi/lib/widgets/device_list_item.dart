import 'package:flutter/material.dart';
import '../models/device_model.dart';

/// Device list item matching the screenshot design
class DeviceListItem extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onTap;

  const DeviceListItem({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Device Icon (left side)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Icon(
                    _getDeviceIcon(),
                    size: 32,
                    color: const Color(
                      0xFF1E3A5F,
                    ), // Dark blue matching screenshot
                  ),
                ),

                const SizedBox(width: 16),

                // Device Info (middle - expanded)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device Name
                      Text(
                        device.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Label (My Device / Router / Unknow)
                      Text(
                        device.displayLabel,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 4),

                      // IP Address
                      Text(
                        'IP Address: ${device.ipAddress}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon (right side)
                Icon(Icons.arrow_forward, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
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
        return Icons.phone_android; // Default to phone icon
    }
  }
}
