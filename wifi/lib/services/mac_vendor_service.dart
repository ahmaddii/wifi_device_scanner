import 'package:http/http.dart' as http;
import 'dart:convert';

/// Enhanced MAC vendor lookup service with online API fallback
/// Supports popular brands: Infinix, Realme, Redmi, OPPO, vivo, etc.
class EnhancedMacVendorService {
  // Cache to avoid repeated API calls
  static final Map<String, String> _cache = {};

  // Enhanced local database with popular phone brands
  static final Map<String, String> _localDatabase = {
    // Infinix (Transsion Holdings) - Very popular in Pakistan
    '00606E': 'Infinix', '04D3B0': 'Infinix', '08EDB9': 'Infinix',
    '1C3BF3': 'Infinix', '2047ED': 'Infinix', '244B03': 'Infinix',
    '34415D': 'Infinix', '3CCD5D': 'Infinix', '5CC307': 'Infinix',
    '68EBAE': 'Infinix', '7C1C4E': 'Infinix', 'A0F459': 'Infinix',
    'D46E5C': 'Infinix', 'E884A5': 'Infinix', 'F8C39E': 'Infinix',

    // Realme (BBK Electronics) - Very popular
    '009EC8': 'Realme', '044FAA': 'Realme', '1C994C': 'Realme',
    '346BD3': 'Realme', '3CF808': 'Realme', '4491DB': 'Realme',
    '58C5CB': 'Realme', '683E34': 'Realme', '706655': 'Realme',
    '886B0F': 'Realme', '94E96A': 'Realme', 'A036BC': 'Realme',
    'C09F05': 'Realme', 'D067E5': 'Realme', 'F0038C': 'Realme',

    // Xiaomi / Redmi - Extremely popular
    '04CF8C': 'Xiaomi', '085B0E': 'Xiaomi', '286C07': 'Xiaomi',
    '34CE00': 'Xiaomi', '44032C': 'Xiaomi', '508F4C': 'Xiaomi',
    '640980': 'Xiaomi', '64B473': 'Xiaomi', '68DFDD': 'Xiaomi',
    '6C5697': 'Xiaomi', '7811DC': 'Xiaomi', '7C1C68': 'Xiaomi',
    '8CBEBE': 'Xiaomi', '98FAE3': 'Xiaomi', 'A086C6': 'Xiaomi',
    'C40BCB': 'Xiaomi', 'D06FAA': 'Xiaomi', 'F8A45F': 'Xiaomi',

    // OPPO (BBK Electronics)
    '08863B': 'OPPO', '14D424': 'OPPO', '1CB72C': 'OPPO',
    '28C63F': 'OPPO', '445EF3': 'OPPO', '54FA3E': 'OPPO',
    '6CB7F4': 'OPPO', '74DFBF': 'OPPO', '886B0F': 'OPPO',
    '983571': 'OPPO', 'AC3743': 'OPPO', 'B8D7AF': 'OPPO',
    'D067E5': 'OPPO', 'E45D75': 'OPPO', 'F8461C': 'OPPO',

    // vivo (BBK Electronics)
    '10BF48': 'vivo', '203DB2': 'vivo', '30B4B8': 'vivo',
    '503275': 'vivo', '603D26': 'vivo', '80797B': 'vivo',
    '90B0ED': 'vivo', 'B0A7B9': 'vivo', 'C85A9F': 'vivo',
    'D4970B': 'vivo', 'E0191D': 'vivo', 'F0728C': 'vivo',

    // OnePlus
    'AC3743': 'OnePlus', 'D0C637': 'OnePlus', 'E470B8': 'OnePlus',

    // Samsung
    '0012FB': 'Samsung', '0015B9': 'Samsung', '00166B': 'Samsung',
    '0017C9': 'Samsung', '0018AF': 'Samsung', '001C43': 'Samsung',
    '3423BA': 'Samsung', '380A94': 'Samsung', '400E85': 'Samsung',
    '503237': 'Samsung', '50B7C3': 'Samsung', '88329B': 'Samsung',
    'A00BBA': 'Samsung', 'C819F7': 'Samsung', 'D0176A': 'Samsung',
    'E8508B': 'Samsung', 'EC1D8B': 'Samsung',

    // Apple
    '000393': 'Apple', '000A95': 'Apple', '000D93': 'Apple',
    '0017F2': 'Apple', '001B63': 'Apple', '001CB3': 'Apple',
    '28CFE9': 'Apple', '3C0754': 'Apple', '50EAD6': 'Apple',
    '685B35': 'Apple', '8C8590': 'Apple', 'A4D18C': 'Apple',
    'B8E856': 'Apple', 'D0E140': 'Apple', 'F0B479': 'Apple',

    // Huawei
    '001882': 'Huawei', '001E10': 'Huawei', '0819A6': 'Huawei',
    '5001BB': 'Huawei', '582AF7': 'Huawei', '6CE873': 'Huawei',
    '84A8E4': 'Huawei', 'ACE215': 'Huawei', 'D07AB5': 'Huawei',

    // Tecno (Transsion)
    '04D3B0': 'Tecno', 'D46E5C': 'Tecno',

    // Motorola
    '001A1B': 'Motorola', '24DA9B': 'Motorola', '30074D': 'Motorola',
    '5C0E8B': 'Motorola', 'CCC734': 'Motorola',

    // Routers
    '002719': 'TP-Link', '14CF92': 'TP-Link', '50C7BF': 'TP-Link',
    '00055D': 'D-Link', '001195': 'D-Link',
    '00095B': 'Netgear', '00146C': 'Netgear',
    '00112F': 'Asus', '001D60': 'Asus',
  };

  /// Main method: Get vendor from MAC address
  /// Uses local DB first, then fallback to online API
  static Future<String?> getVendor(String? macAddress) async {
    if (macAddress == null || macAddress.isEmpty) {
      print('⚠️ MAC address is null or empty');
      return null;
    }

    // Normalize MAC first
    final normalized = _normalizeMac(macAddress);
    if (normalized == null) {
      print('⚠️ Invalid MAC address format: $macAddress');
      return null;
    }

    print(
      '🔍 Looking up vendor for MAC: $macAddress (normalized: $normalized)',
    );

    // Check cache first
    if (_cache.containsKey(normalized)) {
      print('✅ Found in cache: ${_cache[normalized]}');
      return _cache[normalized];
    }

    // Try local database
    final localVendor = _getVendorFromLocal(normalized);
    if (localVendor != null) {
      print('✅ Found in local DB: $localVendor');
      _cache[normalized] = localVendor;
      return localVendor;
    }

    // Fallback to online API
    print('🌐 Trying online API...');
    final onlineVendor = await _getVendorFromAPI(macAddress);
    if (onlineVendor != null) {
      print('✅ Found via API: $onlineVendor');
      _cache[normalized] = onlineVendor;
      return onlineVendor;
    }

    print('❌ Vendor not found for: $macAddress');
    return null;
  }

  /// Normalize MAC address to consistent format (remove separators, uppercase)
  static String? _normalizeMac(String macAddress) {
    try {
      String normalized = macAddress
          .toUpperCase()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceAll('.', '')
          .replaceAll(' ', '');

      if (normalized.length < 6) return null;
      return normalized;
    } catch (e) {
      return null;
    }
  }

  /// Get vendor from local database
  static String? _getVendorFromLocal(String normalizedMac) {
    try {
      if (normalizedMac.length < 6) return null;

      // Extract OUI (first 6 characters)
      String oui = normalizedMac.substring(0, 6);

      // Try direct lookup (without colons)
      if (_localDatabase.containsKey(oui)) {
        return _localDatabase[oui];
      }

      // Also try with colons format for backward compatibility
      String formattedOui =
          '${oui.substring(0, 2)}:${oui.substring(2, 4)}:${oui.substring(4, 6)}';

      return _localDatabase[formattedOui];
    } catch (e) {
      print('Error in local lookup: $e');
      return null;
    }
  }

  /// Get vendor from online API (macvendors.com - free, no API key)
  static Future<String?> _getVendorFromAPI(String macAddress) async {
    try {
      final url =
          'https://api.macvendors.com/${Uri.encodeComponent(macAddress)}';
      print('API URL: $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));

      print('API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        String vendor = response.body.trim();
        print('API returned: $vendor');

        // Clean up vendor name
        if (vendor.contains(',')) {
          vendor = vendor.split(',').first.trim();
        }

        return vendor.isNotEmpty ? vendor : null;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('MAC API lookup failed: $e');
    }
    return null;
  }

  /// Check if vendor is a router manufacturer
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
      'Tenda',
      'Mercusys',
    ];

    return routerVendors.any(
      (rv) => vendor.toLowerCase().contains(rv.toLowerCase()),
    );
  }

  /// Clear cache (useful for testing)
  static void clearCache() {
    _cache.clear();
    print('🗑️ Cache cleared');
  }
}
