import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Enhanced MAC vendor lookup service with expanded database
class EnhancedMacVendorService {
  static final Map<String, String> _cache = {};

  // MASSIVELY EXPANDED local database
  static final Map<String, String> _localDatabase = {
    // Infinix (Transsion Holdings)
    '00606E': 'Infinix', '04D3B0': 'Infinix', '08EDB9': 'Infinix',
    '1C3BF3': 'Infinix', '2047ED': 'Infinix', '244B03': 'Infinix',
    '34415D': 'Infinix', '3CCD5D': 'Infinix', '5CC307': 'Infinix',
    '68EBAE': 'Infinix', '7C1C4E': 'Infinix', 'A0F459': 'Infinix',
    'D46E5C': 'Infinix', 'E884A5': 'Infinix', 'F8C39E': 'Infinix',
    '9C35EB': 'Infinix', 'F0D7AA': 'Infinix', '2C1F23': 'Infinix',

    // Realme (BBK Electronics) - EXPANDED
    '009EC8': 'Realme', '044FAA': 'Realme', '1C994C': 'Realme',
    '346BD3': 'Realme', '3CF808': 'Realme', '4491DB': 'Realme',
    '58C5CB': 'Realme', '683E34': 'Realme', '706655': 'Realme',
    '886B0F': 'Realme', '94E96A': 'Realme', 'A036BC': 'Realme',
    'C09F05': 'Realme', 'D067E5': 'Realme', 'F0038C': 'Realme',
    '18D2C8': 'Realme', '2078B0': 'Realme', '24F677': 'Realme',
    '28B2BD': 'Realme', '4C79BA': 'Realme', '5CF7E6': 'Realme',
    '6462E2': 'Realme', '7073CB': 'Realme', '7CB05C': 'Realme',
    '8438DA': 'Realme', '8C1F64': 'Realme', 'A4711F': 'Realme',
    'B4A5EF': 'Realme', 'C4B301': 'Realme', 'D8A9C5': 'Realme',
    'E4419C': 'Realme', 'E86F38': 'Realme', 'F81A67': 'Realme',

    // Xiaomi / Redmi - MASSIVELY EXPANDED
    '04CF8C': 'Xiaomi', '085B0E': 'Xiaomi', '286C07': 'Xiaomi',
    '34CE00': 'Xiaomi', '44032C': 'Xiaomi', '508F4C': 'Xiaomi',
    '640980': 'Xiaomi', '64B473': 'Xiaomi', '68DFDD': 'Xiaomi',
    '6C5697': 'Xiaomi', '7811DC': 'Xiaomi', '7C1C68': 'Xiaomi',
    '8CBEBE': 'Xiaomi', '98FAE3': 'Xiaomi', 'A086C6': 'Xiaomi',
    'C40BCB': 'Xiaomi', 'D06FAA': 'Xiaomi', 'F8A45F': 'Xiaomi',
    '009EC8': 'Xiaomi', '041BBA': 'Xiaomi', '0C1DAF': 'Xiaomi',
    '10234B': 'Xiaomi', '141F78': 'Xiaomi', '183762': 'Xiaomi',
    '1C3342': 'Xiaomi', '202BC1': 'Xiaomi', '244B03': 'Xiaomi',
    '28A60A': 'Xiaomi', '2CF43C': 'Xiaomi', '30DE4B': 'Xiaomi',
    '3448ED': 'Xiaomi', '38A4ED': 'Xiaomi', '3C8B18': 'Xiaomi',
    '401801': 'Xiaomi', '44D6E3': 'Xiaomi', '4846FB': 'Xiaomi',
    '4C49E3': 'Xiaomi', '5014F5': 'Xiaomi', '54A5C8': 'Xiaomi',
    '58CF79': 'Xiaomi', '5C51AC': 'Xiaomi', '604BAA': 'Xiaomi',
    '6407D2': 'Xiaomi', '680E8C': 'Xiaomi', '6C56DE': 'Xiaomi',
    '707BE0': 'Xiaomi', '742344': 'Xiaomi', '7837C6': 'Xiaomi',
    '784F43': 'Xiaomi', '7C496B': 'Xiaomi', '7C8BCA': 'Xiaomi',
    '7CE9D3': 'Xiaomi', '80E650': 'Xiaomi', '8416F9': 'Xiaomi',
    '88C396': 'Xiaomi', '8CFCAC': 'Xiaomi', '90604B': 'Xiaomi',
    '940D77': 'Xiaomi', '983DDA': 'Xiaomi', '9C28EF': 'Xiaomi',
    'A026B7': 'Xiaomi', 'A40CC3': 'Xiaomi', 'A45046': 'Xiaomi',
    'A87859': 'Xiaomi', 'AC233F': 'Xiaomi', 'AC853D': 'Xiaomi',
    'B083FE': 'Xiaomi', 'B44BD2': 'Xiaomi', 'B8AC6F': 'Xiaomi',
    'BCB36C': 'Xiaomi', 'C063F1': 'Xiaomi', 'C46AB7': 'Xiaomi',
    'C46C66': 'Xiaomi', 'C80E14': 'Xiaomi', 'CC61E5': 'Xiaomi',
    'D0C857': 'Xiaomi', 'D41C6D': 'Xiaomi', 'D4BF7F': 'Xiaomi',
    'D8F1A5': 'Xiaomi', 'DC49F4': 'Xiaomi', 'E06267': 'Xiaomi',
    'E09479': 'Xiaomi', 'E0E3B8': 'Xiaomi', 'E4C483': 'Xiaomi',
    'E894F6': 'Xiaomi', 'EC1D8B': 'Xiaomi', 'F0B429': 'Xiaomi',
    'F4062D': 'Xiaomi', 'F4F9F4': 'Xiaomi', 'F8630C': 'Xiaomi',
    'FC64BA': 'Xiaomi', 'FC8E7E': 'Xiaomi',

    // OPPO (BBK Electronics) - EXPANDED
    '08863B': 'OPPO', '14D424': 'OPPO', '1CB72C': 'OPPO',
    '28C63F': 'OPPO', '445EF3': 'OPPO', '54FA3E': 'OPPO',
    '6CB7F4': 'OPPO', '74DFBF': 'OPPO', '886B0F': 'OPPO',
    '983571': 'OPPO', 'AC3743': 'OPPO', 'B8D7AF': 'OPPO',
    'D067E5': 'OPPO', 'E45D75': 'OPPO', 'F8461C': 'OPPO',
    '0C84DC': 'OPPO', '10682F': 'OPPO', '184F32': 'OPPO',
    '3C7374': 'OPPO', '549D71': 'OPPO', '784476': 'OPPO',
    '94E979': 'OPPO', 'C03FD5': 'OPPO', 'DC028E': 'OPPO',

    // vivo (BBK Electronics) - EXPANDED
    '10BF48': 'vivo', '203DB2': 'vivo', '30B4B8': 'vivo',
    '503275': 'vivo', '603D26': 'vivo', '80797B': 'vivo',
    '90B0ED': 'vivo', 'B0A7B9': 'vivo', 'C85A9F': 'vivo',
    'D4970B': 'vivo', 'E0191D': 'vivo', 'F0728C': 'vivo',
    '08669C': 'vivo', '145B89': 'vivo', '2043D8': 'vivo',
    '3C2886': 'vivo', '48E1E9': 'vivo', '540635': 'vivo',
    '682711': 'vivo', '7CE4AA': 'vivo', '881FAC': 'vivo',
    '98F0AB': 'vivo', 'AC561F': 'vivo', 'B8BC5B': 'vivo',

    // OnePlus - EXPANDED
    'AC3743': 'OnePlus', 'D0C637': 'OnePlus', 'E470B8': 'OnePlus',
    '24F094': 'OnePlus', '38C986': 'OnePlus', '70E72C': 'OnePlus',
    '885395': 'OnePlus', 'B4D5BD': 'OnePlus', 'F4525D': 'OnePlus',

    // Samsung - EXPANDED
    '0012FB': 'Samsung', '0015B9': 'Samsung', '00166B': 'Samsung',
    '0017C9': 'Samsung', '0018AF': 'Samsung', '001C43': 'Samsung',
    '3423BA': 'Samsung', '380A94': 'Samsung', '400E85': 'Samsung',
    '503237': 'Samsung', '50B7C3': 'Samsung', '88329B': 'Samsung',
    'A00BBA': 'Samsung', 'C819F7': 'Samsung', 'D0176A': 'Samsung',
    'E8508B': 'Samsung', 'EC1D8B': 'Samsung', '001377': 'Samsung',
    '0016DB': 'Samsung', '001D25': 'Samsung', '002597': 'Samsung',
    '0026C6': 'Samsung', '002686': 'Samsung', '0C7527': 'Samsung',
    '10BF48': 'Samsung', '14910F': 'Samsung', '1C5A3E': 'Samsung',
    '2C598A': 'Samsung', '30D6C9': 'Samsung', '44F459': 'Samsung',
    '542696': 'Samsung', '609217': 'Samsung', '68A86D': 'Samsung',
    '7C6193': 'Samsung', '843838': 'Samsung', '8851FB': 'Samsung',
    '940026': 'Samsung', 'A0821F': 'Samsung', 'A468BC': 'Samsung',
    'B47C9C': 'Samsung', 'C4731E': 'Samsung', 'D4E8B2': 'Samsung',
    'E4121D': 'Samsung', 'E8E5D6': 'Samsung', 'F04F7C': 'Samsung',

    // Apple - EXPANDED
    '000393': 'Apple', '000A95': 'Apple', '000D93': 'Apple',
    '0017F2': 'Apple', '001B63': 'Apple', '001CB3': 'Apple',
    '28CFE9': 'Apple', '3C0754': 'Apple', '50EAD6': 'Apple',
    '685B35': 'Apple', '8C8590': 'Apple', 'A4D18C': 'Apple',
    'B8E856': 'Apple', 'D0E140': 'Apple', 'F0B479': 'Apple',
    '000502': 'Apple', '000A27': 'Apple', '001124': 'Apple',
    '001451': 'Apple', '001F5B': 'Apple', '0021E9': 'Apple',
    '002332': 'Apple', '002436': 'Apple', '002500': 'Apple',
    '00264A': 'Apple', '003065': 'Apple', '003EE1': 'Apple',
    '0050E4': 'Apple', '001EC2': 'Apple', '0056CD': 'Apple',

    // Huawei - EXPANDED
    '001882': 'Huawei', '001E10': 'Huawei', '0819A6': 'Huawei',
    '5001BB': 'Huawei', '582AF7': 'Huawei', '6CE873': 'Huawei',
    '84A8E4': 'Huawei', 'ACE215': 'Huawei', 'D07AB5': 'Huawei',
    '000FE2': 'Huawei', '0018E7': 'Huawei', '001EC2': 'Huawei',
    '0C45BA': 'Huawei', '1095E9': 'Huawei', '2C3033': 'Huawei',
    '3862BB': 'Huawei', '3CB87A': 'Huawei', '404E36': 'Huawei',
    '504A6E': 'Huawei', '5C939E': 'Huawei', '6C4A85': 'Huawei',
    '7CE4AA': 'Huawei', '84B543': 'Huawei', '94E9F6': 'Huawei',
    '9C37F4': 'Huawei', 'A4DCB3': 'Huawei', 'AC853D': 'Huawei',
    'B05BE3': 'Huawei', 'BCF685': 'Huawei', 'C06394': 'Huawei',

    // Tecno (Transsion)
    '04D3B0': 'Tecno', 'D46E5C': 'Tecno', '68EBAE': 'Tecno',

    // Motorola - EXPANDED
    '001A1B': 'Motorola', '24DA9B': 'Motorola', '30074D': 'Motorola',
    '5C0E8B': 'Motorola', 'CCC734': 'Motorola', '000CE6': 'Motorola',
    '001423': 'Motorola', '002378': 'Motorola', '1C667F': 'Motorola',
    '3C753C': 'Motorola', '484520': 'Motorola', '8C3AE3': 'Motorola',

    // Routers
    '002719': 'TP-Link', '14CF92': 'TP-Link', '50C7BF': 'TP-Link',
    '00055D': 'D-Link', '001195': 'D-Link', '0015E9': 'D-Link',
    '00095B': 'Netgear', '00146C': 'Netgear', '002275': 'Netgear',
    '00112F': 'Asus', '001D60': 'Asus', '1062EB': 'Asus',
  };

  static Future<String?> getVendor(String? macAddress) async {
    if (macAddress == null || macAddress.isEmpty) {
      debugPrint('⚠️ MAC address is null or empty');
      return null;
    }

    final normalized = _normalizeMac(macAddress);
    if (normalized == null) {
      debugPrint('⚠️ Invalid MAC address format: $macAddress');
      return null;
    }

    debugPrint(
      '🔍 Looking up vendor for MAC: $macAddress (normalized: $normalized)',
    );

    // Check cache
    if (_cache.containsKey(normalized)) {
      debugPrint('✅ Found in cache: ${_cache[normalized]}');
      return _cache[normalized];
    }

    // Try local database
    final localVendor = _getVendorFromLocal(normalized);
    if (localVendor != null) {
      debugPrint('✅ Found in local DB: $localVendor');
      _cache[normalized] = localVendor;
      return localVendor;
    }

    // Fallback to online API
    debugPrint('🌐 Trying online API...');
    final onlineVendor = await _getVendorFromAPI(macAddress);
    if (onlineVendor != null) {
      debugPrint('✅ Found via API: $onlineVendor');
      _cache[normalized] = onlineVendor;
      return onlineVendor;
    }

    debugPrint('❌ Vendor not found for: $macAddress');
    return null;
  }

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

  static String? _getVendorFromLocal(String normalizedMac) {
    try {
      if (normalizedMac.length < 6) return null;

      String oui = normalizedMac.substring(0, 6);

      if (_localDatabase.containsKey(oui)) {
        return _localDatabase[oui];
      }

      return null;
    } catch (e) {
      debugPrint('Error in local lookup: $e');
      return null;
    }
  }

  static Future<String?> _getVendorFromAPI(String macAddress) async {
    try {
      final url =
          'https://api.macvendors.com/${Uri.encodeComponent(macAddress)}';
      debugPrint('API URL: $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));

      debugPrint('API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        String vendor = response.body.trim();
        debugPrint('API returned: $vendor');

        if (vendor.contains(',')) {
          vendor = vendor.split(',').first.trim();
        }

        return vendor.isNotEmpty ? vendor : null;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('MAC API lookup failed: $e');
    }
    return null;
  }

  static void clearCache() {
    _cache.clear();
    debugPrint('🗑️ Cache cleared');
  }
}
