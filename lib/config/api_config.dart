import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Midwest server URL (primary)
  static const String _midwestServerUrl = 'https://midwest-server.onrender.com';

  static String get baseHost {
    // Use Midwest server for all platforms
    return _midwestServerUrl;
  }

  static String get baseUrl => '$baseHost/api';
  
  // Method to get all possible URLs for testing
  static List<String> getAllPossibleUrls() {
    return [_midwestServerUrl + '/api'];
  }
}
