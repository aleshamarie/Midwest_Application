import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Primary IP addresses to try (in order of preference)
  static const List<String> _ipAddresses = [
    '192.168.1.17',  // Your current IP
    '172.20.10.5',   // Previous IP
    'localhost',      // Fallback for web/desktop
  ];

  static String get baseHost {
    if (kIsWeb) return 'http://localhost:4000';
    
    // For mobile devices, use the first IP address
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://${_ipAddresses[0]}:4000';
    }
    
    // For desktop platforms, use localhost
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:4000';
    }
    
    // Fallback
    return 'http://${_ipAddresses[0]}:4000';
  }

  static String get baseUrl => '$baseHost/api';
  
  // Method to get all possible URLs for testing
  static List<String> getAllPossibleUrls() {
    return _ipAddresses.map((ip) => 'http://$ip:4000/api').toList();
  }
}
