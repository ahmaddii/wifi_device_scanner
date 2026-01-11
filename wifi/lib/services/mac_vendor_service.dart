/// Service to identify device vendors from MAC addresses
/// Uses MAC OUI (Organizationally Unique Identifier) prefix lookup
class MacVendorService {
  // Common MAC address prefixes (first 6 characters) mapped to vendors
  // This is a subset - production apps use comprehensive databases
  static final Map<String, String> _macVendorDatabase = {
    // Apple
    '00:03:93': 'Apple',
    '00:0A:95': 'Apple',
    '00:0D:93': 'Apple',
    '00:17:F2': 'Apple',
    '00:1B:63': 'Apple',
    '00:1C:B3': 'Apple',
    '00:1D:4F': 'Apple',
    '00:1E:52': 'Apple',
    '00:1F:5B': 'Apple',
    '00:1F:F3': 'Apple',
    '00:21:E9': 'Apple',
    '00:22:41': 'Apple',
    '00:23:12': 'Apple',
    '00:23:32': 'Apple',
    '00:23:6C': 'Apple',
    '00:23:DF': 'Apple',
    '00:24:36': 'Apple',
    '00:25:00': 'Apple',
    '00:25:4B': 'Apple',
    '00:25:BC': 'Apple',
    '00:26:08': 'Apple',
    '00:26:4A': 'Apple',
    '00:26:B0': 'Apple',
    '00:26:BB': 'Apple',
    '28:CF:E9': 'Apple',
    '34:36:3B': 'Apple',
    '3C:07:54': 'Apple',
    '40:A6:D9': 'Apple',
    '50:EA:D6': 'Apple',
    '64:B0:A6': 'Apple',
    '68:5B:35': 'Apple',
    '7C:C3:A1': 'Apple',
    '8C:85:90': 'Apple',
    '90:84:0D': 'Apple',
    'A4:D1:8C': 'Apple',
    'AC:BC:32': 'Apple',
    'B8:E8:56': 'Apple',
    'C8:2A:14': 'Apple',
    'D0:E1:40': 'Apple',
    'E0:C9:7A': 'Apple',
    'F0:B4:79': 'Apple',
    'F8:1E:DF': 'Apple',
    
    // Samsung
    '00:12:FB': 'Samsung',
    '00:15:B9': 'Samsung',
    '00:16:6B': 'Samsung',
    '00:16:6C': 'Samsung',
    '00:17:C9': 'Samsung',
    '00:18:AF': 'Samsung',
    '00:1A:8A': 'Samsung',
    '00:1C:43': 'Samsung',
    '00:1D:25': 'Samsung',
    '00:1E:7D': 'Samsung',
    '00:21:19': 'Samsung',
    '00:23:39': 'Samsung',
    '00:23:D6': 'Samsung',
    '00:23:D7': 'Samsung',
    '00:24:54': 'Samsung',
    '00:24:90': 'Samsung',
    '00:24:91': 'Samsung',
    '00:26:37': 'Samsung',
    '00:26:5D': 'Samsung',
    '00:26:5F': 'Samsung',
    '34:23:BA': 'Samsung',
    '38:0A:94': 'Samsung',
    '40:0E:85': 'Samsung',
    '50:32:37': 'Samsung',
    '50:B7:C3': 'Samsung',
    '5C:0A:5B': 'Samsung',
    '88:32:9B': 'Samsung',
    '90:18:7C': 'Samsung',
    'A0:0B:BA': 'Samsung',
    'B0:C5:59': 'Samsung',
    'C8:19:F7': 'Samsung',
    'D0:17:6A': 'Samsung',
    'E8:50:8B': 'Samsung',
    'EC:1D:8B': 'Samsung',
    
    // Huawei
    '00:18:82': 'Huawei',
    '00:1E:10': 'Huawei',
    '00:25:9E': 'Huawei',
    '00:46:4B': 'Huawei',
    '00:66:4B': 'Huawei',
    '00:E0:FC': 'Huawei',
    '08:19:A6': 'Huawei',
    '18:4F:32': 'Huawei',
    '28:6E:D4': 'Huawei',
    '50:01:BB': 'Huawei',
    '58:2A:F7': 'Huawei',
    '6C:E8:73': 'Huawei',
    '78:D7:52': 'Huawei',
    '84:A8:E4': 'Huawei',
    '98:52:B1': 'Huawei',
    'AC:E2:15': 'Huawei',
    'C8:14:79': 'Huawei',
    'D0:7A:B5': 'Huawei',
    'E4:D3:32': 'Huawei',
    
    // Xiaomi
    '04:CF:8C': 'Xiaomi',
    '28:6C:07': 'Xiaomi',
    '34:CE:00': 'Xiaomi',
    '50:8F:4C': 'Xiaomi',
    '64:09:80': 'Xiaomi',
    '64:B4:73': 'Xiaomi',
    '68:DF:DD': 'Xiaomi',
    '6C:56:97': 'Xiaomi',
    '78:11:DC': 'Xiaomi',
    '7C:1C:68': 'Xiaomi',
    '8C:BE:BE': 'Xiaomi',
    '98:FA:E3': 'Xiaomi',
    'A0:86:C6': 'Xiaomi',
    'C4:0B:CB': 'Xiaomi',
    'F8:A4:5F': 'Xiaomi',
    
    // TP-Link (Routers)
    '00:27:19': 'TP-Link',
    '14:CF:92': 'TP-Link',
    '18:D6:C7': 'TP-Link',
    '50:C7:BF': 'TP-Link',
    '54:A5:1B': 'TP-Link',
    '64:66:B3': 'TP-Link',
    '74:DA:38': 'TP-Link',
    '98:DE:D0': 'TP-Link',
    'A0:F3:C1': 'TP-Link',
    'B0:95:75': 'TP-Link',
    'C0:06:C3': 'TP-Link',
    'D8:07:B6': 'TP-Link',
    'E8:48:B8': 'TP-Link',
    'F4:F2:6D': 'TP-Link',
    
    // D-Link (Routers)
    '00:05:5D': 'D-Link',
    '00:0D:88': 'D-Link',
    '00:11:95': 'D-Link',
    '00:13:46': 'D-Link',
    '00:15:E9': 'D-Link',
    '00:17:9A': 'D-Link',
    '00:19:5B': 'D-Link',
    '00:1B:11': 'D-Link',
    '00:1C:F0': 'D-Link',
    '00:1E:58': 'D-Link',
    
    // Netgear (Routers)
    '00:09:5B': 'Netgear',
    '00:0F:B5': 'Netgear',
    '00:14:6C': 'Netgear',
    '00:18:4D': 'Netgear',
    '00:1B:2F': 'Netgear',
    '00:1E:2A': 'Netgear',
    '00:24:B2': 'Netgear',
    '00:26:F2': 'Netgear',
    
    // Asus (Routers/Laptops)
    '00:11:2F': 'Asus',
    '00:15:F2': 'Asus',
    '00:17:31': 'Asus',
    '00:1A:92': 'Asus',
    '00:1D:60': 'Asus',
    '00:22:15': 'Asus',
    '00:23:54': 'Asus',
    '00:24:8C': 'Asus',
    '00:26:18': 'Asus',
    
    // Cisco
    '00:01:42': 'Cisco',
    '00:01:43': 'Cisco',
    '00:01:63': 'Cisco',
    '00:01:64': 'Cisco',
    '00:01:96': 'Cisco',
    '00:01:97': 'Cisco',
    
    // HP
    '00:01:E6': 'HP',
    '00:08:83': 'HP',
    '00:0E:7F': 'HP',
    '00:10:E3': 'HP',
    '00:11:0A': 'HP',
    '00:12:79': 'HP',
    
    // Dell
    '00:06:5B': 'Dell',
    '00:08:74': 'Dell',
    '00:0B:DB': 'Dell',
    '00:0D:56': 'Dell',
    '00:11:43': 'Dell',
    '00:12:3F': 'Dell',
    '00:13:72': 'Dell',
    '00:14:22': 'Dell',
    
    // Lenovo
    '00:1C:25': 'Lenovo',
    '00:21:97': 'Lenovo',
    '00:23:8B': 'Lenovo',
    '00:26:6C': 'Lenovo',
    '50:65:F3': 'Lenovo',
    '68:F7:28': 'Lenovo',
  };

  /// Get vendor name from MAC address
  /// Returns null if vendor cannot be determined
  static String? getVendor(String? macAddress) {
    if (macAddress == null || macAddress.isEmpty) {
      return null;
    }

    // Normalize MAC address to uppercase and remove separators
    String normalizedMac = macAddress
        .toUpperCase()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '');

    // MAC address should be 12 characters (6 bytes)
    if (normalizedMac.length < 6) {
      return null;
    }

    // Extract OUI (first 6 characters / 3 bytes)
    String oui = normalizedMac.substring(0, 6);
    
    // Format as XX:XX:XX for lookup
    String formattedOui = '${oui.substring(0, 2)}:${oui.substring(2, 4)}:${oui.substring(4, 6)}';

    // Lookup in database
    return _macVendorDatabase[formattedOui];
  }

  /// Check if MAC address belongs to a known router manufacturer
  static bool isLikelyRouter(String? vendor) {
    if (vendor == null) return false;
    
    final routerVendors = [
      'TP-Link',
      'D-Link',
      'Netgear',
      'Cisco',
      'Linksys',
      'Asus',
      'Belkin',
      'Buffalo',
    ];

    return routerVendors.any((rv) => vendor.toLowerCase().contains(rv.toLowerCase()));
  }
}