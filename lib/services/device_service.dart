import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DeviceService {
  static String? _deviceId;
  static const String _deviceIdKey = 'device_id';

  /// Get the unique device identifier
  /// This will be the same for the same device across app sessions
  static Future<String> getDeviceId() async {
    if (_deviceId != null) {
      return _deviceId!;
    }

    // Try to get stored device ID first
    final prefs = await SharedPreferences.getInstance();
    final storedDeviceId = prefs.getString(_deviceIdKey);
    
    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      _deviceId = storedDeviceId;
      return _deviceId!;
    }

    // Generate new device ID
    _deviceId = await _generateDeviceId();
    
    // Store it for future use
    await prefs.setString(_deviceIdKey, _deviceId!);
    
    return _deviceId!;
  }

  /// Generate a unique device identifier
  static Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        // android.id is available; combine with model for stability
        final idPart = (android.id ?? 'unknown');
        final modelPart = (android.model ?? 'device');
        final brandPart = (android.brand ?? 'brand');
        return 'android_${idPart}_${modelPart}_$brandPart';
      }
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        final vendor = ios.identifierForVendor ?? 'unknown';
        final model = ios.model ?? 'device';
        final name = ios.name ?? 'name';
        return 'ios_${vendor}_${model}_$name';
      }
      // For non-mobile platforms used during development (web/desktop),
      // avoid using unsupported getters; return a generated fallback.
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Clear stored device ID (for testing or reset purposes)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    _deviceId = null;
  }

  /// Get device info for debugging
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final info = DeviceInfoPlugin();
    final deviceId = await getDeviceId();
    try {
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return {
          'deviceId': deviceId,
          'platform': 'Android',
          'model': a.model,
          'brand': a.brand,
          'version': a.version.release,
        };
      }
      if (Platform.isIOS) {
        final i = await info.iosInfo;
        return {
          'deviceId': deviceId,
          'platform': 'iOS',
          'model': i.model,
          'name': i.name,
          'version': i.systemVersion,
        };
      }
      return {
        'deviceId': deviceId,
        'platform': 'Unknown',
      };
    } catch (e) {
      return {
        'deviceId': deviceId,
        'platform': 'Unknown',
        'error': e.toString(),
      };
    }
  }
}
